#PlayerManager
extends Node

var players := {}              # token → player data
var peer_to_token := {}        # peer_id → token

func _ready():
	print("PlayerManager initialized")

func add_or_update_player(token: String, _name: String, peer_id: int, secret: String = ""):
	#print("🚶 Player: %s, Token: %s, peer id: %s" % [_name, token, peer_id])
	if not players.has(token):
		players[token] = {
			"name": _name,
			"peer_id": peer_id,
			"secret": secret,
			"inventory": [],
			"position": Vector2.ZERO,
			"health": 100,
			"scene": null
		}
	else:
		players[token].peer_id = peer_id
		players[token].name = _name
		if secret != "":
			players[token].secret = secret

	if peer_id > 0:
		peer_to_token[peer_id] = token

func set_node(token: String, node: Node):
	if players.has(token):
		players[token].scene = node

func get_player_node(token: String) -> Node:
	return players.get(token, {}).get("scene", null)

func set_peer_id(token: String, peer_id: int):
	if players.has(token):
		var old_peer :int= players[token].peer_id
		if old_peer != 0:
			peer_to_token.erase(old_peer)
		players[token].peer_id = peer_id
		if peer_id > 0:
			peer_to_token[peer_id] = token

func get_token_by_peer(peer_id: int) -> String:
	return peer_to_token.get(peer_id, "")

func get_peer_id(token: String) -> int:
	return players.get(token, {}).get("peer_id", 0)

func get_all_tokens()-> Array:
	return players.keys()

func update_persistent_data_from_scene(token: String):
	var node = get_player_node(token)
	if node == null:
		return
	#players[token].inventory = node.get_inventory_data()
	players[token].position = node.global_position
	#players[token].health = node.health
	set_node(token, null)

func validate_token(token: String, secret: String) -> bool:
	if not players.has(token):
		return false
	return players[token].secret == secret

func get_persistent_data_dict() -> Dictionary:
	var result := {}
	
	for token in players.keys():
		
		var p = players[token]
		result[token] = {
			"name": p.name,
			"secret": p.secret,
			"inventory": p.inventory,
			"position": { "x" :p["scene"].position.x, "y" :p["scene"].position.y },
			"health": p.health
		}
	return result



func has_token(token: String) -> bool:
	return players.has(token)

func get_position(token)-> Vector2:
	var player = players.get(token)
	return player.get("position", Vector2.ZERO)

func set_player_node(token: String, node: Node):
	if players.has(token):
		players[token]["scene"]=node



func save_data(path: String):
	var data = get_persistent_data_dict()
	SaveHelper.save_json(path.path_join("players.json"), data)

func load_data(data: Dictionary):
	for token in data.keys():
		var p = data[token]
		players[token] = {
			"name": p.get("name", ""),
			"peer_id": 0,  # Will be set when player joins
			"secret": p.get("secret", ""),
			"inventory": p.get("inventory", []),
			"position": Vector2(p.get("position", {}).get("x", 0), p.get("position", {}).get("y", 0)),
			"health": p.get("health", 100),
			"scene": null
		}
