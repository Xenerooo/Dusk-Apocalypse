# ChunkManagerMP.gd
extends Node2D
class_name ChunkManagerMP

var running := false

@export var chunk_scene: PackedScene
@export var tile_size: int = 32:
	set(value): tile_size = value; _update_chunk_pixel_size()
@export var chunk_tile_size: int = 40:
	set(value): chunk_tile_size = value; _update_chunk_pixel_size()

@export var TILES_PER_FRAME := 256
@export var load_radius: int = 2
@export var unload_radius: int = 3
@export var pool_initial_size := 20
@export var CHUNKS_PER_PLAYER_PER_FRAME := 2


var _player_index := 0
@export var players_per_frame := 1

@export var label_chunk: Label
@export_node_path("Node2D") var player_path
@export_node_path("TerrainLogic") var terrain_logic_path
@export_node_path("TileGenerator") var tile_generator_path
@export var prefab_folder_path := "res://resources/structures/"

var chunk_pixel_size: int
var chunk_pool: Array[Node] = []
var player_ref: Node2D
var terrain_logic_ref: TerrainLogic
var tile_generator_ref: TileGenerator

var current_chunk := Vector2i(-999, -999)
var loaded_chunks: Dictionary = {}
var chunk_load_queue: Array[Vector2i] = []
var chunk_last_keep_time: Dictionary = {}
var pending_requests := {}  

const CHUNKS_PER_FRAME := 1
const UNLOAD_COOLDOWN := 1.0
var time_elapsed := 0.0


var is_host := false
var world_save := {}
var prefab_cache: Dictionary = {}

class ChunkSliceTask:
	var chunk_pos: Vector2i
	var prefab: MapStructureResource
	var terrain_logic: TerrainLogic
	var tile_generator: TileGenerator
	var result: Dictionary = {}
	var is_done := false
	var is_network:= false
	var rpc_target:= 0

class ChunkBuildTask:
	var chunk_node: Node
	var chunk_pos: Vector2i
	var chunk_data: Dictionary = {}
	var current_layer_index: int = 0
	var tiles_done: int = 0

var slice_queue: Array[ChunkSliceTask] = []
var active_task: ChunkSliceTask = null
var slice_thread := Thread.new()

var generation_queue: Array[ChunkBuildTask] = []
var received_chunks: Dictionary = {}

func set_seed(_seed:int):
	terrain_logic_ref = get_node(terrain_logic_path)
	tile_generator_ref = get_node(tile_generator_path)
	
	terrain_logic_ref.biome_noise.seed = _seed
	tile_generator_ref.ground_variation.seed =_seed
	tile_generator_ref.vegetation_variation.seed =_seed
	tile_generator_ref.tree_variation.seed =_seed
	tile_generator_ref.noise_variation.seed =_seed

func _ready():
	_cache_all_prefabs()
	is_host = multiplayer.is_server()


	if is_host:
		terrain_logic_ref = get_node(terrain_logic_path)
		tile_generator_ref = get_node(tile_generator_path)

	for i in pool_initial_size:
		var chunk = chunk_scene.instantiate()

		chunk_pool.append(chunk)

	set_process(false)
	

func warm_up(data: Dictionary):
	world_save = data
	running = true
	set_process(true)

func _process(delta):
	if not player_ref:
		return

	time_elapsed += delta

	if is_host:
		_process_host_chunks()
	else:
		_process_client_chunks()

	if generation_queue.size() > 0:
		_generate_chunks_step()

	_update_debug_label()

