extends Node2D
class_name Chunk
@export var tile_size: int = 32
@export var chunk_tile_size: int = 32
var chunk_pos: Vector2i

@export var notifier: VisibleOnScreenNotifier2D

@export_subgroup("Environment")
@export var map: Node2D
@export var ground: TileMapLayer
@export var ground2: TileMapLayer
@export var vegetation: TileMapLayer
@export var trees: TileMapLayer

@export_subgroup("Buildings")
@export var building: Node2D
@export var building_outline: TileMapLayer
@export var interiorWall: TileMapLayer
@export var exteriorWall: TileMapLayer
@export var floor: TileMapLayer
@export var roof: TileMapLayer

# Frame-sliced generation data
var pending_layers: Dictionary = {}
var current_layer_name: String = ""
var tiles_done := 0
var total_tiles := 0

# === Tile data loading ===
func set_tile_data(layer_data: Dictionary):
	pending_layers = layer_data.duplicate(true)
	_start_next_layer()

func _start_next_layer():
	if pending_layers.is_empty():
		current_layer_name = ""
		return
	current_layer_name = pending_layers.keys()[0]
	tiles_done = 0
	total_tiles = pending_layers[current_layer_name].size()

func process_tiles_step(max_tiles: int) -> bool:
	if current_layer_name == "":
		return true

	var layer: TileMapLayer = get_layer_by_name(current_layer_name)
	if layer == null:
		push_warning("Layer not found: %s" % current_layer_name)
		pending_layers.erase(current_layer_name)
		_start_next_layer()
		return false

	var data: Array = pending_layers[current_layer_name]
	var tiles_this_frame = 0
	while tiles_done < total_tiles and tiles_this_frame < max_tiles:
		var tile_info = data[tiles_done]
		tiles_done += 1
		tiles_this_frame += 1

		# ✅ Already local to this chunk
		var local_pos = Vector2i(tile_info.position[0], tile_info.position[1])
		var source_id = tile_info.source_id
		var atlas_coords = Vector2i(tile_info.atlas_coords[0], tile_info.atlas_coords[1])

		layer.set_cell(local_pos, source_id, atlas_coords)

	if tiles_done >= total_tiles:
		pending_layers.erase(current_layer_name)
		_start_next_layer()

	return pending_layers.is_empty()


func get_layer_by_name(_name: String) -> TileMapLayer:
	match _name:
		"Ground": return ground
		"Ground2": return ground2
		"Trees": return trees
		"Vegetation": return vegetation
		"BuildingOutline": return building_outline
		"ExteriorWall": return exteriorWall
		"InteriorWall": return interiorWall
		"Floor": return floor
		"Roof": return roof
		_: return null

func update_notifier():
	var size := tile_size * chunk_tile_size
	notifier.rect = Rect2(Vector2.ZERO, Vector2(size, size))
	name = str(chunk_pos)

func reset():
	for tilemap in [ground,ground2, trees, vegetation, building_outline, exteriorWall, interiorWall, floor, roof]:
		tilemap.clear()

func _on_visibilty_notifier_screen_entered() -> void:
	map.show()
	building.show()
	print("Chunk %s visible" % [chunk_pos])

func _on_visibilty_notifier_screen_exited() -> void:
	map.hide()
	building.hide()
