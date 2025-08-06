extends Node
var map_size := Vector2i()
var tile_size :float
var chunk_size : float
var seed := 0
var chunks := {}  # Dictionary<Vector2i, Dictionary>

func load_data(world_dict: Dictionary):
	map_size = SaveHelper.string_to_vector2(world_dict.map_size)
	tile_size = world_dict.tile_size
	chunk_size = world_dict.chunk_size
	seed = world_dict.get("seed", 0)
	chunks = world_dict.get("chunks", {})

func get_chunks() -> Dictionary:
	return chunks

func get_world_data() -> Dictionary:
	return {
		"map_size": map_size,
		"tile_size": tile_size,
		"chunk_size": chunk_size,
		"seed": seed,
		"chunks": chunks
	}

func save_data(path: String):
	var data = get_world_data()
	SaveHelper.save_json(path.path_join("world.json"), data)
