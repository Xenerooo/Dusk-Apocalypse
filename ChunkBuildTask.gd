extends RefCounted
class_name ChunkBuildTask

var chunk_node: Node
var chunk_pos: Vector2i
var total_tiles: int
var tiles_done: int = 0

enum TileLayer {
	GROUND,
	TREES,
	BUSHES
}
var layer_order := [TileLayer.GROUND, TileLayer.TREES, TileLayer.BUSHES]
var current_layer_index: int = 0

func get_current_layer() -> TileLayer:
	return layer_order[current_layer_index]

func is_complete() -> bool:
	return current_layer_index >= layer_order.size()
