extends Node2D
@export var tile_size: int = 32
@export var chunk_tile_size: int = 32
var chunk_pos: Vector2i

# Internal TileMap reference
@export var ground: TileMapLayer
@export var bush: TileMapLayer
@export var trees: TileMapLayer

enum TileLayer {
	GROUND,
	TREES,
	BUSHES
}

var layers := {}
var noise_maps: Dictionary = {}

func set_noise_maps(maps: Dictionary):
	noise_maps = maps

func generate_tile(
	local_x: int,
	local_y: int,
	world_x: int,
	world_y: int,
	layer: TileLayer
) -> void:
	var tilemap_layer: TileMapLayer
	match layer:
		TileLayer.GROUND: tilemap_layer = ground
		TileLayer.TREES: tilemap_layer = trees
		TileLayer.BUSHES: tilemap_layer = bush
		_: tilemap_layer = null

	if tilemap_layer == null:
		push_warning("Invalid layer passed to generate_tile: %s" % str(layer))
		return

	var noise_map :FastNoiseLite= noise_maps.get(layer, null)
	if noise_map == null:
		push_warning("No noise map found for layer: %s" % str(layer))
		return

	var noise_value := noise_map.get_noise_2d(world_x, world_y)
	var tile_id := _get_tile_id_for_layer(noise_value, layer)

	if tile_id >= 0:
		tilemap_layer.set_cell(Vector2i(local_x, local_y), tile_id, Vector2i.ZERO)



func _get_tile_id_for_layer(value: float, layer: TileLayer) -> int:
	match layer:
		TileLayer.GROUND:
			return 0 if value < 0 else 1
		TileLayer.BUSHES:
			return 0 if value > 0.15 and value <.21 else -1
		TileLayer.TREES:
			return 0 if value > 0.3 and value < .31 else -1
		_:
			return -1
