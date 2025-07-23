@tool# WorldSaveResource.gd
extends Resource
class_name WorldSaveResource
@export var map_size: Vector2i
@export var tile_size: int
@export var chunk_size: int
@export var chunks: Dictionary  # key: Vector2i (chunk_id), value: Dictionary with prefab_id and optional overrides
@export_tool_button("Debug Map")
var debug_map_tool = debug_print_map

func debug_print_map():
	var regions = chunks
	var size = map_size
	print("\n=== MAP DEBUG ===")

	for y in size.y:
		var line := ""
		for x in size.x:
			var pos = Vector2i(x, y)
			if not regions.has(pos):
				#line += ". "
				continue

			var cell = regions[pos]
			match cell.get("type", "empty"):
				"structure_empty": line += ". "
				"road": line += "# "
				"city":
					var city_id = cell.get("meta_data", {}).get("city_id", -1)
					line += str(city_id) + " "
				_: line += "? "
		print(line)

	var l := "\n"
	for i in size.x:
		l += "= "
	l += "\n"
	print(l)
