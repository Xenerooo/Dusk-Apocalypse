extends Node2D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("cam_zoom"):
		get_viewport().get_camera_2d().zoom.x +=.1 
		get_viewport().get_camera_2d().zoom.y +=.1 
	if event.is_action_pressed("cam_zoom_out"):
		get_viewport().get_camera_2d().zoom.x -=.1 
		get_viewport().get_camera_2d().zoom.y -=.1 