func _process_host_chunks():
	var chunks_to_load :Array[Vector2i] = []
	var chunks_to_unload :Array[Vector2i] = []

	# Convert dict keys to an array once per frame
	var tokens := PlayerManager.get_all_tokens()

	if tokens.is_empty():
		return

	var players_done := 0
	while players_done < players_per_frame and not tokens.is_empty():
		# Wrap index if we exceed available players
		if _player_index >= tokens.size():
			_player_index = 0

		var token = tokens[_player_index]
		_player_index += 1
		players_done += 1

		var player_node = PlayerManager.get_player_node(token)
		if player_node == null:
			continue

		var chunk = _get_chunk_coords(player_node.global_position)
		var area = _get_chunks_in_radius(chunk, load_radius)

		# ✅ Prioritize nearest chunks
		area.sort_custom(func(a, b):
			return a.distance_to(chunk) < b.distance_to(chunk)
		)

		for pos in area:
			if not chunks_to_load.has(pos):
				chunks_to_load.append(pos)

		var unload_area = _get_chunks_in_radius(chunk, unload_radius)
		for pos in unload_area:
			if not chunks_to_unload.has(pos):
				chunks_to_unload.append(pos)

	_update_chunk_keep_times(chunks_to_load)
	_prune_load_queue(chunks_to_load)
	_queue_new_chunks(chunks_to_load)
	_unload_old_chunks(chunks_to_unload)
	_load_queued_chunks()
	_process_chunk_slicing()

func _process_client_chunks():
	var player_chunk = _get_chunk_coords(player_ref.global_position)
	current_chunk = player_chunk

	var chunks_to_request = _get_chunks_in_radius(player_chunk, load_radius)

	for chunk_pos in chunks_to_request:
		chunk_last_keep_time[chunk_pos] = time_elapsed

		var already_have = received_chunks.has(chunk_pos)
		var already_queued = chunk_load_queue.has(chunk_pos)
		var already_pending = pending_requests.has(chunk_pos)

		if not already_have and not already_queued and not already_pending:
			pending_requests[chunk_pos] = true
			#print("📡 Requesting chunk: ", chunk_pos)
			rpc_id(1, "request_chunk_data", chunk_pos)


	_unload_old_chunks(_get_chunks_in_radius(player_chunk, unload_radius))
	_load_queued_chunks()
	_process_chunk_slicing()


func _get_chunk_coords(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / chunk_pixel_size), floor(pos.y / chunk_pixel_size))

func _get_chunks_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var chunks: Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			chunks.append(Vector2i(x, y))
	return chunks

func _update_chunk_keep_times(chunks: Array[Vector2i]):
	var TILES_PER_PREFAB := 200.0 / chunk_tile_size

	for pos in chunks:
		var world_chunk_pos = Vector2i(
		floor(pos.x / TILES_PER_PREFAB),
		floor(pos.y / TILES_PER_PREFAB))
		if not world_save.chunks.has(world_chunk_pos):
			continue  # 🛑 Skip this chunk entirely
		chunk_last_keep_time[pos] = time_elapsed

func _prune_load_queue(valid: Array[Vector2i]):
	chunk_load_queue = chunk_load_queue.filter(func(p): return valid.has(p))

func _is_chunk_pending_or_loaded(pos: Vector2i) -> bool:
	if loaded_chunks.has(pos):
		return true
	for task in generation_queue:
		if task.chunk_pos == pos:
			return true
	for task in slice_queue:
		if task.chunk_pos == pos:
			return true
	if active_task and active_task.chunk_pos == pos:
		return true
	return false

func _queue_new_chunks(chunks: Array[Vector2i]):
	#print("🧩 host attempting to queue chunks. . .")
	var TILES_PER_PREFAB := 200.0 / chunk_tile_size
	for pos in chunks:
		if _is_chunk_pending_or_loaded(pos) or chunk_load_queue.has(pos):
			continue
		var world_chunk_pos = Vector2i(
			floor(pos.x / TILES_PER_PREFAB),
			floor(pos.y / TILES_PER_PREFAB)
			)
		#print("🧩 Host: checking world pos: %s" %[world_chunk_pos])
		
		if not world_save.chunks.has(world_chunk_pos):
			#print("🧩 Skipping missing chunk: %s" % [world_chunk_pos])
			continue
		#print("🧩 queueng chunk: %s" % [pos])
		chunk_load_queue.append(pos)

