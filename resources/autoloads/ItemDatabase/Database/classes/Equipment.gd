extends Item
class_name ItemEquipment

enum EquipmentTypes {head, body, vest, bag}
@export var equipment_type :EquipmentTypes= EquipmentTypes.head
@export_range ( 0, 9999999) var armor = 0
@export_range ( 0, 9999999) var warm = 0
@export_range ( 0, 9999999) var max_durability = 0
@export_range ( 0, 9999999) var max_slots = 0
@export var can_store_equipment :bool= false
@export var sprite_path : String

var durability : = 0
var slots := []

func _init() -> void:
	item_type = ItemTypes.equipment
	
func set_data(data : Dictionary):
	itemid = data.itemid
	name = data.name
	is_stackable = data.is_stackable
	max_amount = data.max_amount
	equipment_type = EquipmentTypes.get(data.equipment_type)
	armor = data.armor
	warm = data.warm
	max_durability = data.max_durability
	max_slots= data.max_slots
	can_store_equipment = data.can_store_equipment
	description = data.description
	sprite_path = data.sprite_path
	if DirAccess.dir_exists_absolute(data.icon_path):
		icon = load(data.icon_path)
	
	slots.resize(max_slots)
	
	if data.has("item_stats") :
		var stats :Dictionary= data.item_stats
		if stats.has("durability") :
			durability = stats.durability

		if stats.has("slots") :
			var data_slots:Array = stats["slots"]
			for s in data_slots.size() :
				if data_slots[s] != null :
					var item : Item = ItemDatabase.get_old_item(data_slots[s].itemid, (data_slots[s].item_stats))
					slots[s] = item
					#breakpoint
	#breakpoint

	
	
func to_dict() -> Dictionary :
	var data := {
		"itemid" : itemid,
		"item_stats" : {
			"durability" : durability,
			"slots" : []
		}
	}
	for i in max_slots : 
		data.item_stats.slots.append(null)
	
	for s in slots.size() :
		var item : Item = slots[s]
		if item == null : 
			data.item_stats.slots[s] = null
			continue
		data.item_stats.slots[s] = item.to_dict()
	
	return data
