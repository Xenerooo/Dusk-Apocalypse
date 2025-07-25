extends Node2D
class_name TerrainDebugOverlay

@export var terrain_logic: TerrainLogic
@export var font: Font  # Optional, for drawing text
@export var debug_point: Vector2i = Vector2i.ZERO
@export var snap_to_tile: bool = true
@export var show_mouse: bool = true

var debug_info := ""

func _process(_delta):
	if show_mouse:
		var mouse_pos = get_global_mouse_position()
		debug_point = mouse_pos.floor()

		if snap_to_tile:
			var tile_size = terrain_logic.tile_size if "tile_size" in terrain_logic else 24
			debug_point = Vector2i(debug_point / tile_size) 

		_update_debug_info()

func _update_debug_info():
	if terrain_logic == null:
		debug_info = "No TerrainLogic assigned."
		return

	var temp = terrain_logic.temperature_noise.get_noise_2d(debug_point.x, debug_point.y)
	var moist = terrain_logic.moisture_noise.get_noise_2d(debug_point.x, debug_point.y)
	var biome = terrain_logic.biome_classifier.classify(temp, moist)
	var tiles = terrain_logic.get_tiles_at(debug_point)

	debug_info = "📍 Debug Point: %s\n" % debug_point
	debug_info += "🌡 Temp: %.2f\n💧 Moisture: %.2f\n" % [temp, moist]
	debug_info += "🏞 Biome: %s\n" % biome
	debug_info += "🧱 Tiles:\n"

	for tile in tiles:
		debug_info += "  - %s @ %s [%d]\n" % [
			tile.get("layer", "?"),
			str(tile.get("atlas_coords", Vector2i.ZERO)),
			tile.get("source_id", -1)
		]

func _draw():
	draw_rect(Rect2(debug_point - Vector2i(2, 2), Vector2i(4, 4)), Color.YELLOW, true)
	if font and debug_info:
		draw_multiline_string(font, Vector2(10, 10), debug_info, HORIZONTAL_ALIGNMENT_LEFT)

func _ready():
	set_process(true)
	set_notify_transform(true)
	queue_redraw()

func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()
