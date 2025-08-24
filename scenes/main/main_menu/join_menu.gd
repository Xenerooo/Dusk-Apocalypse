extends Control
@export var ip_edit: LineEdit

func _ready() -> void:
	MultiplayerManager.join_timeout.connect(connection_timeout_prompt)

func _on_join_button_pressed() -> void:
	if MultiplayerManager.join_game(ip_edit.text) == true:
		join_prompt()

func _on_back_button_pressed() -> void:
	hide()

func join_prompt():
	$MarginContainer/VBoxContainer.hide()
	$MarginContainer/JoinPrompt.show()

func connection_timeout_prompt():
	$MarginContainer/JoinPrompt/Label.text = "Connection Timeout"
	

func _on_button_pressed() -> void:
	$MarginContainer/JoinPrompt/Label.text = "Connecting please wait"
	MultiplayerManager.cancel_join()
	$MarginContainer/JoinPrompt.hide()
	$MarginContainer/VBoxContainer.show()
