extends CanvasLayer

@export var player_controls : Control
@export var pause_menu: Control
@export var inventory_control : Control
func _ready() -> void:
	pause_menu.hide()
	player_controls.hide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		GameSession.pause_game()
	if event.is_action_pressed("resume"):
		GameSession.resume_game()
	if event.is_action_pressed("open_inventory"):
		inventory_control.open_inventory()

func show_pause_menu():
	pause_menu.show()

func hide_pause_menu():
	pause_menu.hide()

func show_controls():
	player_controls.show()

func hide_controls():
	player_controls.hide()

func pause_game():
	pass

func resume_game():
	pass

func set_inventory_root():
	pass

@rpc("authority", "call_local")
func update_local_inventory(inv:Dictionary):
	inventory_control.sync_inventory(inv)
