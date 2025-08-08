#GameSession
extends Node

var active_players := {}  # token → scene reference
var local_player :Player

var current_world_path : String
var current_world_node: Node2D

var player_container:Node2D = null
@onready var spawner :MultiplayerSpawner= $PlayerSpawner

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("save"):
		save_world()

func _ready():
	spawner.spawn_function = _on_spawn_entity  # Custom handler
	print("GameSession ready")

func join_world():
	var world_scene = preload("res://World.tscn").instantiate()
	current_world_node = world_scene
	var scene_root = get_node("/root/Main/SceneRoot")
	scene_root.add_child(world_scene)
	scene_root.get_node("MenuMargins").queue_free()
	
	MultiplayerManager.request_world_setup.rpc_id(1)
	#world_scene.chunk_manager.warm_up({})
	GameUI.show()

#@rpc()
#func instance_client_world():
	#

func load_world(path: String) -> void:
	print("💾 Loading world from: ", path)
	current_world_path = path

	# 1. Clear any existing world
	if is_instance_valid(current_world_node):
		current_world_node.queue_free()
		current_world_node = null

	# 2. Load JSON files
	var world_data = SaveHelper.load_dict_from_file(path.path_join("world.bin"))
	var players_data = SaveHelper.load_json(path.path_join("players.json"))
	var storages_data = SaveHelper.load_json(path.path_join("storages.json"))
	var meta_data = SaveHelper.load_json(path.path_join("meta.json"))

	# 3. Pass to managers

	#StorageManager.load_data(storages_data)
	# MultiplayerManager will also be notified if needed

	# 4. Instance world scene
	var world_scene = preload("res://World.tscn").instantiate()
	current_world_node = world_scene
	var scene_root = get_node("/root/Main/SceneRoot")
	scene_root.add_child(world_scene)
	scene_root.get_node("MenuMargins").queue_free()
	
	
	WorldManager.load_data(world_data)
	PlayerManager.load_data(players_data)
	#world_scene.chunk_manager.warm_up(WorldManager.get_world_data())
	
	# 5. Set world state
	world_scene.load_world_data()  # optional
	MultiplayerManager.start_host()
	GameUI.show()

func _on_spawn_entity(data:Dictionary) -> Node:
	if data.type_key == "Player":
		return _spawn_player_scene(data.token)
	return null

func spawn_player(player_token: String):
	if active_players.has(player_token):
		return
	var data:= {"type_key": 'Player', "token": player_token}
	spawner.spawn(data)  # Type + data

func _spawn_player_scene(token: String) -> Node:
	var player = preload("res://scenes/player/player.tscn").instantiate()
	player.token = token

	var peer_id = PlayerManager.get_peer_id(token)
	#print("🌐 Spawn Called %s compared to %s" % [multiplayer.get_unique_id(), peer_id])
	player.name = str(peer_id)
	if PlayerProfile.token == token:
		local_player = player
		
		#TEST make a seperate function for this.
		var chunk_manager :ChunkManagerMP= get_node_or_null( "/root/Main/SceneRoot/World/ChunkManager")
		if chunk_manager :
			chunk_manager.player_ref = local_player
		#print("🌐 I am who i am")
	if multiplayer.is_server() :
		player.global_position = PlayerManager.get_position(token)

		PlayerManager.set_player_node(token, player)
		active_players[token] = player
	# We dont need to manually set where to spawn them because spawner handles it base where we set the spawn path
	# We already have path so it's okay
	return player


func despawn_player(player_token: String):
	if not active_players.has(player_token):
		return

	var player_node = active_players[player_token]
	player_node.queue_free()

	PlayerManager.set_player_node(player_token, null)
	active_players.erase(player_token)

func respawn_player(player_token: String):
	despawn_player(player_token)
	spawn_player(player_token)

func set_player_container(node: Node2D):
	player_container =node
	spawner.spawn_path = node.get_path()

func save_world():
	if current_world_path.is_empty():
		push_error("❌ No world path to save to")
		return

	print("💾 Saving world to: ", current_world_path)

	WorldManager.save_data(current_world_path)
	PlayerManager.save_data(current_world_path)
	#StorageManager.save_data(current_world_path)

	# Save meta if needed
	var meta = {
		"last_saved": Time.get_datetime_string_from_system()
	}
	SaveHelper.save_json(current_world_path.path_join("meta.json"), meta)

	print("✅ World save complete")
