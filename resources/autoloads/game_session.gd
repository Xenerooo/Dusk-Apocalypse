#GameSession
extends Node

const MAIN_MENU = preload("res://scenes/main/main_menu/main_menu.tscn")

var active_players := {}  # token → scene reference
var local_player :PlayerCharacter

var current_world_path : String
var current_world_node: Node2D

var player_container: Node2D = null
var on_session:=false

@onready var spawner :MultiplayerSpawner= $PlayerSpawner

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("save"):
		save_world()

func _ready():
	if OS.request_permissions() == false:
		OS.request_permission("android.permission.READ_EXTERNAL_STORAGE")
		OS.request_permission("android.permission.MANAGE_EXTERNAL_STORAGE")
	
	spawner.spawn_function = _on_spawn_entity  # Custom handler
	print("GameSession ready")

func join_world():
	var world_scene = preload("res://World.tscn").instantiate()
	current_world_node = world_scene
	
	#GameSession.set_player_container(world_scene.entity_container)
	#AudioManager.set_audio_container(world_scene.audio_container)
	var scene_root = get_node("/root/Main/SceneRoot")
	scene_root.add_child(world_scene)
	scene_root.get_node("MenuMargins/MainMenu").queue_free()
	
	MultiplayerManager.request_world_setup.rpc_id(1)
	#world_scene.chunk_manager.warm_up({})
	GameUI.show_controls()

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
	var inventory_data = SaveHelper.load_json(path.path_join("inventory.json"))
	var meta_data = SaveHelper.load_json(path.path_join("meta.json"))

	# 3. Pass to managers

	#StorageManager.load_data(storages_data)
	# MultiplayerManager will also be notified if needed

	# 4. Instance world scene
	var world_scene = preload("res://World.tscn").instantiate()
	current_world_node = world_scene
	
	
	var scene_root = get_node("/root/Main/SceneRoot")
	scene_root.get_node("MenuMargins/MainMenu").queue_free()
	scene_root.add_child(world_scene)

	PlayerManager.load_data(players_data)
	InventoryManager.load_data(inventory_data)
	MultiplayerManager.start_host()

	WorldManager.load_data(world_data)
	
	#print(multiplayer.multiplayer_peer)
	
	# 5. Set world state
	world_scene.load_world_data()  # optional
	on_session = true
	GameUI.show_controls()

func _on_spawn_entity(data:Dictionary) -> Node:
	if data.type_key == "Player":
		return _spawn_player_scene(data.token)
	elif data.type_key == "Bullet":
		return _spawn_bullet_scene(data.token, data.pos, data.rot, data.speed, data.time, data.damage)
	return null

func _spawn_bullet_scene(player_token: String, _pos: Vector2, _rot:float, _speed:float, _time:float, _dmg:float) -> Node:
	var bullet := preload("res://scenes/entities/bullet.tscn").instantiate()
	bullet.global_position = _pos
	bullet.rotation = _rot
	bullet.bullet_speed = _speed
	bullet.bullet_life = _time
	if multiplayer.is_server():
		bullet.b_owner = PlayerManager.get_player_node(player_token)
	return bullet

func spawn_player(player_token: String):
	if active_players.has(player_token):
		return
	var data:= {"type_key": 'Player', "token": player_token}
	spawner.spawn(data)  # Type + data

func spawn_bullet(player_token:String,  _pos: Vector2, _rot, _speed:float, _time:float, _dmg:float):
	var data := {"type_key": 'Bullet',
				"token": player_token,
				"pos": _pos,
				"rot": _rot,
				"speed": _speed,
				"time": _time,
				"damage": _dmg
				}
	spawner.spawn(data)

func _spawn_player_scene(token: String) -> Node:
	var player = preload("res://scenes/player/player.tscn").instantiate()
	player.token = token

	var peer_id = PlayerManager.get_peer_id(token)
	player.name = str(peer_id)
	
	if multiplayer.is_server() :
		player.global_position = PlayerManager.get_position(token)
		PlayerManager.set_player_node(token, player)
		active_players[token] = player
	
	if PlayerProfile.token == token:
		local_player = player
		player.is_local = true
		
		#TEST make a seperate function for this.
		var chunk_manager :ChunkManagerMP= get_node_or_null( "/root/Main/SceneRoot/World/ChunkManager")
		if chunk_manager :
			chunk_manager.player_ref = local_player
	# We dont need to manually set where to spawn them because spawner handles it base where we set the spawn path
	# We already have path so it's okay
	return player


