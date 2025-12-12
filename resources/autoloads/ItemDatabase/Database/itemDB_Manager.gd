extends Node

enum ItemTypes {consumable, weapon, equipment, material}
enum WeaponTypes {gun, melee}
enum EquipmentTypes {HEAD, BODY, VEST, BAG}

var database := {}


func _ready() -> void:
	var file_access := FileAccess.open("res://resources/autoloads/ItemDatabase/ItemData.json", FileAccess.READ)
	var json_data := file_access.get_line()
	file_access.close()
	var data: Dictionary = JSON.parse_string(json_data)
	database = data

func get_item_data(item_id)-> Dictionary :
	if !database.has(item_id) :
		return {}
	return database[item_id]

func get_item(item_id) -> Item :
	var item_type = database[item_id]["item_type"]
	match item_type :
		"weapon" :
			if database[item_id].weapon_type == "gun":
				var w = ItemGun.new()
				w.set_data( database[item_id])
				return w
			var m = ItemMelee.new()
			m.set_data( database[item_id])
			return m
		"consumable" :
			var c = ItemConsumable.new()
			c.set_data(database[item_id])
			return c
		"equipment" :
			var e =  ItemEquipment.new()
			e.set_data(database[item_id])
			return e
		"material" :
			var m =  ItemMaterial.new()
			m.set_data( database[item_id])
			return m
	return null

func get_old_item(item_id, old_data) -> Item  :
	var item_type = database[item_id]["item_type"]
	var data :Dictionary= database[item_id]
	data["item_stats"] = old_data
	
	match item_type :
		"weapon" :
			if database[item_id].weapon_type == "gun":
				var w = ItemGun.new()
				w.set_data(data)
				return w
			var m =  ItemMelee.new()
			m.set_data(data)
			return m
		"consumable" :
			var c = ItemConsumable.new()
			c.set_data(data)
			return c
		"equipment" :
			var e = ItemEquipment.new()
			e.set_data(data)
			return e
		"material" :
			var m =  ItemMaterial.new()
			m.set_data( data)
			return m
			
	return null

func get_spawn_item(item_id, amount:=1) -> Item :
	randomize()
	var is_id_valid = database.get(item_id) != null
	if !is_id_valid :
		return null
	var item_type = database[item_id]["item_type"]
	var db = database[item_id]
	match item_type :
		"weapon" :
			var rd = randi_range(1, db.max_durability)
			db["item_stats"] = {"durability" : rd}
			if database[item_id].weapon_type == "gun":
				var w = ItemGun.new()
				w.set_data(db)
				return w
			var m = ItemMelee.new()
			m.set_data( db)
			return m
		"consumable" :
			db["item_stats"] = {"amount" : clamp(amount, 1, db.max_amount)}
			var c = ItemConsumable.new()
			c.set_data(db)
			return c
		"equipment" :
			var rd = randi_range(1, db.max_durability)
			db["item_stats"] = {"durability" : rd}
			var e =  ItemEquipment.new()
			e.set_data( db)
			return e
		"material" :
			db["item_stats"] = {"amount" : clamp(amount, 1, db.max_amount)}
			var m =  ItemMaterial.new()
			m.set_data(db)
			return m
	return null

func get_data(id) :
	return database.get(id, {})
