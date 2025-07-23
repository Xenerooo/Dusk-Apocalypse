@tool
extends Node

# Set this in the editor or in code
@export var old_resource_path: String = "res://path/to/old_file.res"
@export var new_resource_path: String = "res://path/to/new_file.res"

@export_tool_button("Migrate Old Resource")
var migrate_old_resource_button = migrate_old_resource


func migrate_old_resource():
	var old_res := load(old_resource_path)
	if old_res == null or not (old_res is OldMapStructureResource):
		print("❌ Failed to load or invalid OldMapStructureResource")
		return

	var new_res := MapStructureResource.new()
	new_res.chunk_id = old_res.chunk_id
	new_res.layers = {}

	for i in old_res.layer_names.size():
		var layer_name = old_res.layer_names[i]
		var positions = old_res.layer_positions[i]
		var source_ids = old_res.layer_source_ids[i]
		var atlas_coords = old_res.layer_atlas_coords[i]

		new_res.layers[layer_name] = {
			"positions": positions,
			"source_ids": source_ids,
			"atlas_coords": atlas_coords
		}

	var err := ResourceSaver.save(new_res, new_resource_path, ResourceSaver.FLAG_COMPRESS)

	if err == OK:
		print("✅ Migration successful: ", new_resource_path)
	else:
		print("❌ Migration failed with error: ", err)
