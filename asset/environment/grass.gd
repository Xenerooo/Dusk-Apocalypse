extends TileMapLayer


func _use_tile_data_runtime_update( coords: Vector2i) -> bool:
	return true


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	tile_data.texture_origin += Vector2i(0, randi_range(-10, 10))

#
#func _process(delta: float) -> void:
	#notify_runtime_tile_data_update(0)