func _queue_new_chunks_progressive(chunks: Array[Vector2i], player_node: Node2D):
	var TILES_PER_PREFAB := 200.0 / chunk_tile_size
	var queued_this_player := 0

	# Sort chunks by distance to player
	chunks.sort_custom(func(a, b):
		var pa = (a * chunk_pixel_size).distance_squared_to(player_node.global_position)
		var pb = (b * chunk_pixel_size).distance_squared_to(player_node.global_position)
		return pa < pb
	)

	for pos in chunks:
		if queued_this_player >= CHUNKS_PER_PLAYER_PER_FRAME:
			break

		if _is_chunk_pending_or_loaded(pos) or chunk_load_queue.has(pos):
			continue

		var world_chunk_pos = Vector2i(
			floor(pos.x / TILES_PER_PREFAB),
			floor(pos.y / TILES_PER_PREFAB)
		)

		if not world_save.chunks.has(world_chunk_pos):
			continue

		chunk_load_queue.append(pos)
		queued_this_player += 1



func _unload_old_chunks(valid_chunks: Array[Vector2i]):
	var keep_map := {}
	for pos in valid_chunks:
		keep_map[pos] = true

	for pos in loaded_chunks.keys():
		if keep_map.has(pos):
			continue

		if time_elapsed - chunk_last_keep_time.get(pos, 0.0) > UNLOAD_COOLDOWN:
			var chunk = loaded_chunks[pos]
			chunk.reset()
			#chunk.hide()
			chunk_pool.append(chunk)
			chunk.get_parent().remove_child(chunk)

			loaded_chunks.erase(pos)
			chunk_last_keep_time.erase(pos)
			if not is_host:
				received_chunks.erase(pos)

func _load_queued_chunks():
	var i := 0
	
	while i < CHUNKS_PER_FRAME and chunk_load_queue.size() > 0:
		var chunk_pos = chunk_load_queue.front()

		if is_host:
			
			# ✅ HOST: we slice and generate chunk data directly
			chunk_load_queue.pop_front()
			#print("📦 [Host] Processing chunk: ", chunk_pos)
			_queue_slice_task(chunk_pos)
			i += 1

		else:
			# ✅ CLIENT: only proceed if we've received data from host
			if received_chunks.has(chunk_pos):
				chunk_load_queue.pop_front()
				_queue_client_slice_task(chunk_pos, received_chunks[chunk_pos])
				i += 1
			else:
				break
				

func _queue_client_slice_task(chunk_pos: Vector2i, chunk_data: Dictionary):
	var prefab_id = chunk_data.get("prefab_id", "")
	if prefab_id == "" or not prefab_cache.has(prefab_id):
		return

	var prefab = prefab_cache[prefab_id]

	var task := ChunkSliceTask.new()
	task.chunk_pos = chunk_pos
	task.prefab = prefab
	task.terrain_logic = terrain_logic_ref
	task.tile_generator = tile_generator_ref
	task.result = chunk_data.get("overrides", {}) # ✅ STORE THE OVERRIDES HERE
	slice_queue.append(task)


func _queue_slice_task(chunk_pos: Vector2i):
	var TILES_PER_PREFAB := 200 / chunk_tile_size
	var world_chunk_pos = chunk_pos / TILES_PER_PREFAB
	var chunk_data = world_save.chunks.get(world_chunk_pos)

	if chunk_data == null:
		return

	var prefab_id = chunk_data.get("prefab_id", "")
	var prefab = prefab_cache.get(prefab_id)
	if prefab == null:
		return

	var task = ChunkSliceTask.new()
	task.chunk_pos = chunk_pos
	task.prefab = prefab
	task.terrain_logic = terrain_logic_ref
	task.tile_generator = tile_generator_ref
	task.result = chunk_data.get("overrides", {}) # ✅ STORE THE OVERRIDES HERE
	slice_queue.append(task)
	#print("🧩 Host queueing slice task: %s" % [chunk_pos])

