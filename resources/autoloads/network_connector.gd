extends CanvasLayer

signal connected_to_host

@export var ip_address : LineEdit

func host_game():
	var peer = ENetMultiplayerPeer.new()
	peer.create_server(7777, 10)
	multiplayer.multiplayer_peer = peer
	print("Server started as host")

	#var profile = PlayerProfile
	#MultiplayerManager.rpc_id(1, "register_player_identity",
		#profile.name, profile.token, profile.secret)
	# Register yourself immediately
	var profile = PlayerProfile
	MultiplayerManager.register_host_identity(
		profile.name,
		profile.token,
		profile.secret
	)

	emit_signal("connected_to_host")

func join_game(ip: String = "127.0.0.1"):
	var peer = ENetMultiplayerPeer.new()
	peer.create_client(ip, 7777)
	multiplayer.multiplayer_peer = peer

	multiplayer.connected_to_server.connect(_on_connected)
	multiplayer.connection_failed.connect(_on_failed)
	
func _on_connected():
	var profile = PlayerProfile
	MultiplayerManager.rpc_id(1, "register_player_identity",
		profile.name, profile.token, profile.secret)

	emit_signal("connected_to_host")

func _on_failed():
	print("Connection failed.")


func _on_host_pressed() -> void:
	host_game()
	hide()

func _on_join_pressed() -> void:
	join_game(ip_address.text)
	hide()
