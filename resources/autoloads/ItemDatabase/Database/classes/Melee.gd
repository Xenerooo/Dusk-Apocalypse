extends ItemWeapon
class_name ItemMelee

@export var swing := false

func _init() -> void:
	item_type = ItemTypes.weapon
	weapon_type = WeaponTypes.melee

func set_data(data):
	super(data)
	itemid = data.itemid
	name = data.name
	is_stackable = data.is_stackable
	max_amount = data.max_amount
	description = data.description
	max_durability = data.max_durability
	sprite_path = data.sprite_path
	
	if data.icon_path != "" :
		icon = load(data.icon_path)
	if data.preview_path != "" :
		preview_icon = load(data.preview_path)
	#item_type = str_to_var(data.item_type)
	#weapon_type = str_to_var(data.weapon_type)
	damage = data.damage
	use_interval = data.use_interval
	crit_rate = data.crit_rate

	if data.has("item_stats") :
		var stats :Dictionary= data.item_stats
		if stats.has("durability") :
			durability = stats.durability

func to_dict() -> Dictionary :
	var data := {
		"itemid" : itemid,
		"item_stats" : {
			"durability" : durability
		}
	}
	return data
