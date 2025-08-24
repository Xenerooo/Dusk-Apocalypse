#WorldManager
extends Node
var map_size := Vector2i()
var tile_size :float
var chunk_size : float
var seed := 0
var chunks := {}  # Dictionary<Vector2i, Dictionary>

func load_data(world_dict: Dictionary):
	map_size = world_dict.map_size
	tile_size = world_dict.tile_size
	chunk_size = world_dict.chunk_size
	seed = world_dict.get("seed", 0)
	chunks = world_dict.get("chunks", {})
	setup_world(seed)

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
	var manager:ChunkManagerMP = GameSession.current_world_node.chunk_manager
	if manager :
		var data = manager.world_save
		SaveHelper.save_dict_to_file(data, path.path_join("world.bin"))

@rpc("authority")
func setup_world(_seed: int = seed):
	var chunk_manager :ChunkManagerMP= GameSession.current_world_node.chunk_manager
	chunk_manager.set_seed(_seed)
	chunk_manager.warm_up(get_world_data())

func reset_manager():
	map_size = Vector2i()
	tile_size = 0.0
	chunk_size = 0.0
	seed = 0
	chunks = {}  # Dictionary<Vector2i, Dictionary>

func set_visual_tile():
	pass

func get_player_current_audio(player:PlayerCharacter) -> int:
	var chunk_manager :ChunkManagerMP= GameSession.current_world_node.chunk_manager
	var player_pos = player.global_position
	
	var chunk :Chunk= chunk_manager.get_current_chunk_node(player_pos)
	
	if chunk:
		var data :int = chunk.get_audio_data(player_pos, "Ground")
		
		return data

	return -1
	#chunk_manager.get_current_chunk_node()
	
