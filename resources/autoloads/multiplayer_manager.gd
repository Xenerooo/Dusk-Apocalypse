#MultiplayerManager
extends Node

var port := 7777  # You can make this configurable if needed

func start_host():

	var peer := ENetMultiplayerPeer.new()
	var error := peer.create_server(port, 10)
	if error != OK:
		push_error("Failed to start host server: %s" % error)
		return

	multiplayer.multiplayer_peer = peer

	var profile = PlayerProfile
	MultiplayerManager.register_host_identity(
		profile._name,
		profile.token,
		profile.secret
	)
	
	print("✅ Host server started on port %d" % port)

func join_game(ip: String = "127.0.0.1"):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, 7777)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	
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
	

func _on_failed():
	print("Connection failed.")

func _ready():
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)
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

func is_host() -> bool:
	return multiplayer.is_server()

func network_is_connected() -> bool:
	return multiplayer.multiplayer_peer != null
