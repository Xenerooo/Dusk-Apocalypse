extends Resource
class_name Player

var name :String
var peer_id : int
var secret: String
var inventory := []
var position :Vector2 = Vector2.ZERO
var health := 100.0
var scene : PlayerCharacter = null

func setup( _name:String, 
			_peer_id:int, 
			_secret:String, 
			_position := Vector2.ZERO, 
			_inventory := [], 
			_health := 100.0, 
			_scene: PlayerCharacter = null):
				
	name = _name
	peer_id = _peer_id
	secret = _secret
	position = _position
	inventory = _inventory
	health = _health
	scene = _scene

func to_dictionary()-> Dictionary:
	var dict := {
			"name": name,
			"secret": secret,
			"inventory": inventory,
			"position": { "x" : position.x, "y" : position.y },
			"health": health
	}
	
	if scene :
		var latest_pos:= { "x" : scene.position.x, "y" : scene.position.y }
		dict["position"] = latest_pos
	
	return dict

		#players[token] = {
			#"name": _name,
			#"peer_id": peer_id,
			#"secret": secret,
			#"inventory": [],
			#"position": Vector2.ZERO,
			#"health": 100,
			#"scene": null
		#}