func _process_chunk_slicing():
	if active_task != null and active_task.is_done:
		
		slice_thread.wait_to_finish()

		if active_task.is_network:
			if is_host:
				# ✅ Host is sending prefab_id + overrides (not full prefab data)
				var overrides := active_task.result
				var prefab_id := active_task.prefab.resource_path.get_file().get_basename()

				var payload := {
					"prefab_id": prefab_id,
					"overrides": {},
				}
				var raw = var_to_bytes(payload)
				var compressed := raw.compress(2)
				var original_size := raw.size()
				rpc_id(active_task.rpc_target, "receive_chunk_data_compressed", active_task.chunk_pos, compressed, original_size)
				

			else:
				# ✅ Client finished slicing the prefab locally
				_spawn_chunk_with_data(active_task.chunk_pos, active_task.result)
				print("✅ [Client] Client finished slicing:", active_task.result)

		else:
			# ✅ Local (host or client) chunk spawn
			_spawn_chunk_with_data(active_task.chunk_pos, active_task.result)
			

		active_task = null

	# Start next task if none active
	if active_task == null and not slice_queue.is_empty():
		#print("🧵 [Client] Starting slice thread for:", slice_queue[0].chunk_pos)
		active_task = slice_queue.pop_front()
		slice_thread.start(Callable(self, "_threaded_slice_prefab").bind(active_task))


func _threaded_slice_prefab(task: ChunkSliceTask):
	var PREFAB_TILE_SIZE := 200
	var TILE_CHUNK_SIZE := chunk_tile_size
	var TILES_PER_PREFAB := PREFAB_TILE_SIZE / TILE_CHUNK_SIZE

	var chunk_pos = task.chunk_pos
	var world_chunk_pos = chunk_pos / TILES_PER_PREFAB
	var world_chunk_start_pos = world_chunk_pos * PREFAB_TILE_SIZE
	var chunk_offset = chunk_pos - world_chunk_pos * TILES_PER_PREFAB
	var tile_origin = chunk_offset * TILE_CHUNK_SIZE
	var tile_end = tile_origin + Vector2i(TILE_CHUNK_SIZE, TILE_CHUNK_SIZE)

	var result: Dictionary = {}
	var claimed_positions: Dictionary = {}
	# === Prefab Layer Extraction ===
	for layer_name in task.prefab.layers.keys():
		var layer_data: Dictionary = task.prefab.layers[layer_name]

		for key in layer_data:
			var tile_pos: Vector2i = key
			if tile_pos.x >= tile_origin.x and tile_pos.x < tile_end.x and tile_pos.y >= tile_origin.y and tile_pos.y < tile_end.y:
				var local_pos: Vector2i = tile_pos - tile_origin
				var tile_info: Dictionary = layer_data[key]

				if not result.has(layer_name):
					result[layer_name] = {}

				var local_key = local_pos
				result[layer_name][local_key] = tile_info
				claimed_positions[local_key] = true

	# === Overrides Merge ===
	if task.result is Dictionary:
		for layer_name in task.result:
			var layer_data: Dictionary = task.result[layer_name]

			for world_local_key in layer_data:
				if typeof(world_local_key) != TYPE_VECTOR2I:
					continue

				var world_local_pos: Vector2i = world_local_key

				# Only take overrides within this chunk's region
				if world_local_pos.x >= tile_origin.x and world_local_pos.x < tile_end.x \
				and world_local_pos.y >= tile_origin.y and world_local_pos.y < tile_end.y:

					var tile_info: Dictionary = layer_data[world_local_pos]
					var local_pos :Vector2i= world_local_pos - tile_origin

					if not result.has(layer_name):
						result[layer_name] = {}

					result[layer_name][local_pos] = tile_info
					claimed_positions[local_pos] = true
	
	# === Procedural Generation ===
	for x in range(tile_origin.x, tile_end.x):
		for y in range(tile_origin.y, tile_end.y):
			var world_pos = world_chunk_start_pos + Vector2i(x, y)
			var local_pos = Vector2i(x, y) - tile_origin
			var local_key = local_pos

			if claimed_positions.has(local_key):
				continue

			var lookups := task.tile_generator.generate_tiles(world_pos, task.terrain_logic)

			for lookup in lookups:
				if not lookup.has("layer") or not lookup.has("source_id") or not lookup.has("atlas_coords"):
					continue

				var layer_name: String = lookup["layer"]

				if not result.has(layer_name):
					result[layer_name] = {}

				result[layer_name][local_key] = {
					"source_id": lookup["source_id"],
					"atlas_coords": lookup["atlas_coords"],
					"alt_tile": 0
				}

	task.result = result
	task.is_done = true


