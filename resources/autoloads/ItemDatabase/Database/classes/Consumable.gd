extends Item
class_name ItemConsumable

@export_range(-100, 100 ) var hp := 0
@export_range(-100, 100 ) var hunger := 0
@export_range(-100, 100 ) var thirst := 0
@export var consume_time := 0.0
@export var consume_audio := ""

func _init() -> void:
	item_type = ItemTypes.consumable

func set_data(data : Dictionary):
	itemid = data.itemid
	name = data.name
	is_stackable = data.is_stackable
	max_amount = data.max_amount
	description = data.description
	consume_time = data.consume_time
	consume_audio = data.consume_audio
	
	if data.icon_path != "" :
		icon = load(data.icon_path)

	hp = data.hp
	hunger = data.hunger
	thirst = data.thirst
	
	if data.has("item_stats") :
		amount = data.item_stats.amount

func to_dict() -> Dictionary :
	var data := {
		"itemid" : itemid,
		"item_stats" : {
			"amount" : amount
		}
	}
	return data
