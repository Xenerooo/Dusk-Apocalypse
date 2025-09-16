extends CharacterBody2D

var damage : int = 0
var bullet_velocity := 0.0
var bullet_speed : = 20.0
var bullet_life : = 1.0
var b_owner : PlayerCharacter
var pierce := true

func _ready() -> void:
	#if multiplayer.is_server() :
	velocity = Vector2(bullet_speed, 0).rotated(rotation)
	
func _physics_process(delta: float) -> void:
	#if multiplayer.is_server() :
	bullet_life -= delta
	move_and_slide()
	if multiplayer.is_server():
		if bullet_life <= 0 : queue_free()
#	
func _on_area_2d_body_entered(body: Node2D) -> void:
	if multiplayer.is_server():
		if body is Hurtbox :
			body.receive_damage(damage)
		queue_free()

func _on_area_2d_area_entered(area: Area2D) -> void:
	if multiplayer.is_server():
		if pierce :
			if area is Hurtbox :
				if !area.body == b_owner:
					area.receive_damage(damage)
					pierce = false
					queue_free()
			else :
				pierce = false
				queue_free()


func _on_area_2d_area_exited(area: Area2D) -> void:
	pass # Replace with function body.
