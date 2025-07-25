extends CharacterBody2D

@export var speed := 12000.0

func _physics_process(delta: float) -> void:
	var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()
	if dir:
		velocity = dir * speed * delta
	else:
		velocity.x = move_toward(velocity.x, 0,600)
		velocity.y = move_toward(velocity.y, 0,600)
	
	move_and_slide()
