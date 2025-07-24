extends Node
class_name TerrainLogic

@export var ground_noise :FastNoiseLite
@export var tree_noise :FastNoiseLite
@export var seed: int = 1337
@export var frequency: float = 0.02

#func _ready():
	#ground_noise.seed = seed
	#tree_noise.seed = seed

func get_tiles_at(world_pos: Vector2i) -> Array:
	#print(world_pos)
	var tiles := []
	#print(world_pos)
	var n = ground_noise.get_noise_2d(world_pos.x, world_pos.y)
	var v = tree_noise.get_noise_2d(world_pos.x, world_pos.y)
	if n > 0.0:
		tiles.append({
			"layer": "Ground2",
			"source_id": 0,
			"atlas_coords": Vector2i(0, 0)
		})
	elif n < 0.0:
		tiles.append({
			"layer": "Ground2",
			"source_id": 0,
			"atlas_coords": Vector2i(1, 0)
		})
		if v < 0.0:
			tiles.append({
				"layer": "Vegetation",
				"source_id": 0,
				"atlas_coords": Vector2i(0, 0)
			})
		elif v > 0.3:
			tiles.append({
				"layer": "Trees",
				"source_id": 0,
				"atlas_coords": Vector2i(0, 0)
			})
	#if n > 0.7:
		#tiles.append({
			#"layer": "Vegetation",
			#"source_id": 0,
			#"atlas_coords": Vector2i(1, 0)
		#})

	return tiles
