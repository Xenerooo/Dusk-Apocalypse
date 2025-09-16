extends Node

var player :PlayerCharacter
var move_vector:= Vector2.ZERO
@export var SPEED := 12000.0
@export var SNEAK_SPEED:= 6000.0
#
#func _ready() -> void:
	#set_physics_process(false)
	#else:
		#set_physics_process(false)


func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		if player.can_move():
			player.velocity = player.get_input() * (SPEED if !player.sneaking else  SNEAK_SPEED) * delta
		else :
			player.velocity = Vector2.ZERO
		player.move_and_slide()
