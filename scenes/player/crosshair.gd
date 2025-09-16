extends Marker2D

@onready var root: Marker2D = $Root
@onready var muzzle_root: Marker2D = $MuzzleRoot

func rotate_aim(aim_vector: Vector2):
	#var rad := aim_vector.angle()
	root.rotation = aim_vector.angle()
	muzzle_root.rotation = aim_vector.angle()

@export var player : PlayerCharacter
@export var sens := 100.0
@export var gradient : GradientTexture1D

# Nodes
@export var aim_crosshair :Marker2D
@export var recoil_indicator: Line2D
@export var recoil_indicator_2: Line2D 
@export var muzzle: Marker2D 

var trigger_held := false
# Recoil state
var circle_radius :Vector2
var current_recoil := 0.0
var target_recoil := 0.0
var gun_firing := false
var recoil_cooldown := 0.0
const recoil_recovery_speed := 8.0

func hide_indicator():
	muzzle_root.hide()

func show_indicator():
	muzzle_root.show()

func _ready() -> void:
	circle_radius = muzzle_root.position - muzzle.position

func _physics_process(delta: float) -> void:
	gun_firing = player.get_active_input()
	var gun: ItemWeapon = player.get_active_gun()

	# Update cooldown
	if recoil_cooldown > 0.0:
		recoil_cooldown -= delta
	
	var is_moving :bool= player.velocity.length() > 0.0

	# --- Recoil logic ---
	if gun is ItemGun:
		if (gun_firing and !player.is_busy()) and recoil_cooldown <= 0.0:
			if gun.ammo <= 0:
				recoil_cooldown = 1.0
				AudioManager.spawn_audio.rpc(AudioManager.EMPTY_CLICK, player.global_position, 4000, 10.5)
			else:
				# Check fire mode
				if gun.fire_mode == ItemGun.FireMode.AUTO:
					_shoot_and_apply_recoil(gun)
				elif gun.fire_mode == ItemGun.FireMode.SEMI:
					if not trigger_held: # Only fire once per press
						_shoot_and_apply_recoil(gun)
						trigger_held = true
		elif gun_firing == false:
			# Reset trigger when player releases input
			trigger_held = false

		if is_moving:
			var move_factor :float= clamp(player.velocity.length() / player.SPEED, 0.0, 1.0)
			var move_recoil :float= lerp(gun.min_acc, gun.max_acc, move_factor)
			#target_recoil = max(target_recoil, move_recoil * (1.0 + gun.run_penalty))
			#target_recoil = clamp(target_recoil - gun.aim_recovery, gun.min_acc, gun.max_acc )
			target_recoil = clamp(gun.current_recoil + gun.run_penalty, gun.min_acc, gun.max_acc)
		else:
			target_recoil = clamp(gun.current_recoil + gun.aim_recovery, gun.min_acc, gun.max_acc)

		# Smooth recoil
		gun.current_recoil = target_recoil

		# Update crosshair visuals
		_update_crosshair(gun.current_recoil,  gun.min_acc,gun.max_acc)

func _shoot_and_apply_recoil(gun: ItemGun):
	gun.current_recoil = clamp(gun.current_recoil + gun.recoil, gun.min_acc, gun.max_acc)
	recoil_cooldown = gun.use_interval
	_fire_gun(gun)

# ----------------------
# Crosshair visuals
# ----------------------
func _update_crosshair(spread: float, min_recoil:float,max_recoil: float) -> void:
	recoil_indicator.rotation_degrees = spread
	recoil_indicator_2.rotation_degrees = -spread

	if aim_crosshair.visible:
		#var gradient_pos := spread / max_recoil
		var gradient_pos :float= clamp((spread - min_recoil) / (max_recoil - min_recoil), 0.0, 1.0)
		
		var color := gradient.gradient.sample(gradient_pos)
		recoil_indicator.gradient.set_color(0, color)
		recoil_indicator_2.gradient.set_color(0, color)
		
		var base_scale := 1.0
		var extra_scale := 0.02 * spread
		aim_crosshair.scale = Vector2.ONE * (base_scale + extra_scale)

