extends Node
class_name TileGenerator

@export var ground_variation: FastNoiseLite
@export var tree_variation: FastNoiseLite
@export var vegetation_variation: FastNoiseLite

func generate_tiles(world_pos: Vector2i, terrain: TerrainLogic) -> Array:
	var biome := terrain.get_biome_at(world_pos)
	var tiles: Array = []

	var g_var := ground_variation.get_noise_2d(world_pos.x, world_pos.y)
	var t_var := tree_variation.get_noise_2d(world_pos.x, world_pos.y)
	var v_var := vegetation_variation.get_noise_2d(world_pos.x, world_pos.y)

	match biome:
		"forest":
			# Ground
			var g_tile := int(abs(g_var) * 2.0)  # 0 or 1
			tiles.append({
				"layer": "Ground2",
				"source_id": 0,
				"atlas_coords": Vector2i(g_tile, 2)
			})

			# Trees (dense forest)
			if t_var < -0.23:
				var t_tile := int(t_var * 2.0) % 2
				tiles.append({
					"layer": "Trees",
					"source_id": 0,
					"atlas_coords": Vector2i(0, 0)
				})

			# Vegetation
			if v_var < -0.1:
				var v_tile := int(v_var * 3.0) % 2
				tiles.append({
					"layer": "Vegetation",
					"source_id": 0,
					"atlas_coords": Vector2i(0, 0)
				})

		"plains":
			# Grass
			var g_tile := int(abs(g_var) * 2.0)  # 0 or 1
			tiles.append({
				"layer": "Ground2",
				"source_id": 0,
				"atlas_coords": Vector2i(g_tile, 1)
			})

			# Sparse trees
			if t_var > 0.45:
				tiles.append({
					"layer": "Trees",
					"source_id": 0,
					"atlas_coords": Vector2i(1, 0)
				})

			# Sparse bushes
			if v_var > 0.0:
				var v_tile := int(v_var * 2.0) % 2
				tiles.append({
					"layer": "Vegetation",
					"source_id": 0,
					"atlas_coords": Vector2i(v_tile, 1)
				})

		_:
			# fallback ground
			tiles.append({
				"layer": "Ground2",
				"source_id": 0,
				"atlas_coords": Vector2i(1, 0)
			})

	return tiles
