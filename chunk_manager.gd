extends Node2D

# === CONFIGURABLE PARAMETERS ===
@export var seed: String = ""
@export var ground_noise: FastNoiseLite
@export var detail_noise: FastNoiseLite
@export var chunk_scene: PackedScene

@export var tile_size: int = 32:
	set(value):
		tile_size = value
		_update_chunk_pixel_size()

@export var chunk_tile_size: int = 32:
	set(value):
		chunk_tile_size = value
		_update_chunk_pixel_size()

@export var load_radius: int = 2
@export var unload_radius: int = 3
@export var label_chunk: Label
@export_node_path("Node2D") var player_path

# === INTERNAL STATE ===
var chunk_pixel_size: int
var player_ref: Node2D
var current_chunk := Vector2i(-999, -999)
var loaded_chunks: Dictionary = {}
var chunk_load_queue: Array[Vector2i] = []
var chunk_last_keep_time: Dictionary = {}
var generation_queue: Array[ChunkBuildTask] = []

# === CONSTANTS ===
const TILES_PER_FRAME := 256
const CHUNKS_PER_FRAME := 1
const UNLOAD_COOLDOWN := 1.0
enum TileLayer {
	GROUND,
	TREES,
	BUSHES
}
# === TIME TRACKING ===
var time_elapsed := 0.0

# === LIFECYCLE ===
func _ready():
	player_ref = get_node(player_path)
	_update_chunk_pixel_size()

func _process(delta):
	if not player_ref:
		return

	time_elapsed += delta
	_process_chunks()

# === CHUNK PROCESSING ===
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

func _spawn_chunk(pos: Vector2i):
	var chunk = chunk_scene.instantiate()
	chunk.chunk_tile_size = chunk_tile_size
	chunk.tile_size = tile_size
	chunk.chunk_pos = pos
	chunk.position = pos * chunk_pixel_size
	chunk.set_noise_maps({
		TileLayer.GROUND: ground_noise,
		TileLayer.TREES: detail_noise,
		TileLayer.BUSHES: detail_noise
	})
	add_child(chunk)

	var task := ChunkBuildTask.new()
	task.chunk_node = chunk
	task.chunk_pos = pos
	task.tiles_done = 0
	task.total_tiles = chunk_tile_size * chunk_tile_size
	generation_queue.append(task)

	loaded_chunks[pos] = chunk
	chunk_last_keep_time[pos] = time_elapsed

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

	for pos in to_unload:
		loaded_chunks[pos].queue_free()
		loaded_chunks.erase(pos)
		chunk_last_keep_time.erase(pos)

func _generate_chunks_step():
	var tiles_this_frame := 0

	while generation_queue.size() > 0 and tiles_this_frame < TILES_PER_FRAME:
		var task = generation_queue[0]
		var chunk = task.chunk_node

		if task.is_complete():
			generation_queue.pop_front()
			continue

		var base_x = task.chunk_pos.x * chunk_tile_size
		var base_y = task.chunk_pos.y * chunk_tile_size
		var layer = task.get_current_layer()

		while task.tiles_done < task.total_tiles and tiles_this_frame < TILES_PER_FRAME:
			var x = task.tiles_done % chunk_tile_size
			var y = task.tiles_done / chunk_tile_size
			task.tiles_done += 1
			tiles_this_frame += 1

			var world_x = base_x + x
			var world_y = base_y + y

			chunk.generate_tile(x, y, world_x, world_y, layer)


		if task.tiles_done >= task.total_tiles:
			task.tiles_done = 0
			task.current_layer_index += 1

func _update_chunk_pixel_size():
	chunk_pixel_size = chunk_tile_size * tile_size

func _update_debug_label():
	if not label_chunk:
		return
	label_chunk.text = "Chunks: %d\nFPS: %d" % [chunk_last_keep_time.size(), Engine.get_frames_per_second()]
