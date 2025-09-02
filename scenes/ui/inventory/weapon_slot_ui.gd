extends "res://scenes/ui/inventory/slot_ui.gd"

@onready var ammo: Label = $HBoxContainer/ammo
@onready var durability: Label = $HBoxContainer/durability


func set_item_on_slot(item:Dictionary):
	item_id = item.get("itemid", "")
	item_data = item
	var _item_data :Dictionary= ItemDatabase.get_data(item_id)
	var item_durability :int = item.get("item_stats", {}).get("durability", 0)
	
	match _item_data.item_type :
		"weapon":
			var exist := ResourceLoader.exists(_item_data.preview_path)
			var item_ammo :int = item.get("item_stats", {}).get("ammo", 0)
			icon.texture = load(_item_data.preview_path) if exist else load("res://icon.svg")
			ammo.text = str("%s/%s" % [item_ammo, _item_data.max_ammo]) if _item_data.weapon_type == "gun" else ""
		"equipment":
			var exist := ResourceLoader.exists(_item_data.icon_path)
			icon.texture = load(_item_data.icon_path) if exist else load("res://icon.svg")

	
	#durability.text = str(((item_durability / _item_data.max_durability) * 100), "%")
	durability.text = str("%.1f" % ((item_durability / _item_data.max_durability) * 100), "%")

	

func set_slot_empty():
	item_id = ""
	item_data = {}
	icon.texture = null
	ammo.text = ""
	#amount_panel.hide()
	durability.text = ""
