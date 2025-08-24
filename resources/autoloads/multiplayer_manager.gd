#MultiplayerManager
extends Node

signal join_timeout

var port := 7777  # You can make this configurable if needed
var ClientPeer: MultiplayerPeer
var timer: Timer

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		#print(multiplayer.is_server())
		#print(multiplayer.get_unique_id())
		#reset_manager()
		print(multiplayer.has_multiplayer_peer())

func start_host():
	timer.stop()
	reset_manager()
	
	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 10)
	if error != OK:
		push_error("Failed to start host server: %s" % error)
		return

	multiplayer.multiplayer_peer = peer
	ClientPeer = multiplayer.multiplayer_peer
	
	var profile = PlayerProfile
	MultiplayerManager.register_host_identity(
		profile._name,
		profile.token,
		profile.secret
	)
	
	print("✅ Host server started on port %d \n" % port)

func join_game(ip: String = "127.0.0.1") -> bool:
	var peer = ENetMultiplayerPeer.new()
	if peer.create_client(ip, 7777) == OK:
	
		multiplayer.multiplayer_peer = peer
		ClientPeer = multiplayer.multiplayer_peer
		timer.start(10.0)
		return true
	return false

func cancel_join():
	reset_manager()
	timer.stop()

@rpc("any_peer")
func request_world_setup():
	var peer_id := multiplayer.get_remote_sender_id()
	
	var seed := WorldManager.seed
	WorldManager.setup_world.rpc_id(peer_id, seed)
	

func _on_connected():
	var profile = PlayerProfile
	MultiplayerManager.rpc_id(1, "register_player_identity",
		profile._name, profile.token, profile.secret)
	
	GameSession.join_world()
	timer.stop()
	

func _on_failed():
	print("Connection failed.")

func _ready():
	timer = Timer.new()
	add_child( timer)
	timer.autostart = false
	timer.one_shot = true
	timer.timeout.connect(on_join_timeout)
	
	ClientPeer = multiplayer.multiplayer_peer
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	print("MultiplayerManager initialized")

@rpc("any_peer")
func register_player_identity(display_name: String, player_token: String, player_secret: String):
	var peer_id := multiplayer.get_remote_sender_id()
	print("🛜 Incoming player registration: %s, token: %s, peer id: %s" %[display_name, player_token, peer_id])
	
	if PlayerManager.has_token(player_token):
		if not PlayerManager.validate_token(player_token, player_secret):
			print("🛜 Invalid identity for: ", display_name)
			multiplayer.disconnect_peer(peer_id)
			return
	else:
		print("🛜 New Player, accepting and registing %s" % [display_name])

	PlayerManager.add_or_update_player(player_token, display_name, peer_id, player_secret)
	GameSession.spawn_player(player_token)

func register_host_identity(display_name: String, player_token: String, player_secret: String):
	print("🛜 Incoming player registration: %s, token: %s" %[display_name, player_token])
	
	if PlayerManager.has_token(player_token):
		if not PlayerManager.validate_token(player_token, player_secret):
			print("🛜 Invalid identity for: ", display_name)
			return
	else:
		print("🛜 New Player, accepting and registing %s" % [display_name])

	PlayerManager.add_or_update_player(player_token, display_name, 1, player_secret)
	GameSession.spawn_player(player_token)

func _on_peer_disconnected(peer_id: int):
	var token := PlayerManager.get_token_by_peer(peer_id)
	if token == "":
		return

	PlayerManager.update_persistent_data_from_scene(token)
	PlayerManager.set_peer_id(token, 0)
	GameSession.despawn_player(token)

func _on_server_disconnected():
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	GameSession.reset_session()

func is_host() -> bool:
	return multiplayer.is_server()

func network_is_connected() -> bool:
	return multiplayer.multiplayer_peer != null

func reset_manager():
	
	if multiplayer.is_server():
		for peer_id in multiplayer.get_peers():
			multiplayer.multiplayer_peer.disconnect_peer(peer_id)
	
	multiplayer.multiplayer_peer.close()
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	
	ClientPeer = multiplayer.multiplayer_peer

	print("multiplayer manager: reset")

func on_join_timeout():
	cancel_join()
	emit_signal("join_timeout")
