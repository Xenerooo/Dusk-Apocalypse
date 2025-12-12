extends Node2D
@export var player :PlayerCharacter
@export var human_sprite : Sprite2D
@export var part_body : Sprite2D
@export var part_head : Sprite2D
@export var part_vest : Sprite2D
@export var part_bag : Sprite2D
@export var part_melee : Sprite2D
@export var part_weapon1 : Sprite2D
@export var part_weapon2 : Sprite2D

var const_sprite := {
	"M" : null,
	"B" : null
}

var melee_sprites := {
	"M" : null,
	"B" : null
}

var weapon1_sprites := {
	"M" : null,
	"B" : null
}

var weapon2_sprites := {
	"M" : null,
	"B" : null
}

func update_hand_sprite(current_index):
	
	part_melee.texture = null if melee_sprites["B"] == null else load(melee_sprites["B"])
	part_weapon1.texture = null if weapon1_sprites["B"] == null else load(weapon1_sprites["B"])
	part_weapon2.texture = null if weapon2_sprites["B"] == null else load(weapon2_sprites["B"])
	match current_index:
		0 :
			part_melee.texture =  null if melee_sprites["M"] == null else load(melee_sprites["M"])
		1: 
			part_weapon1.texture =  null if weapon1_sprites["M"] == null else load(weapon1_sprites["M"])
		2:
			part_weapon2.texture =  null if weapon2_sprites["M"] == null else load(weapon2_sprites["M"])
			
func _on_body_frame_changed() -> void:
	part_body.frame = human_sprite.frame
	part_head.frame = human_sprite.frame
	part_vest.frame = human_sprite.frame
	part_bag.frame = human_sprite.frame
	part_melee.frame = human_sprite.frame
	part_weapon1.frame = human_sprite.frame
	part_weapon2.frame = human_sprite.frame

@rpc("authority", "unreliable", "call_local")
func update_sprite(part :String, item_id: String):
	var _item_data :Dictionary= ItemDatabase.get_data(item_id)
	var exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.sprite_path)
	#print(part, item_id)
	#print(exist, " ", _item_data.sprite_path)
	match part :
		"head":
			part_head.texture = load(_item_data.sprite_path) if exist else null
		"body":
			part_body.texture = load(_item_data.sprite_path) if exist else null
		"vest":
			part_vest.texture = load(_item_data.sprite_path) if exist else null
		"bag":
			part_bag.texture = load(_item_data.sprite_path) if exist else null
		"melee":
			if !_item_data.is_empty():
				var main_exist := ResourceLoader.exists(_item_data.sprite_path)
				var back_exist := ResourceLoader.exists(_item_data.back_sprite_path)
				melee_sprites["M"] = _item_data.sprite_path if main_exist else  null
				melee_sprites["B"] = _item_data.back_sprite_path if back_exist else null
				update_hand_sprite(player.active_weapon_index)
			else : 
				melee_sprites = {"B": null, "M": null}
		"weapon1":
			if !_item_data.is_empty():
				var main_exist := ResourceLoader.exists(_item_data.sprite_path)
				var back_exist := ResourceLoader.exists(_item_data.back_sprite_path)
				weapon1_sprites["M"] = _item_data.sprite_path if main_exist else  null
				weapon1_sprites["B"] = _item_data.back_sprite_path if back_exist else null
				update_hand_sprite(player.active_weapon_index)
			else : 
				weapon1_sprites = {"B": null, "M": null}
		"weapon2":
			if !_item_data.is_empty():
				var main_exist := ResourceLoader.exists(_item_data.sprite_path)
				var back_exist := ResourceLoader.exists(_item_data.back_sprite_path)
				weapon2_sprites["M"] = _item_data.sprite_path if main_exist else  null
				weapon2_sprites["B"] = _item_data.back_sprite_path if back_exist else null
				update_hand_sprite(player.active_weapon_index)
			else : 
				weapon2_sprites = {"B": null, "M": null}

@rpc("authority", "unreliable", "call_local")
func update_sprites(parts: Dictionary):
	print("received in %s " % player.token)
	for i in parts.keys():
		var _item_data :Dictionary= ItemDatabase.get_data(parts[i])
		var exist :bool= false if _item_data.is_empty() else ResourceLoader.exists(_item_data.sprite_path)
		
		match i :
			"head":
				part_head.texture = load(_item_data.sprite_path) if exist else null
			"body":
				part_body.texture = load(_item_data.sprite_path) if exist else null
			"vest":
				part_vest.texture = load(_item_data.sprite_path) if exist else null
			"bag":
				part_bag.texture = load(_item_data.sprite_path) if exist else null
			"melee":
				var main_exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.sprite_path)
				var back_exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.back_sprite_path)
				melee_sprites["M"] = _item_data.sprite_path if main_exist else  null
				melee_sprites["B"] = _item_data.back_sprite_path if back_exist else null
			"weapon1":
				var main_exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.sprite_path)
				var back_exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.back_sprite_path)
				weapon1_sprites["M"] = _item_data.sprite_path if main_exist else  null
				weapon1_sprites["B"] = _item_data.back_sprite_path if back_exist else null
			"weapon2":
				var main_exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.sprite_path)
				var back_exist := false if _item_data.is_empty() else ResourceLoader.exists(_item_data.back_sprite_path)
				weapon2_sprites["M"] = _item_data.sprite_path if main_exist else  null
				weapon2_sprites["B"] = _item_data.back_sprite_path if back_exist else null
	update_hand_sprite(player.active_weapon_index)
