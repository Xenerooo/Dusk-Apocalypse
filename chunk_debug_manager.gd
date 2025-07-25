extends Node2D

@onready var chunk_manager := get_parent()
@export var world_chunk_size :=200

func get_save_chunk_info_from_mouse() -> Dictionary:
	var mouse_pos = get_global_mouse_position()
	var tile_size = chunk_manager.tile_size
	var chunk_tile_size :int= chunk_manager.chunk_tile_size
	
	
	# 1. Convert to tile coordinates
	var tile_coords = Vector2i(mouse_pos / tile_size)
	
	# 2. Get ChunkManager chunk coords
	var chunk_manager_chunk = tile_coords / chunk_tile_size
	
	# 3. Convert to save world chunk
	var PREFAB_TILE_SIZE := 200  # must match your save format
	var TILES_PER_PREFAB := PREFAB_TILE_SIZE / chunk_tile_size
	var world_chunk_coords = chunk_manager_chunk / TILES_PER_PREFAB
	
	return {
		"node": chunk_manager.get_node_or_null(str(chunk_manager_chunk)),
		"mouse_pos": mouse_pos,
		"tile_coords": tile_coords,
		"chunk_manager_chunk": chunk_manager_chunk,
		"world_chunk_coords": world_chunk_coords
	}

func _unhandled_input(event):
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var info = get_save_chunk_info_from_mouse()
		print("🧭 Clicked World Chunk: ", info["world_chunk_coords"])
		print("🧩 Tile Pos: ", info["tile_coords"], " in ChunkManager Chunk: ", info["chunk_manager_chunk"], info["node"])