func _spawn_chunk_with_data(chunk_pos: Vector2i, chunk_data: Dictionary):

	#if is_host:
		# Host behavior (already sliced)
	var chunk = chunk_pool.pop_back() if chunk_pool.size() > 0 else chunk_scene.instantiate()
	chunk.chunk_tile_size = chunk_tile_size
	chunk.tile_size = tile_size
	chunk.chunk_pos = chunk_pos
	chunk.position = chunk_pos * chunk_pixel_size
	chunk.name = str(chunk_pos)

	add_child(chunk)

	var build_task := ChunkBuildTask.new()
	build_task.chunk_node = chunk
	build_task.chunk_pos = chunk_pos
	build_task.chunk_data = chunk_data
	generation_queue.append(build_task)
	loaded_chunks[chunk_pos] = chunk
	chunk_last_keep_time[chunk_pos] = time_elapsed

	#else:
		# === Client: queue a slicing task using prefab + overrides ===

func client_slice_task(chunk_pos: Vector2i, chunk_data: Dictionary):
	var prefab_id: String = chunk_data.get("prefab_id", "")
	var overrides: Dictionary = chunk_data.get("overrides", {})
	
	var prefab: MapStructureResource = prefab_cache.get(prefab_id)
	
	if prefab == null:
		push_error("❌ Missing prefab on client: '%s'" % prefab_id)
		return
	var slice_task := ChunkSliceTask.new()
	slice_task.chunk_pos = chunk_pos
	slice_task.prefab = prefab
	slice_task.terrain_logic = terrain_logic_ref
	slice_task.tile_generator = tile_generator_ref
	slice_task.is_network = true  # Flag as network-originated
	slice_task.result = overrides  # Save for post-slice merge

	slice_queue.append(slice_task)

func _generate_chunks_step():
	var tiles_this_frame := 0
	while generation_queue.size() > 0 and tiles_this_frame < TILES_PER_FRAME:
		var task = generation_queue[0]
		if task.chunk_data.is_empty():
			generation_queue.pop_front()
			continue

		var chunk = task.chunk_node
		var layers = task.chunk_data.keys()
		if task.current_layer_index >= layers.size():
			chunk.update_notifier()
			generation_queue.pop_front()
			continue

		var layer_name = layers[task.current_layer_index]
		if task.tiles_done == 0 and chunk.pending_layers.is_empty():
			var layer_tiles = {layer_name: task.chunk_data[layer_name]}
			chunk.set_tile_data(layer_tiles)

		var tiles_to_process := TILES_PER_FRAME - tiles_this_frame
		var done :bool= chunk.process_tiles_step(tiles_to_process)
		tiles_this_frame += tiles_to_process

		if done:
			task.tiles_done = 0
			task.current_layer_index += 1

func _cache_all_prefabs():
	var dir := DirAccess.open(prefab_folder_path)
	if dir == null:
		push_error("Failed to open prefab folder: %s" % prefab_folder_path)
		return
	dir.list_dir_begin()
	var file_name := dir.get_next()

	while file_name != "":
		if file_name.begins_with("."):
			file_name = dir.get_next()
			continue

		if dir.current_is_dir():
			# Skip all folders
			file_name = dir.get_next()
			continue

		if file_name.ends_with(".res") or file_name.ends_with(".tres"):
			var file_path := prefab_folder_path.path_join(file_name)
			if ResourceLoader.exists(file_path):
				var resource := load(file_path)
				if resource is MapStructureResource:
					var id := file_name.get_basename()
					prefab_cache[id] = resource

		file_name = dir.get_next()

	dir.list_dir_end()



