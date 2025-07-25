extends TileGenerator
class_name GroundGenerator

func get_tiles(world_pos: Vector2i, context := {}) -> Array:
	var biome = context.get("biome", "")
	var tiles := []

	match biome:
		"dry_plains":
			tiles.append({
				"layer": "Ground2",
				"source_id": 0,
				"atlas_coords": Vector2i(0, 1)
			})
		"forest":
			tiles.append({
				"layer": "Ground2",
				"source_id": 0,
				"atlas_coords": Vector2i(2, 0)
			})
		#"swamp":
			#tiles.append({
				#"layer": "Ground2",
				#"source_id": 0,
				#"atlas_coords": Vector2i(3, 0)
			#})
		#"dead_zone":
			#tiles.append({
				#"layer": "Ground2",
				#"source_id": 0,
				#"atlas_coords": Vector2i(5, 0)
			#})
		_:
			tiles.append({
				"layer": "Ground2",
				"source_id": 0,
				"atlas_coords": Vector2i(0, 3)
			})

	return tiles
