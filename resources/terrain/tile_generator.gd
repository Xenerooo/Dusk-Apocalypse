extends Node
class_name TileGenerator

@export var ground_variation: FastNoiseLite
@export var tree_variation: FastNoiseLite
@export var vegetation_variation: FastNoiseLite
@export var noise_variation: FastNoiseLite

func generate_tiles(world_pos: Vector2i, terrain: TerrainLogic) -> Array:
	var biome := terrain.get_biome_at(world_pos)
	var tiles: Array = []

	var g_var := ground_variation.get_noise_2d(world_pos.x, world_pos.y)
	var t_var := tree_variation.get_noise_2d(world_pos.x, world_pos.y)
	var v_var := vegetation_variation.get_noise_2d(world_pos.x, world_pos.y)
	var n_var := noise_variation.get_noise_2d(world_pos.x, world_pos.y)
	
	var ground_tile := get_variant_x(n_var)
	#tiles.append({
			#"layer": "Ground",
			#"source_id": 0,
			#"atlas_coords": Vector2i(ground_tile, 3)
		#})
	match biome:
		"forest":
			# Ground
			var g_tile := get_variant_x(n_var)
			tiles.append({
				"layer": "Ground",
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
				var v_tile :=  get_variant_x(n_var)
				tiles.append({
					"layer": "Vegetation",
					"source_id": 0,
					"atlas_coords": Vector2i(v_tile, 0)
				})

		"plains":
			# Grass
			var g_tile :=  get_variant_x(n_var)
			tiles.append({
				"layer": "Ground",
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
				var v_tile := get_variant_x(n_var)
				tiles.append({
					"layer": "Vegetation",
					"source_id": 0,
					"atlas_coords": Vector2i(v_tile, 1)
				})

		_:
			# fallback ground
			tiles.append({
				"layer": "Ground",
				"source_id": 0,
				"atlas_coords": Vector2i(1, 0)
			})

	return tiles


func get_variant_x(noise_val, variation_count:=3) -> int:
	#var variant_count = TILE_VARIANT_COUNT.get(tile_type_y, 1)

	#if variant_count <= 1:
		#return 0  # Only one variant for this tile type

	#var noise_val = noise.get_noise_2d(pos.x, pos.y)
	var normalized = (noise_val + 1.0) / 2.0  # Map from [-1, 1] to [0, 1]
	var x_variant = int(normalized * variation_count)

	return clamp(x_variant, 0, variation_count - 1)