@rpc("any_peer", "call_local")
func request_chunk_data(chunk_pos: Vector2i):
	var TILES_PER_PREFAB := 200 / chunk_tile_size
	var world_chunk_pos = chunk_pos / TILES_PER_PREFAB

	var world_chunk = world_save.chunks.get(world_chunk_pos, null)
	if world_chunk == null:
		print("❌ No chunk exists at: ", world_chunk_pos)
		return

	var prefab_id = world_chunk.get("prefab_id", "")
	if prefab_id == "":
		print("❌ Prefab ID missing at: ", world_chunk_pos)
		return

	# Only send the prefab_id and optional overrides
	rpc_id(multiplayer.get_remote_sender_id(), "receive_chunk_data", chunk_pos, {
		"prefab_id": prefab_id,
		"overrides": world_chunk.get("overrides", {})
	})


@rpc("authority")
func receive_chunk_data(chunk_pos: Vector2i, chunk_data: Dictionary):
	var prefab_id = chunk_data.get("prefab_id", "")
	if prefab_id == "" or not prefab_cache.has(prefab_id):
		print("❌ Invalid prefab ID or not cached: ", prefab_id)
		return

	# Save the prefab_id + overrides
	received_chunks[chunk_pos] = chunk_data
	pending_requests.erase(chunk_pos)

	if not chunk_load_queue.has(chunk_pos):
		chunk_load_queue.append(chunk_pos)

@rpc("authority")
func receive_chunk_data_compressed(chunk_pos: Vector2i, compressed: PackedByteArray, original_size: int):
	var decompressed = compressed.decompress(original_size, 2)
	var chunk_data = bytes_to_var(decompressed)


	#print("📦 Received chunk. .  total: %s" % [received_chunks.size()])
	received_chunks[chunk_pos] = chunk_data

	# ✅ Mark request as complete
	pending_requests.erase(chunk_pos)
	
	if not chunk_load_queue.has(chunk_pos):
		chunk_load_queue.append(chunk_pos)

func set_tile_override(world_tile_pos: Vector2i, layer_name: String, tile_data: Dictionary) -> void:
	var PREFAB_TILE_SIZE := 200
	var TILES_PER_PREFAB := PREFAB_TILE_SIZE  # This is because world tile size is equal to prefab tile size

	var world_chunk_pos := world_tile_pos / TILES_PER_PREFAB
	var local_tile_pos := world_tile_pos - world_chunk_pos * PREFAB_TILE_SIZE
	var local_key := local_tile_pos

	var chunk_key := world_chunk_pos
	if not world_save.chunks.has(chunk_key):
		world_save.chunks[chunk_key] = {
			"prefab_id": "",  # You may need to set this depending on use case
			"overrides": {}
		}

	var chunk_data :Dictionary= world_save.chunks[chunk_key]

	# Make sure overrides exist
	if not chunk_data.has("overrides"):
		chunk_data["overrides"] = {}

	if not chunk_data["overrides"].has(layer_name):
		chunk_data["overrides"][layer_name] = {}

	# Set or replace the override
	chunk_data["overrides"][layer_name][local_key] = tile_data

	# ✅ Optional: mark the chunk as dirty for saving
	world_save.chunks[chunk_key] = chunk_data
	print("uhh")

func get_current_chunk_node(pos:Vector2) -> Chunk:
	var chunk_coord :Vector2i= _get_chunk_coords(pos)
	var chunk = get_node_or_null(str(chunk_coord))
	return chunk

func _update_chunk_pixel_size():
	chunk_pixel_size = chunk_tile_size * tile_size

func _update_debug_label():
	if label_chunk:
		label_chunk.text = "Chunks: %d\nFPS: %d\nReceived chunks: %s" % [chunk_last_keep_time.size(), Engine.get_frames_per_second(), received_chunks.size()]

func _exit_tree():
	if slice_thread.is_started() :
		slice_thread.wait_to_finish()
