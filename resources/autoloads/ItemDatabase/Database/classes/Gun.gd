extends ItemWeapon
class_name ItemGun

enum shootTypes {single, scatter, burst}
enum FireMode { AUTO, SEMI }

var shoot_type : shootTypes = shootTypes.single
var fire_mode : FireMode = FireMode.AUTO

@export var bullet_count : = 1
@export var bullet_speed := 0.0
@export var bullet_time := 0.0
@export_range ( 0, 9999999) var reload_time = 0
@export_range ( 0, 9999999) var min_acc = 0
@export_range ( 0, 9999999) var max_acc = 0
@export_range ( 0, 9999999) var recoil = 0
@export var ammo_id = ""
@export var can_attach := false
@export var max_ammo := 0
@export var aim_recovery := 0.0
@export var run_penalty := 0.0

var ammo : = 0
var current_recoil: float = 0.0

func _init() -> void:
	item_type = ItemTypes.weapon
	weapon_type = WeaponTypes.gun

func set_data(data):
	super(data)
	itemid = data.itemid
	name = data.name
	is_stackable = data.is_stackable
	max_amount = data.max_amount
	description = data.description
	max_durability = data.max_durability
	sprite_path = data.sprite_path
	shoot_type = shootTypes[data.shoot_type]
	bullet_speed = data.bullet_speed
	bullet_time = data.bullet_life
	
	#item_type = str_to_var(data.item_type)
	#weapon_type = str_to_var(data.weapon_type)
	damage = data.damage
	use_interval = data.use_interval
	crit_rate = data.crit_rate
	reload_time = data.reload_time
	min_acc = data.min_acc
	max_acc = data.max_acc
	recoil = data.recoil
	bullet_count = data.bullet_count
	ammo_id = data.ammo_id
	max_ammo = data.max_ammo
	run_penalty = data.run_penalty
	aim_recovery = data.aim_recovery
	
	can_attach = data.can_attach

	if data.icon_path != "" :
		icon = load(data.icon_path)
	if data.preview_path != "" :
		preview_icon = load(data.preview_path)
	
	if data.has("item_stats") :
		var stats :Dictionary= data.item_stats
		if stats.has("durability") :
			durability = stats.durability
		if stats.has("ammo") :
			ammo = stats.ammo
		if stats.has("mode") :
			fire_mode = stats.mode
		if stats.has("current_recoil") :
			current_recoil = stats.current_recoil


func get_ammo_needed() -> int:
	return max_ammo - ammo

func to_dict() -> Dictionary :
	var data := {
		"itemid" : itemid,
		"item_stats" : {
			"durability" : durability,
			"ammo" : ammo,
			"mode":  fire_mode,
			"current_recoil": current_recoil
		}
	}
	return data
