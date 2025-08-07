@tool
extends Node

# Set this in the editor or in code
@export var old_resource_path: String = "res://path/to/old_file.res"
@export var new_resource_path: String = "res://path/to/new_file.res"

@export_tool_button("Migrate Old Resource")
var migrate_old_resource_button = migrate_old_resource

@export var resources : Array[MapStructureResource]
@export_tool_button("Migrate Resources")
var mig = migrate_resources

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
		var alt_tiles = old_res.layer_atlas_coords[i]

		new_res.layers[layer_name] = {
			"positions": positions,
			"source_ids": source_ids,
			"atlas_coords": atlas_coords,
			"alt_tile": 0 if alt_tiles == null else alt_tiles
		}

	var err := ResourceSaver.save(new_res, new_resource_path, ResourceSaver.FLAG_COMPRESS)

	if err == OK:
		print("✅ Migration successful: ", new_resource_path)
	else:
		print("❌ Migration failed with error: ", err)

func migrate_resources():
	
	for r in resources.size():

		if resources[r] == null :
			continue
		
		
		var res :MapStructureResource= resources[r]
		convert_prefab_arrays_to_dict(res)
		resources[r] = null
		#var res_path = res.resource_path
		#var old_res := load(res_path)
		#var temp_path : = "res://resources/structures/to_delete_%s" % [r]
		#if old_res == null or not (old_res is MapStructureResource):
			#print("❌ Failed to load or invalid OldMapStructureResource")
			#return
		#
		#res.resource_path =  temp_path
		#resources[r] = null
		#
		#var new_res := MapStructureResource.new()
		#new_res.chunk_id = old_res.chunk_id
		#new_res.layers = {}
		##print(old_res.layers.keys())
		#for layer_name in old_res.layers.keys():
			##var layer_name = old_res.layers[i]
			#var positions = old_res.layers[layer_name]
			#var source_ids = old_res.layers[layer_name]
			#var atlas_coords = old_res.layers[layer_name]
			#var alt_tiles :PackedInt32Array = []
#
			#for z in positions.size() :
				#alt_tiles.append(0)
#
			#new_res.layers[layer_name] = {
				#"positions": positions,
				#"source_ids": source_ids,
				#"atlas_coords": atlas_coords,
				#"alt_tile": alt_tiles
			#}
			#
		#if FileAccess.file_exists(temp_path):
			#print("🚮 removed %s" % [temp_path])
			#DirAccess.remove_absolute(temp_path)
			#
		#var err := ResourceSaver.save(new_res, res_path, ResourceSaver.FLAG_COMPRESS)
#
		#if err == OK:
			#print("✅ Migration successful: ", res_path)
		#else:
			#print("❌ Migration failed with error: ", err)
		
		await get_tree().process_frame


func convert_prefab_arrays_to_dict(prefab: MapStructureResource):
	var original_path := prefab.resource_path
	
	prefab.resource_path = "res://resources/structures/temp1.res"
	
	var new_prefab := MapStructureResource.new()
	new_prefab.chunk_id = prefab.chunk_id
	
	for layer_name in prefab.layers.keys():
		var old = prefab.layers[layer_name]
		var new_layer := {}

		for i in old["positions"].size():
			var pos = Vector2i(old["positions"][i])
			var key = str(pos)
			new_layer[key] = {
				"source_id": old["source_ids"][i],
				"atlas_coords": Vector2i(old["atlas_coords"][i]),
				"alt_tile": old["alt_tile"][i],
			}

		new_prefab.layers[layer_name] = new_layer
		
	var err:= ResourceSaver.save(new_prefab, original_path, ResourceSaver.FLAG_COMPRESS)
	if err == OK:
		print("Successfully migrated")

	if FileAccess.file_exists("res://resources/structures/temp1.res"):
		print("🚮 removed %s" % ["res://resources/structures/temp1.res"])
		DirAccess.remove_absolute("res://resources/structures/temp1.res")
