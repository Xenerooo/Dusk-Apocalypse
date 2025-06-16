# Zombie.gd
extends CharacterBody2D

var speed := 60.0
var horde = null

func _process(delta):
	if not horde:
		wander(delta)

func follow_horde(dir: Vector2, delta):
	var adjusted_dir = dir.normalized().rotated(randf_range(-0.1, 0.1))
	velocity = adjusted_dir * speed
	move_and_slide()

func wander(delta):
	# Basic wandering behavior when not in horde
	velocity = Vector2.RIGHT.rotated(randf()) * 20.0
	move_and_slide()
