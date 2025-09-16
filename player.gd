extends CharacterBody2D
class_name PlayerCharacter

var token := ""
@export var SPEED := 12000.0

@onready var movement: Node = $Movement
@onready var label: Label = $Label
@onready var InputSync: MultiplayerSynchronizer = $InputSync
@onready var HostSsync: MultiplayerSynchronizer = $HostSync

var is_local := false
var is_inside_structure: =false

@export var lerp_speed := 10.0

@export var sync_position: = Vector2.ZERO
@export var sync_velocity:= Vector2.ZERO
@export var client_position := Vector2.ZERO

@export var animation_tree: AnimationTree
@export var state_machine: FiniteStateMachine
@export var audios: Node2D 

@onready var crosshair: Marker2D = $Crosshair
@onready var remote_transform_2d: RemoteTransform2D = $RemoteTransform2D
@onready var phantom_camera_2d: PhantomCamera2D = $PhantomCamera2D
@onready var action_manager: ActionManager = $ActionManager


var sneaking := false
var aiming := false
var active_weapon_index := 0  # 0 = melee, 1 = weapon1, 2 = weapon2


func _on_tree_entered() -> void:
	pass # Replace with function body.
	
func host_setup():
	await get_tree().process_frame
	if multiplayer.is_server():
		var weapon_index:int = PlayerManager.players[token].weapon_index
		confirm_swap_weapon.rpc_id(PlayerManager.get_peer_id(token), weapon_index)
		InputSync.last_aim_input = PlayerManager.players[token].facing_vector
		confirm_toggle_sneak.rpc(PlayerManager.players[token].sneaking)

func client_setup():
	InputSync.set_multiplayer_authority(int(name))
	InputSync.player = self
	phantom_camera_2d.priority = 20 if InputSync.is_multiplayer_authority() else 0
	action_manager.token = token
	movement.player = self
	request_player_name_setup.rpc_id(1)
	audios.set_as_current(is_local)
	if is_local:
		remote_transform_2d.remote_path = WorldManager.shadow.get_path()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("cam_zoom"):
		phantom_camera_2d.zoom.x = clamp(phantom_camera_2d.zoom.x+ .1, 0.1, 3.0)
		phantom_camera_2d.zoom.y = clamp(phantom_camera_2d.zoom.y+ .1, 0.1, 3.0)

	if event.is_action_pressed("cam_zoom_out"):
		phantom_camera_2d.zoom.x = clamp(phantom_camera_2d.zoom.x -.1, 0.1, 3.0)
		phantom_camera_2d.zoom.y = clamp(phantom_camera_2d.zoom.y - .1, 0.1, 3.0)

func _ready() -> void:
	host_setup()
	client_setup()

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		client_position = client_position.lerp(sync_position, lerp_speed * delta)
		global_position = client_position
		velocity = sync_velocity
	else:
		handle_server_process(delta)

func handle_server_process(delta :float) -> void:
	if get_aim_input() != Vector2.ZERO:
		request_aim(get_aim_input())
	if !is_busy():
		if get_active_input() == true:
			var weapon_data := InventoryManager.get_weapon_data(token, active_weapon_index)
			match weapon_data.type:
				"gun":
					pass
				"melee":
					var item : ItemMelee = weapon_data.item
					try_melee(item)
	sync_velocity = velocity
	sync_position = global_position

#@rpc("any_peer", "call_local")
func request_aim(aim_vector:Vector2):
	crosshair.rotate_aim(aim_vector)

func reset_melee_scale():
	animation_tree.set("parameters/TimeScale/scale", 1)

func is_busy() -> bool:
	return action_manager.busy()

func can_move()-> bool:
	return action_manager.lock_movement == false

func swap_weapon():
	request_swap_weapon.rpc_id(1)

func try_reload():
	request_reload_weapon.rpc_id(1)

func try_melee(item: ItemMelee):
	# don't start if already busy
	if is_busy():
		return
	
	var swing_time := .1
	if item != null:
		swing_time = item.use_interval
	# lock into melee action
	# you can tweak per-weapon later
	action_manager.start_action(ActionManager.ActionType.MELEE, swing_time, {}, true)
	set_melee_scale.rpc(swing_time)
	transition_to_attack.rpc()
	AudioManager.spawn_audio.rpc(AudioManager.punch.pick_random(), Vector2.ZERO, 2000, 10.5, self)

func get_active_gun() -> ItemWeapon:
	return InventoryManager.get_player_current_weapon(token, active_weapon_index)

func get_input()-> Vector2:
	return InputSync.local_move_input

func get_aim_input()-> Vector2:
	return InputSync.local_aim_input