# ----------------------
# Shooting function
# ----------------------
func _fire_gun(gun: ItemGun) -> void:

	match gun.shoot_type:
		gun.shootTypes.single:
			_fire_single(gun)
		gun.shootTypes.scatter:
			_fire_scatter(gun)
		gun.shootTypes.burst:
			_fire_burst(gun)
	
	gun.ammo -= 1
	# Optional: spawn noise
	#if player.is_auth() and player.noise_cooldown.is_stopped():
		#GameManager.spawn_noise.rpc(global_position, 600.0)
		#player.noise_cooldown.start()

# ----------------------
# Implement shoot types
# ----------------------
func _fire_single(gun: ItemGun):
	#var direction = player.get_aim_input().rotated(deg_to_rad(randf_range(-current_recoil, current_recoil)))
	
	var vector = player.get_last_aim_input() ## BUG WHERE IF U AIM QUICK IT WILL SHOOT ACCURATE
	var recoil_degree_max = gun.max_acc
	var random_angle = gun.current_recoil
	var recoil_radians_actual = deg_to_rad(randf_range(-random_angle, random_angle))
	var actual_bullet_direction = vector.rotated(recoil_radians_actual)
	var recoil_increment = gun.recoil
	var _x := circle_radius.length() * cos(recoil_radians_actual)
	var _y := circle_radius.length() * sin(recoil_radians_actual)
	
	# Use the rotated direction with the node's global rotation
	var rotated_bullet_direction = vector.rotated(recoil_radians_actual)
	# Scale the rotated direction by the circle radius
	var scaled_bullet_direction = rotated_bullet_direction * circle_radius.length()
	var bullet_pos = (muzzle_root.global_position + scaled_bullet_direction)
	#var bullet_pos = ($MuzzleRoot.global_position + Vector2(_x, _y))
	#var bullet_pos = muzzle.global_position
	var dsx :Array= ItemDatabase.get_data(gun.itemid).sound_fx
	AudioManager.spawn_audio.rpc(dsx.pick_random(), player.global_position, 4000, 10.5)
	
	GameSession.spawn_bullet(player.token, bullet_pos, actual_bullet_direction.angle(), gun.bullet_speed, gun.bullet_time, gun.damage)


func _fire_scatter(gun: ItemGun):
	for i in gun.bullet_count:
		var vector = player.get_last_aim_input()
		var recoil_degree_max = gun.max_acc
		var random_angle = gun.current_recoil
		var recoil_radians_actual = deg_to_rad(randf_range(-random_angle, random_angle))
		var actual_bullet_direction = vector.rotated(recoil_radians_actual)
		var recoil_increment = gun.recoil
		
		var _x := circle_radius.length() * cos(recoil_radians_actual)
		var _y := circle_radius.length() * sin(recoil_radians_actual)
		
		# Use the rotated direction with the node's global rotation
		var rotated_bullet_direction = vector.rotated(recoil_radians_actual)
		# Scale the rotated direction by the circle radius
		var scaled_bullet_direction = rotated_bullet_direction * circle_radius.length()
		
		var bullet_pos = (muzzle_root.global_position + scaled_bullet_direction)
		#var bullet_pos = ($MuzzleRoot.global_position + Vector2(_x, _y))
		#var bullet_pos = muzzle.global_position
		
		GameSession.spawn_bullet(player.token, bullet_pos, actual_bullet_direction.angle(), gun.bullet_speed, gun.bullet_time, gun.damage)
	var dsx :Array=  ItemDatabase.get_data(gun.itemid).sound_fx
	AudioManager.spawn_audio.rpc(dsx.pick_random(), player.global_position, 4000, 10.5)
		#GameManager.spawn_bullet.rpc(bullet_pos, direction.angle(), gun.bullet_speed, gun.bullet_time, gun.damage, player)
	#GameManager.spawn_muzzle.rpc(muzzle.global_position, player.aim_direction.angle(), 0)

func _fire_burst(gun: ItemGun):
	for i in gun.bullet_count:
		await get_tree().create_timer(0.05 * i).timeout  # stagger shots
		var direction = player.get_aim_input().rotated(deg_to_rad(randf_range(-current_recoil, current_recoil)))
		var bullet_pos = muzzle.global_position
		#GameManager.spawn_bullet.rpc(bullet_pos, direction.angle(), gun.bullet_speed, gun.bullet_time, gun.damage, player)
	#GameManager.spawn_muzzle.rpc(muzzle.global_position, player.aim_direction.angle(), 0)