func despawn_player(player_token: String):
	print("despawn player requested: ", player_token)
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
	player_container = node
	spawner.spawn_path = player_container.get_path()

func save_world():
	if current_world_path.is_empty():
		push_error("❌ No world path to save to")
		return

	print("💾 Saving world to: ", current_world_path)

	WorldManager.save_data(current_world_path)
	PlayerManager.save_data(current_world_path)
	InventoryManager.save_data(current_world_path)
	#StorageManager.save_data(current_world_path)

	# Save meta if needed
	var meta = {
		"last_saved": Time.get_datetime_string_from_system()
	}
	SaveHelper.save_json(current_world_path.path_join("meta.json"), meta)

	print("✅ World save complete \n")

func pause_game():
	if MultiplayerManager.is_host():
		get_tree().paused = true
	
	GameUI.show_pause_menu()
	GameUI.hide_controls()
	

func resume_game():
	if MultiplayerManager.is_host():
		get_tree().paused = false
	GameUI.hide_pause_menu()
	GameUI.show_controls()
	

func reset_session():
	if MultiplayerManager.is_host():
		get_tree().paused = false
	
	MultiplayerManager.reset_manager()
	
	var game_world = get_node_or_null("/root/Main/SceneRoot/World")
	if game_world != null:
		game_world.queue_free()

	current_world_node = null
	current_world_path = ""
	local_player = null
	active_players = {}
	
	await get_tree().process_frame
	PlayerManager.reset_manager()
	InventoryManager.reset_manager()
	WorldManager.reset_manager()
	AudioManager.reset_manager()
	
	GameUI.reset_ui()

	var menu = MAIN_MENU.instantiate()
	var menu_margins := get_node("/root/Main/SceneRoot/MenuMargins")
	menu_margins.add_child(menu)
	on_session = false
	pass


func create_world(world_name):
	var path = "user://worlds/%s" % world_name
	DirAccess.make_dir_recursive_absolute(path)
	
	var _map_gen := preload("res://scenes/ChunkSystem/map_generator.tscn").instantiate()
	var world_data = _map_gen.generate_map(world_name)
	var world_dict = {
		"world_name": world_name,
		"map_size": world_data.map_size,
		"tile_size": world_data.tile_size,
		"chunk_size": world_data.chunk_size,
		"chunks": world_data.chunks,
		"seed": world_data.seed,
		"time" : WorldManager.time_manager.get_default_data()
	}
	var player_dict := {}
	var inventory_dict := {}
	
	var local_player :Dictionary= PlayerManager.create_local_player()
	player_dict[local_player.token] = local_player.player_dict
	
	inventory_dict[local_player.token] = InventoryManager.get_inventory_base()
	var item :ItemEquipment= ItemDatabase.get_spawn_item("bag_mountainbp")
	item.slots[1] = ItemDatabase.get_spawn_item("food_rice", 2)
	item.slots[0] = ItemDatabase.get_spawn_item("head_motohelmet")
	item.slots[3] = ItemDatabase.get_spawn_item("gun_akm")
	item.slots[5] = ItemDatabase.get_spawn_item("melee_axe")
	item.slots[4] = ItemDatabase.get_spawn_item("vest_swat")
	item.slots[8] = ItemDatabase.get_spawn_item("set_farmer")
	item.slots[9] = ItemDatabase.get_spawn_item("gun_remington")
	item.slots[10] = ItemDatabase.get_spawn_item("gun_izh")
	item.slots[11] = ItemDatabase.get_spawn_item("ammo_12g", 999)
	item.slots[12] = ItemDatabase.get_spawn_item("ammo_7.62", 999)
	item.slots[13] = ItemDatabase.get_spawn_item("melee_huntingknife")
	
	inventory_dict[local_player.token].bag = item.to_dict()
	
	SaveHelper.save_dict_to_file(world_dict, path.path_join("world.bin"))
	SaveHelper.save_json(path.path_join("players.json"), player_dict)   # Empty players
	SaveHelper.save_json(path.path_join("inventory.json"), inventory_dict)  # Empty storages
	SaveHelper.save_json(path.path_join("meta.json"), {
		"created_at": Time.get_datetime_string_from_system(),
		"seed": world_data.seed
	})
	
	_map_gen.queue_free()
	print("💾 saved!")
