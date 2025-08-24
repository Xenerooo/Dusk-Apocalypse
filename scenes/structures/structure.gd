extends Node2D

@onready var exterior: Sprite2D = $Exterior


func _on_player_detector_body_entered(body: Node2D) -> void:
	if body.is_local:
		exterior.hide()
	body.is_inside_structure = true

func _on_player_detector_body_exited(body: Node2D) -> void:
	if body.is_local:
		exterior.show()
	body.is_inside_structure = false
