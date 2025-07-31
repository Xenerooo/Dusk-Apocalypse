extends Node2D
class_name ChunkManager
@export var chunk_scene: PackedScene
@export var tile_size: int = 32:
	set(value):
		tile_size = value
		_update_chunk_pixel_size()

@export var chunk_tile_size: int = 40:
	set(value):
		chunk_tile_size = value
		_update_chunk_pixel_size()

@export var TILES_PER_FRAME := 256
@export var load_radius: int = 2
@export var unload_radius: int = 3
@export var label_chunk: Label
@export_node_path("Node2D") var player_path
@export_node_path("TerrainLogic") var terrain_logic_path
@export_node_path("TileGenerator") var tile_generator_path
@export var save_path: String = "res://saves/my_world_map.tres"
@export var prefab_folder_path := "res://resources/structures/"

var chunk_pool: Array[Node] = []
@export var pool_initial_size := 20

var chunk_pixel_size: int
var player_ref: Node2D
var terrain_logic_ref: TerrainLogic
var tile_generator_ref: TileGenerator
var current_chunk := Vector2i(-999, -999)
var loaded_chunks: Dictionary = {}
var chunk_load_queue: Array[Vector2i] = []
var chunk_last_keep_time: Dictionary = {}
var generation_queue: Array[ChunkBuildTask] = []

const CHUNKS_PER_FRAME := 1
const UNLOAD_COOLDOWN := 1.0
var time_elapsed := 0.0

var world_save: Resource
var prefab_cache: Dictionary = {}

class ChunkSliceTask:
	var chunk_pos: Vector2i
	var prefab: MapStructureResource
	var terrain_logic: TerrainLogic
	var tile_generator: TileGenerator
	var result: Dictionary = {}
	var is_done := false

var slice_queue: Array[ChunkSliceTask] = []
var active_task: ChunkSliceTask = null
var slice_thread := Thread.new()


func _ready():
	for i in range(pool_initial_size):
		var chunk = chunk_scene.instantiate()
		chunk.hide()
		chunk_pool.append(chunk)

	player_ref = get_node(player_path)
	terrain_logic_ref = get_node(terrain_logic_path)
	tile_generator_ref = get_node(tile_generator_path)
	_update_chunk_pixel_size()

	world_save = load(save_path)
	if world_save == null:
		push_error("❌ Could not load WorldSaveResource at %s" % save_path)
		return

	_cache_all_prefabs()


func _process(delta):
	time_elapsed += delta
	_process_chunks()
	_process_chunk_slicing()
	_generate_chunks_step()
	_update_debug_label()


func _cache_all_prefabs():
	var used_prefabs := {}
	for chunk_data in world_save.chunks.values():
		var id = chunk_data.get("prefab_id", "")
		if id != "" and not used_prefabs.has(id):
			used_prefabs[id] = true
			var path = "%s%s.res" % [prefab_folder_path, id]
			if ResourceLoader.exists(path):
				var prefab = load(path)
				if prefab:
					prefab_cache[id] = prefab
					print("✅ Cached prefab: ", id)
				else:
					print("❌ Failed to load prefab: ", id)
			else:
				print("❌ Prefab path not found: ", path)


func _process_chunks():
	if not player_ref:
		return

	var player_chunk = _get_chunk_coords(player_ref.global_position)
	current_chunk = player_chunk
	var chunks_to_load = _get_chunks_in_radius(player_chunk, load_radius)
	var chunks_to_unload = _get_chunks_in_radius(player_chunk, unload_radius)

	_update_chunk_keep_times(chunks_to_load)
	_prune_load_queue(chunks_to_load)
	_queue_new_chunks(chunks_to_load)
	_unload_old_chunks(chunks_to_unload)
	_load_queued_chunks()


func _get_chunk_coords(pos: Vector2) -> Vector2i:
	return Vector2i(floor(pos.x / chunk_pixel_size), floor(pos.y / chunk_pixel_size))

#[TEST]Just return this
func _get_chunks_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var chunks : Array[Vector2i] = []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			chunks.append(Vector2i(x, y))
	return chunks

#func _get_chunks_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	#var chunks : Array[Vector2i] = []
	#for x in range(center.x - radius, center.x + radius + 1):
		#for y in range(center.y - radius, center.y + radius + 1):
			#if x >= 0 and y >= 0:
				#chunks.append(Vector2i(x, y))
	#return chunks