func get_last_aim_input()-> Vector2:
	return InputSync.last_aim_input

func get_active_input()-> bool:
	return InputSync.local_is_firing and InputSync.local_aim_input !=Vector2.ZERO

func get_aim_state()-> bool :
	return InputSync.local_aim_held

func play_footstep():
	audios.footstep(self)


@rpc("authority", "call_local", "unreliable")
func set_melee_scale(time: float):
	animation_tree.set("parameters/TimeScale/scale", 0.6 / time)

@rpc("authority", "call_local", "unreliable")
func reset_animation():
	reset_melee_scale()
	travel_state("to_idle")

@rpc("any_peer", "call_local")
func request_swap_weapon():
	if action_manager.busy() :
		return
	InventoryManager.rpc_id(1, "request_swap_weapon", token)

@rpc("any_peer", "call_local")
func request_switch_mode():
	if action_manager.busy() :
		return
	var weapon :ItemWeapon= InventoryManager.get_player_current_weapon(token, active_weapon_index)
	if weapon is ItemGun :
		weapon.fire_mode = (weapon.fire_mode + 1) % 2
		AudioManager.spawn_audio.rpc(AudioManager.PICK_PISTOL, Vector2.ZERO, 4000, 10.5, self)

@rpc("any_peer", "call_local")
func request_reload_weapon():
	if action_manager.busy() :
		return

	var slot = active_weapon_index
	if not InventoryManager.can_reload(token, slot):
		print("No ammo available or already full")
		AudioManager.spawn_audio.rpc(AudioManager.PICK_PISTOL, Vector2.ZERO, 2000, 10.5, self)
		return
	
	var reload_time = InventoryManager.get_reload_time(token, slot)
	
	if action_manager.start_action(ActionManager.ActionType.RELOAD, reload_time, {"slot": slot}, false):
		var weapon : ItemWeapon = InventoryManager.get_player_current_weapon(token, slot)
		
		var dsx :String=  ItemDatabase.get_data(weapon.itemid).reload_sound
		if dsx.is_empty() :
			AudioManager.spawn_audio.rpc(AudioManager.RELOAD_PISTOL, Vector2.ZERO, 2000, 10.5, self)
		else:
			AudioManager.spawn_audio.rpc(dsx, Vector2.ZERO, 4000, 10.5, self)
		#travel_state.rpc("to_interact")

#func try_consume(slot: int):
	#var item = InventoryManager.get_item_at(PlayerProfile.token, "inventory", slot)
	#if item == null or item.type != "consumable": return
	#if action_lock.current_action != ActionLock.ActionType.NONE: return
#
	#action_lock.start_action(ActionLock.ActionType.CONSUME, item.consume_time, {"slot": slot})

@rpc("any_peer", "call_local")
func request_toggle_sneak():
	sneaking = !sneaking
	confirm_toggle_sneak.rpc(sneaking)
	GameUI.update_local_sneak_btn.rpc_id(PlayerManager.get_peer_id(token) ,sneaking)
	

@rpc("authority", "call_local", "unreliable")
func confirm_toggle_sneak(state:bool):
	sneaking = state

@rpc("any_peer", "call_local")
func request_toggle_aiming(state:bool):
	aiming = state
	confirm_toggle_aiming.rpc(aiming)

@rpc("authority", "call_local", "unreliable")
func confirm_toggle_aiming(state:bool):
	aiming = state

@rpc("authority", "call_local")
func confirm_swap_weapon(new_index: int):
	active_weapon_index = new_index
	match active_weapon_index:
		0:
			crosshair.hide_indicator()
		1,2 :
			crosshair.show_indicator()
	GameUI.update_local_swap_btn(new_index)


	# TODO: update visuals, animations, etc.

@rpc("any_peer", "call_local")
func request_player_name_setup():
	var peer_id:= multiplayer.get_remote_sender_id()
	setup_name.rpc_id(peer_id, PlayerManager.players[token].name) 

@rpc("authority", "call_local")
func setup_name(_name: String):
	label.text = _name

@rpc("authority", "call_local", "unreliable")
func transition_to_attack():
	state_machine.fire_event("to_melee")

@rpc("authority", "call_local", "unreliable")
func travel_state(state:String):
	state_machine.fire_event(state)

@rpc("authority", "call_local", "unreliable")
func update_animation(blend_dir : Vector2):
	animation_tree.set("parameters/Animation/idle/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/idle_aim/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/melee/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/run/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/run_aim/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/sneak/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/sneak_aim/blend_position", blend_dir)
	animation_tree.set("parameters/Animation/sneak_idle/blend_position", blend_dir)
	
