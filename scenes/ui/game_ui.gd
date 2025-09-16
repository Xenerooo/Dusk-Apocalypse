extends CanvasLayer

const GUI_BTN_SWITCH_SHEET_0 = preload("res://asset/user_interface/gui_btn_switch-sheet0.png")
const GUI_BTN_SWITCH_SHEET_1 = preload("res://asset/user_interface/gui_btn_switch-sheet1.png")
const GUI_BTN_SWITCH_SHEET_2 = preload("res://asset/user_interface/gui_btn_switch-sheet2.png")

@export var player_controls : Control
@export var pause_menu: Control
@export var inventory_control : Control
@onready var status: Control = $AutoMargin/Status

@onready var right_container: GridContainer = $AutoMargin/PlayerControls/RightContainer

func _ready() -> void:
	pause_menu.hide()
	player_controls.hide()
	status.hide()
	print(name, " initialized")

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
	status.show()
func hide_controls():
	player_controls.hide()
	status.hide()

@rpc("authority", "call_local")
func update_local_inventory(inv:Dictionary):
	inventory_control.sync_inventory(inv)
	#print("%s local: data received" % multiplayer.get_unique_id())
	
@rpc("authority", "call_local")
func update_local_swap_btn(_index:int):
	update_button(_index)

@rpc("authority", "call_local")
func update_local_sneak_btn(_index:bool):
	right_container.update_sneak_btn(_index)

func reset_ui():
	inventory_control.hide()
	hide_controls()
	hide_pause_menu()
	pass

func update_button(_index : int):
	right_container.update_container(_index)