func _is_chunk_pending_or_loaded(chunk_pos: Vector2i) -> bool:
	if loaded_chunks.has(chunk_pos):
		return true

	for task in generation_queue:
		if task.chunk_pos == chunk_pos:
			return true

	for task in slice_queue:
		if task.chunk_pos == chunk_pos:
			return true

	if active_task and active_task.chunk_pos == chunk_pos:
		return true

	return false


func _queue_new_chunks(chunks: Array[Vector2i]):
	var TILES_PER_PREFAB := 200.0 / chunk_tile_size  # Ensure float!

	for pos in chunks:
		# Early filter: already loaded or pending
		if _is_chunk_pending_or_loaded(pos) or chunk_load_queue.has(pos):
			continue

		# === Convert chunk_pos to save world chunk pos ===
		var world_chunk_pos = Vector2i(
			floor(pos.x / TILES_PER_PREFAB),
			floor(pos.y / TILES_PER_PREFAB)
		) #+ world_origin_chunk  # if you're using an offset

		# Skip if not present in save
		if not world_save.chunks.has(world_chunk_pos):
			continue  # 🛑 Skip this chunk entirely

		chunk_load_queue.append(pos)



func _prune_load_queue(valid: Array[Vector2i]):
	chunk_load_queue = chunk_load_queue.filter(func(p): return valid.has(p))

#[TEST]
func _update_chunk_keep_times(keep_chunks: Array[Vector2i]):
	var TILES_PER_PREFAB := 200.0 / chunk_tile_size

	for pos in keep_chunks:
		var world_chunk_pos = Vector2i(
		floor(pos.x / TILES_PER_PREFAB),
		floor(pos.y / TILES_PER_PREFAB))
		if not world_save.chunks.has(world_chunk_pos):
			continue  # 🛑 Skip this chunk entirely
		chunk_last_keep_time[pos] = time_elapsed


func _load_queued_chunks():
	var i := 0
	while i < CHUNKS_PER_FRAME and chunk_load_queue.size() > 0:
		var chunk_pos = chunk_load_queue.pop_front()
		_queue_slice_task(chunk_pos)
		i += 1


func _queue_slice_task(chunk_pos: Vector2i):
	var TILES_PER_PREFAB := 200 / chunk_tile_size
	var world_chunk_pos = chunk_pos / TILES_PER_PREFAB

	var world_chunk = world_save.chunks.get(world_chunk_pos)

	if world_chunk == null:
		return

	var prefab_id = world_chunk.get("prefab_id", "")
	var prefab: MapStructureResource = prefab_cache.get(prefab_id)
	if prefab == null:
		print("⚠️ Prefab not cached: ", prefab_id)
		return

	var task := ChunkSliceTask.new()
	task.chunk_pos = chunk_pos
	task.prefab = prefab
	task.terrain_logic = terrain_logic_ref
	task.tile_generator = tile_generator_ref
	slice_queue.append(task)


func _process_chunk_slicing():
	if active_task != null and active_task.is_done:
		slice_thread.wait_to_finish()
		_spawn_chunk_with_data(active_task.chunk_pos, active_task.result)
		active_task = null

	if active_task == null and not slice_queue.is_empty():
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

	var result := {}
	var claimed_positions := {}

	for layer_name in task.prefab.layers.keys():
		var layer_data = task.prefab.layers[layer_name]
		var positions: PackedVector2Array = layer_data["positions"]
		var source_ids: PackedInt32Array = layer_data["source_ids"]
		var alt_tiles: PackedInt32Array = layer_data["alt_tile"]
		var atlas_coords: PackedVector2Array = layer_data["atlas_coords"]

		var tiles := []

		for i in positions.size():
			var pos = Vector2i(positions[i])
			if pos.x >= tile_origin.x and pos.x < tile_end.x and pos.y >= tile_origin.y and pos.y < tile_end.y:
				var local_pos = pos - tile_origin
				claimed_positions[local_pos] = true
				tiles.append({
					"position": local_pos,
					"source_id": source_ids[i],
					"atlas_coords": Vector2i(atlas_coords[i]),
					"alt_tile": alt_tiles[i]
					
				})

		if not tiles.is_empty():
			result[layer_name] = tiles

	# === Procedural Generation ===
	for x in range(tile_origin.x, tile_end.x):
		for y in range(tile_origin.y, tile_end.y):
			var world_pos = world_chunk_start_pos + Vector2i(x, y)
			var local_pos = Vector2i(x, y) - tile_origin

			if claimed_positions.has(local_pos):
				continue

			var lookups := task.tile_generator.generate_tiles(world_pos, task.terrain_logic)

			for lookup in lookups:
				if not lookup.has("layer") or not lookup.has("source_id") or not lookup.has("atlas_coords"):
					continue

				var layer_name = lookup["layer"]
				if not result.has(layer_name):
					result[layer_name] = []

				result[layer_name].append({
					"position": local_pos,
					"source_id": lookup["source_id"],
					"atlas_coords": lookup["atlas_coords"],
					"alt_tile": 0
				})

	task.result = result
	task.is_done = true


