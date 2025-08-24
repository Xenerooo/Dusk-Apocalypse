extends Node

var player :CharacterBody2D
var move_vector:= Vector2.ZERO
@export var SPEED := 12000.0
#
#func _ready() -> void:
	#set_physics_process(false)
	#else:
		#set_physics_process(false)

func _physics_process(delta: float) -> void:
	if multiplayer.is_server():
		player.velocity = player.get_input() * player.SPEED * delta
		player.move_and_slide()
