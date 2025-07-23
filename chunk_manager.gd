extends Node2D

@export var chunk_scene: PackedScene
@export var tile_size: int = 32:
	set(value):
		tile_size = value
		_update_chunk_pixel_size()

@export var chunk_tile_size: int = 32:
	set(value):
		chunk_tile_size = value
		_update_chunk_pixel_size()

@export var TILES_PER_FRAME := 256
@export var load_radius: int = 2
@export var unload_radius: int = 3
@export var label_chunk: Label
@export_node_path("Node2D") var player_path
@export var save_path: String = "user://saves/"

var chunk_pool: Array[Node] = []
@export var pool_initial_size := 20

var chunk_pixel_size: int
var player_ref: Node2D
var current_chunk := Vector2i(-999, -999)
var loaded_chunks: Dictionary = {}
var chunk_load_queue: Array[Vector2i] = []
var chunk_last_keep_time: Dictionary = {}
var generation_queue: Array[ChunkBuildTask] = []

const CHUNKS_PER_FRAME := 1
const UNLOAD_COOLDOWN := 1.0
var time_elapsed := 0.0

func _ready():
	for i in range(pool_initial_size):
		var chunk = chunk_scene.instantiate()
		chunk.hide()
		chunk_pool.append(chunk)
	player_ref = get_node(player_path)
	_update_chunk_pixel_size()

func _process(delta):
	if not player_ref:
		return
	time_elapsed += delta
	_process_chunks()

func _process_chunks():
	var player_chunk = _get_chunk_coords(player_ref.global_position)
	current_chunk = player_chunk
	var chunks_to_load = _get_chunks_in_radius(player_chunk, load_radius)
	var chunks_to_unload = _get_chunks_in_radius(player_chunk, unload_radius)
	_update_chunk_keep_times(chunks_to_load)
	_prune_load_queue(chunks_to_load)
	_queue_new_chunks(chunks_to_load)
	_unload_old_chunks(chunks_to_unload)
	_load_queued_chunks()
	_generate_chunks_step()
	_update_debug_label()

func _get_chunk_coords(pos: Vector2) -> Vector2i:
	return Vector2i(
		floor(pos.x / chunk_pixel_size),
		floor(pos.y / chunk_pixel_size)
	)

func _get_chunks_in_radius(center: Vector2i, radius: int) -> Array[Vector2i]:
	var chunks :Array[Vector2i]= []
	for x in range(center.x - radius, center.x + radius + 1):
		for y in range(center.y - radius, center.y + radius + 1):
			chunks.append(Vector2i(x, y))
	return chunks

func _queue_new_chunks(chunks: Array[Vector2i]):
	for pos in chunks:
		if not loaded_chunks.has(pos) and not chunk_load_queue.has(pos):
			chunk_load_queue.append(pos)

func _prune_load_queue(valid: Array[Vector2i]):
	chunk_load_queue = chunk_load_queue.filter(func(p): return valid.has(p))

func _update_chunk_keep_times(keep_chunks: Array[Vector2i]):
	for pos in keep_chunks:
		chunk_last_keep_time[pos] = time_elapsed

func _load_queued_chunks():
	var i := 0
	while i < CHUNKS_PER_FRAME and chunk_load_queue.size() > 0:
		chunk_load_queue.sort_custom(func(a, b): return a.distance_squared_to(current_chunk) < b.distance_squared_to(current_chunk))
		var pos = chunk_load_queue.pop_front()
		_spawn_chunk(pos)
		i += 1

func _spawn_chunk(chunk_pos: Vector2i):
	var chunk: Node
	if chunk_pool.size() > 0:
		chunk = chunk_pool.pop_back()
		chunk.show()
	else:
		chunk = chunk_scene.instantiate()
		add_child(chunk)

	chunk.chunk_tile_size = chunk_tile_size
	chunk.tile_size = tile_size
	chunk.chunk_pos = chunk_pos
	chunk.position = chunk_pos * chunk_pixel_size
	add_child(chunk)

	# Load save data
	var task := ChunkBuildTask.new()
	task.chunk_node = chunk
	task.chunk_pos = chunk_pos
	task.tiles_done = 0
	task.chunk_data = _load_chunk_data(chunk_pos)
	#breakpoint
	
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
	var to_unload := []
	for pos in loaded_chunks.keys():
		if keep_map.has(pos) or building_chunks.has(pos):
			continue
		if time_elapsed - chunk_last_keep_time.get(pos, 0.0) > UNLOAD_COOLDOWN:
			to_unload.append(pos)
	for chunk_pos in to_unload:
		var chunk = loaded_chunks[chunk_pos]
		chunk.reset()
		chunk.hide()
		chunk_pool.append(chunk)
		chunk.get_parent().remove_child(chunk)
		loaded_chunks.erase(chunk_pos)
		chunk_last_keep_time.erase(chunk_pos)

func _generate_chunks_step():
	var tiles_this_frame := 0

	while generation_queue.size() > 0 and tiles_this_frame < TILES_PER_FRAME:
		var task = generation_queue[0]

		if task.chunk_data.is_empty():
			generation_queue.pop_front()
			continue

		var chunk = task.chunk_node
		var layers = task.chunk_data.keys()

		# All layers processed
		if task.current_layer_index >= layers.size():
			chunk.update_notifier()
			generation_queue.pop_front()
			continue

		var layer_name = layers[task.current_layer_index]

		# Only set tile data once for this layer
		if task.tiles_done == 0 and chunk.pending_layers.is_empty():
			var layer_tiles = { layer_name: task.chunk_data[layer_name] }
			chunk.set_tile_data(layer_tiles)

		var tiles_to_process := TILES_PER_FRAME - tiles_this_frame
		var done :bool= chunk.process_tiles_step(tiles_to_process)
		tiles_this_frame += tiles_to_process

		if done:
			task.tiles_done = 0
			task.current_layer_index += 1


func _load_chunk_data(chunk_pos: Vector2i) -> Dictionary:
	var file_path = "%schunk_%d_%d.json" % [save_path, chunk_pos.x, chunk_pos.y]
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var content = file.get_as_text()
		var p = JSON.parse_string(content)
		return p

	return {}

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
