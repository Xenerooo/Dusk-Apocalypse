extends Node
class_name TerrainLogic

@export var biome_noise: FastNoiseLite
@export var seed := 1337

func _ready():
	biome_noise.seed = seed

func get_biome_at(pos: Vector2i) -> String:
	var n := biome_noise.get_noise_2d(pos.x, pos.y)

	if n < -0.3:
		return "plains"
	elif n > 0.2:
		return "forest"
	else:
		return "plains"  # fallback biome
