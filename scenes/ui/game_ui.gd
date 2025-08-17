extends CanvasLayer

@export var player_controls : Control
@export var pause_menu: Control

func _ready() -> void:
	pause_menu.hide()
	player_controls.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameSession.pause_game()
	if event.is_action_pressed("resume"):
		GameSession.resume_game()

func show_pause_menu():
	pause_menu.show()
	print("pause shown")

func hide_pause_menu():
	pause_menu.hide()
	print("pause hidden")
	

func show_controls():
	player_controls.show()
	print("contols shown")
	

func hide_controls():
	player_controls.hide()
	print("contols hidden")


func pause_game():
	pass

func resume_game():
	pass
