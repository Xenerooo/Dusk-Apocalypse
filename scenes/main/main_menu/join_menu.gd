extends Control
@export var ip_edit: LineEdit


func _on_join_button_pressed() -> void:
	MultiplayerManager.join_game(ip_edit.text)

func _on_back_button_pressed() -> void:
	hide()
