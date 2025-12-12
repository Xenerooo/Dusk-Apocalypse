extends MultiplayerSynchronizer
var player :PlayerCharacter

@export var local_move_input :Vector2 
@export var local_aim_input :Vector2 
@export var local_aim_held : bool = false
@export var local_is_firing : bool = false
var last_aim_input : Vector2

func _ready() -> void:
	call_deferred("local_setup")

func local_setup():
	if !is_multiplayer_authority():
		return
	GameUI.player_controls.aim_stick.pressed.connect(
		func(state:bool):
		local_aim_held = state
		player.request_toggle_aiming.rpc_id(1, state)
		)

func _input(event: InputEvent) -> void:
	if !is_multiplayer_authority():
		return

	if event.is_action_pressed("swap_weapon"):
		player.swap_weapon()
	if event.is_action_pressed("reload_weapon"):
		player.try_reload()
	if event.is_action_pressed("joystick_fire"):
		local_is_firing = true
	if event.is_action_released("joystick_fire"):
		local_is_firing = false
	if event.is_action_released("switch_weapon_mode"):
		player.request_switch_mode.rpc_id(1)
	if event.is_action_pressed("toggle_sneak"):
		player.request_toggle_sneak.rpc_id(1)
	
func _physics_process(delta: float) -> void:
	if player and is_multiplayer_authority():
		var dir :Vector2= GameUI.player_controls.move_stick.output
		local_move_input = dir
	if player and is_multiplayer_authority():
		var dir :Vector2= GameUI.player_controls.aim_stick.output
		local_aim_input = dir
	if local_aim_input != Vector2.ZERO:
		last_aim_input = local_aim_input
