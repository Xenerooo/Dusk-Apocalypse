extends Node2D

@onready var exterior: Sprite2D = $Exterior
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D


func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_local:
		exterior.hide()
		phantom_camera_2d.priority = 30
		phantom_camera_2d.follow_target = body
	body.is_inside_structure = true

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_local:
		exterior.show()
		phantom_camera_2d.priority = 0
		phantom_camera_2d.follow_target = null
		
	body.is_inside_structure = false
