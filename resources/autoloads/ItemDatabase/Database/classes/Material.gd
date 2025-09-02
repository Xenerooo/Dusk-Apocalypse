extends Item
class_name ItemMaterial

func set_data(data : Dictionary):
	
	itemid = data.itemid
	name = data.name
	is_stackable = data.is_stackable
	max_amount = data.max_amount
	description = data.description
	
	if data.icon_path != "" :
		icon = load(data.icon_path)

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
