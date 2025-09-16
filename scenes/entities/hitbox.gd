extends Area2D
class_name Hitbox

#Attack Box/Damage Box

@onready var body := get_parent()

func receive_damage(damage):
	body.receive_damage(damage)

func disable_collision():
	set_collision_layer_value(32, false)