func _spawn_chunk_with_data(chunk_pos: Vector2i, chunk_data: Dictionary):
	var chunk: Node
	if chunk_pool.size() > 0:
		chunk = chunk_pool.pop_back()
		chunk.show()
	else:
		chunk = chunk_scene.instantiate()

	chunk.chunk_tile_size = chunk_tile_size
	chunk.tile_size = tile_size
	chunk.chunk_pos = chunk_pos
	chunk.position = chunk_pos * chunk_pixel_size
	
	add_child(chunk)

	var task := ChunkBuildTask.new()
	task.chunk_node = chunk
	task.chunk_pos = chunk_pos
	task.tiles_done = 0
	task.chunk_data = chunk_data

	generation_queue.append(task)
	loaded_chunks[chunk_pos] = chunk
	chunk_last_keep_time[chunk_pos] = time_elapsed


func _unload_old_chunks(valid_chunks: Array[Vector2i]):
	var keep_map := {}
	for pos in valid_chunks:
		keep_map[pos] = true
		

	var building_chunks := {}
	for task in generation_queue:
		building_chunks[task.chunk_pos] = true

	for pos in loaded_chunks.keys():
		if keep_map.has(pos) or building_chunks.has(pos):
			continue
		if time_elapsed - chunk_last_keep_time.get(pos, 0.0) > UNLOAD_COOLDOWN:
			var chunk = loaded_chunks[pos]
			chunk.reset()
			chunk.hide()
			chunk_pool.append(chunk)
			chunk.get_parent().remove_child(chunk)
			loaded_chunks.erase(pos)
			chunk_last_keep_time.erase(pos)


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
			var layer_tiles = { layer_name: task.chunk_data[layer_name] }
			chunk.set_tile_data(layer_tiles)

		var tiles_to_process := TILES_PER_FRAME - tiles_this_frame
		var done: bool = chunk.process_tiles_step(tiles_to_process)
		tiles_this_frame += tiles_to_process

		if done:
			task.tiles_done = 0
			task.current_layer_index += 1

func _update_chunk_pixel_size():
	chunk_pixel_size = chunk_tile_size * tile_size

func _update_debug_label():
	if not label_chunk:
		return
	label_chunk.text = "Chunks: %d\nFPS: %d" % [chunk_last_keep_time.size(), Engine.get_frames_per_second()]

class ChunkBuildTask:
	var chunk_node: Node
	var chunk_pos: Vector2i
	var chunk_data: Dictionary = {}
	var current_layer_index: int = 0
	var tiles_done: int = 0

func get_tile_data()-> Dictionary:
	var mouse_pos = get_global_mouse_position()
	
	# 1. Convert to tile coordinates
	var tile_coords = Vector2i(mouse_pos / tile_size)
	
	# 2. Get ChunkManager chunk coords
	var chunk_manager_chunk = tile_coords / chunk_tile_size
	
	# 3. Convert to save world chunk
	var PREFAB_TILE_SIZE := 200  # must match your save format
	var TILES_PER_PREFAB := PREFAB_TILE_SIZE / chunk_tile_size
	var world_chunk_coords = chunk_manager_chunk / TILES_PER_PREFAB
	
	return {
		"node": get_node_or_null(str(chunk_manager_chunk)),
		"mouse_pos": mouse_pos,
		"tile_coords": tile_coords,
		"chunk_manager_chunk": chunk_manager_chunk,
		"world_chunk_coords": world_chunk_coords
	}

func get_chunk_from_pos(pos:Vector2i) -> Chunk:
	#var tile_coords = Vector2i(pos / tile_size)
	# 2. Get ChunkManager chunk coords
	var chunk_manager_chunk = pos / chunk_tile_size
	return get_node_or_null(str(chunk_manager_chunk))

	

func _exit_tree() -> void:
	slice_thread.wait_to_finish()
