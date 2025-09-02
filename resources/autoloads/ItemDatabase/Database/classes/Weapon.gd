extends Item
class_name ItemWeapon

enum WeaponTypes {gun, melee}
@export var weapon_type :WeaponTypes= WeaponTypes.gun
@export_range (0, 9999999) var damage = 0
@export_range (0, 9999999) var use_interval :float= 0.0
@export_range (0, 9999999) var crit_rate = 0
@export var preview_icon : Texture2D 
@export var sprite_path :String
@export var back_sprite_path :String
@export var max_durability := 0
var durability : = 0


func _init() -> void:
	item_type = ItemTypes.weapon
	

func set_data(data):
	back_sprite_path = data.back_sprite_path
	#itemid = data.itemid
	#name = data.name
	#is_stackable = data.is_stackable
	#max_amount = data.max_amount
	#description = data.description
	#max_durability = data.max_durability
	#
	##item_type = str_to_var(data.item_type)
	##weapon_type = str_to_var(data.weapon_type)
	#damage = data.damage
	#use_interval = use_interval
	#crit_rate = data.crit_rate
#
#
	#if data.has("item_stats") :
		#var stats :Dictionary= data.item_stats
		#if stats.has("durability") :
			#durability = stats.durability

func to_dict() -> Dictionary :
	var data := {
		"itemid" : itemid,
		"item_stats" : {
			"durability" : durability
		}
	}
	return data
