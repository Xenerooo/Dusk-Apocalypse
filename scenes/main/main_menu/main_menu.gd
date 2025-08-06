extends Control
@onready var world_selector: Control = $WorldSelector
@onready var join_button: Button = $MainButtons/JoinButton
@onready var join_menu: Control = $joinMenu


func _on_play_button_pressed() -> void:
	world_selector.show()


func _on_join_button_pressed() -> void:
	join_menu.show()
