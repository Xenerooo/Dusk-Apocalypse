extends Node
var modulated_cells: Dictionary = {}

var current_modulated_tiles := {}
var last_modulated_tiles := {}

func get_global_tile_coords(tilemap: TileMapLayer, local_tile: Vector2i) -> Vector2i:
	var world_pos := tilemap.to_global(tilemap.map_to_local(local_tile))
	var tile_size := tilemap.tile_set.tile_size
	return Vector2i(floor(world_pos.x / tile_size.x), floor(world_pos.y / tile_size.y))
