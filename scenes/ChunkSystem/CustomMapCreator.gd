@tool
extends Node2D

@export var TILE_SIZE = 24
@export var CHUNK_SIZE = 32  # in tiles, NOT pixels
const SAVE_DIR = "res://resources/structures/"

@export_tool_button("Reset")
var tool_reset_map = reset_tilemaps

@export_category("Prefab Resource")
@export var resource_save_name := ""
@export_tool_button("Save as Resource")
var resource_save = await save_as_resource

@export_category("Prefab Loading")
@export var map_resource: MapStructureResource:
	set(value):
		if Engine.is_editor_hint():
			map_resource = value

@export_tool_button("Load Map")
var tool_load = tool_laod_map


func tool_laod_map():
	if map_resource != null:
		resource_save_name = map_resource.resource_path.get_file().get_basename()
		load_prefab_to_tilemaps(map_resource, Vector2.ZERO, 200)
		map_resource = null
		
	else:
		print("❌ Failed to load, fill the map resource")


func reset_tilemaps():
	if !Engine.is_editor_hint:
		return
	var tilemap_layers: Array[TileMapLayer] = [
		$Map/Ground,
		$Map/Ground2,
		$Map/Vegetation,
		$Map/Props,
		$Map/Trees,
		$Building/Building,

	]
	for i in tilemap_layers:
		i.clear()


func save_as_resource():
	if !Engine.is_editor_hint:
		return

	var chunk_map = group_tiles_by_chunk({
		"Ground": $Map/Ground,
		"Ground2": $Map/Ground2,
		"Props": $Map/Props,
		"Vegetation": $Map/Vegetation,
		"Trees": $Map/Trees,
		"Building": $Building/Building,

	})

	#for chunk_id in chunk_map.keys():
	var chunk_resource := MapStructureResource.new()

	#chunk_resource.chunk_id = chunk_id

	for layer_name in chunk_map.keys():
		var tiles = chunk_map[layer_name]

		var positions := PackedVector2Array()
		var source_ids := PackedInt32Array()
		var atlas_coords := PackedVector2Array()
		var alt_tile := PackedInt32Array()

		for tile in tiles:
			positions.append(Vector2(tile["position"][0], tile["position"][1]))
			source_ids.append(tile["source_id"])
			alt_tile.append(tile["alt_tile"])
			atlas_coords.append(Vector2(tile["atlas_coords"][0], tile["atlas_coords"][1]))

		chunk_resource.layers[layer_name] = {
			"positions": positions,
			"source_ids": source_ids,
			"atlas_coords": atlas_coords,
			"alt_tile": alt_tile
		}

	if resource_save_name.is_empty():
		print("❌ Failed to save, need resource name")
		return

	var save_path = "%s/%s.res" % [SAVE_DIR, resource_save_name]

	# Optional safety: delete file before overwriting
	if FileAccess.file_exists(save_path):
		var temp:= SAVE_DIR + ("temp_%s" % [resource_save_name])
		var res := ResourceLoader.load(save_path)
		res.resource_path = temp
		DirAccess.remove_absolute(temp)
		print("🚮 removed %s" % [save_path])

	var save_flags = ResourceSaver.FLAG_COMPRESS | ResourceSaver.FLAG_REPLACE_SUBRESOURCE_PATHS
	var err = ResourceSaver.save(chunk_resource, save_path, save_flags)

	match err:
		OK:
			reset_tilemaps()
			resource_save_name = ""
			map_resource = null
			print("✅ Saved: %s" % save_path)
			EditorInterface.save_scene()
			await get_tree().create_timer(1).timeout
			EditorInterface.reload_scene_from_path("res://CustomMapCreator.tscn")
		ERR_FILE_CANT_WRITE:
			print("❌ Can't write to file: %s" % save_path)
		_:
			print("❌ Unknown error (%s) saving file: %s" % [err, save_path])


func load_prefab_to_tilemaps(_resource: MapStructureResource, target_chunk_pos: Vector2i, chunk_tile_size := 200):
	if _resource == null:
		return

	var tilemap_layers := {
		"Ground": $Map/Ground,
		"Ground2": $Map/Ground2,
		"Props": $Map/Props,
		"Vegetation": $Map/Vegetation,
		"Trees": $Map/Trees,
		"Building": $Building/Building,
	}

	var offset = target_chunk_pos * chunk_tile_size

	for layer_name in _resource.layers.keys():
		if not tilemap_layers.has(layer_name):
			continue

		var tilemap: TileMapLayer = tilemap_layers[layer_name]
		var layer_data = _resource.layers[layer_name]

		var positions: PackedVector2Array = layer_data["positions"]
		var source_ids: PackedInt32Array = layer_data["source_ids"]
		var atlas_coords: PackedVector2Array = layer_data["atlas_coords"]
		var alt_tiles: PackedInt32Array = layer_data["alt_tile"]

		tilemap.clear()
		for j in positions.size():
			var tile_pos: Vector2i = Vector2i(positions[j]) + offset
			var source_id = source_ids[j]
			var alt_tile = alt_tiles[j]
			var atlas_coord = Vector2i(atlas_coords[j])
			tilemap.set_cell(tile_pos, source_id, atlas_coord, alt_tile)


func get_chunk_id_from_cell(cell: Vector2i) -> Vector2i:
	return Vector2i(
		(cell.x / CHUNK_SIZE),
		(cell.y / CHUNK_SIZE)
	)


func group_tiles_by_chunk(layers: Dictionary) -> Dictionary:
	var chunk_map := {}
	chunk_map = {}

	for layer_name in layers.keys():
		var tilemap: TileMapLayer = layers[layer_name]
		var used_cells := tilemap.get_used_cells()

		chunk_map[layer_name] = []

		for cell in used_cells:
			var chunk_id := get_chunk_id_from_cell(cell)

			var source_id = tilemap.get_cell_source_id(cell)
			var atlas_coords = tilemap.get_cell_atlas_coords(cell)
			var alt_tile = tilemap.get_cell_alternative_tile(cell)

			chunk_map[layer_name].append({
				"position": [cell.x, cell.y],
				"source_id": source_id,
				"atlas_coords": [atlas_coords.x, atlas_coords.y],
				"alt_tile": alt_tile
			})

	return chunk_map
