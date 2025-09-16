extends Resource
class_name Player

var name :String
var peer_id : int
var secret: String
var inventory := {}
var position :Vector2 = Vector2.ZERO
var facing_vector : Vector2 = Vector2.ZERO
var health := 100.0
var scene : PlayerCharacter = null
var weapon_index:= 0
var sneaking := false

func setup( _name:String, 
			_peer_id:int, 
			_secret:String, 
			_position := Vector2.ZERO, 
			_health := 100.0, 
			_scene: PlayerCharacter = null,
			_weapon_index:int = 0,
			_facing_vector:Vector2 = Vector2.ZERO,
			_sneaking:= false):
				
	name = _name
	peer_id = _peer_id
	secret = _secret
	position = _position
	health = _health
	scene = _scene
	weapon_index = _weapon_index
	facing_vector = _facing_vector
	sneaking = _sneaking

func to_dictionary()-> Dictionary:
	var dict := {
			"name": name,
			"secret": secret,
			"inventory": inventory,
			"position": { "x" : position.x, "y" : position.y },
			"face_position": { "x" : facing_vector.x, "y" : facing_vector.y },
			"health": health,
			"weapon_index" : weapon_index,
			"sneaking" : sneaking,
	}
	
	if scene :
		var latest_pos:= { "x" : scene.position.x, "y" : scene.position.y }
		dict["position"] = latest_pos
		dict["face_position"] = { "x" : scene.get_last_aim_input().x, "y" : scene.get_last_aim_input().y }
		dict["sneaking"] = scene.sneaking
	
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
