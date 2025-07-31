extends Node2D

const CHUNK_SIZE_TILES := 40
const CELL_TILE_AREA := 200  # 1 small map cell = 200x200 tile block

@export var small_map_reference : Node # Reference to the node/script that has the small map
@export var prefab_database : Dictionary = {
	"city_single" : "res://resources/structures/structure_city_single.res",
	"structure_empty": "res://resources/structures/structure_empty.res"
} # Map of prefab_id -> PackedScene

func generate_big_map_data_from_small_map(small_map: Dictionary, prefab_path_lookup: Dictionary = prefab_database) -> Dictionary:
	var big_map := {
		"chunk_size": Vector2i(200, 200),
		"tile_size": Vector2i(32, 32),
		"layers": {}  # layer_name => {positions, source_ids, atlas_coords}
	}

	for region_pos in small_map["regions"].keys():
		await get_tree().process_frame
		print("🔃 Writing Chunk %s" % [region_pos])
		var cell = small_map["regions"][region_pos]
		if not cell.has("prefab_id"):
			continue
			

		var prefab_id = cell["prefab_id"]
		if not prefab_path_lookup.has(prefab_id):
			continue
		
		
		var res_path = prefab_path_lookup[prefab_id]
		var chunk_resource: MapStructureResource = load(res_path)
		var world_offset = region_pos * 200
		#await get_tree().process_frame
		for i in chunk_resource.layer_names.size():
			var layer_name = chunk_resource.layer_names[i]
			var layer_positions = chunk_resource.layer_positions[i]
			var layer_source_ids = chunk_resource.layer_source_ids[i]
			var layer_atlas_coords = chunk_resource.layer_atlas_coords[i]

			# Make sure layer exists in big map
			if not big_map["layers"].has(layer_name):
				big_map["layers"][layer_name] = {
					"positions": PackedVector2Array(),
					"source_ids": PackedInt32Array(),
					"atlas_coords": PackedVector2Array()
				}

			# Append tiles to big_map, offsetting positions
			for j in layer_positions.size():
				var pos = Vector2i(layer_positions[j]) + world_offset
				big_map["layers"][layer_name]["positions"].append(pos)
				big_map["layers"][layer_name]["source_ids"].append(layer_source_ids[j])
				big_map["layers"][layer_name]["atlas_coords"].append(layer_atlas_coords[j])

	return big_map
