extends TileMapLayer

func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate = GlobalOccluder.modulated_cells.get(GlobalOccluder.get_global_tile_coords(self, coords), Color(1,1,1,1))

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return GlobalOccluder.modulated_cells.has(GlobalOccluder.get_global_tile_coords(self, coords))

func rdy():
	notify_runtime_tile_data_update()
