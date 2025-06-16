#Horde.gd
class_name Horde
extends Node2D
const ZOMBIE = preload("res://zombie.tscn")
var direction := Vector2.RIGHT
var target_position: Vector2 
var speed := 0.0
var zombies := []
var wander_timer := 0.0

func _spawn_zombies(to) -> void:
	for i in 3 :
		var z := ZOMBIE.instantiate()
		zombies.append(z)
		to.add_child(z)
		z.horde = self

func update_direction():
	if target_position:
		direction = (target_position - global_position).normalized()
	else:
		wander_timer += get_process_delta_time()
		if wander_timer > 3.0:
			direction = direction.rotated(randf_range(-0.5, 0.5))
			wander_timer = 0.0

func move_virtual(delta):
	global_position += direction.normalized() * speed * delta
	# Move each zombie relative to the horde
	for z in zombies:
		z.follow_horde(direction, delta)

func add_zombie(zombie):
	zombies.append(zombie)
	zombie.horde = self
