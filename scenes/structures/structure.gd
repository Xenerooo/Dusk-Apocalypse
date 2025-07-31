extends Node2D

@onready var exterior: Sprite2D = $Exterior


func _on_player_detector_body_entered(body: Node2D) -> void:
	exterior.hide()

func _on_player_detector_body_exited(body: Node2D) -> void:
	exterior.show()
