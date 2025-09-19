extends Node

signal item_transferred()
signal item_equipped(token, root)
signal item_unequipped(token, root)
signal weapon_reloaded(token, body, index)



# Holds all inventories by token (player_id, storage_id, etc.)
var inventories: Dictionary = {}

# --- Player Inventory Template ---
# Each root slot holds either `null` or an ItemEquipment
var PLAYER_INVENTORY_TEMPLATE := {
	"head": null,
	"body": null,
	"vest": null,
	"bag": null,
	"weapon1": null,
	"weapon2": null,
	"melee": null
}

func _ready() -> void:
	item_equipped.connect(func(token, root):
		print("Item Equipped on %s %s" % [token, root]))
	item_unequipped.connect(func(token, root):
		print("Item Unequipped on %s %s" % [token, root]))

# ===========================
# Register / Init
# ===========================

func reset_manager():
	inventories.clear()

func save_data(path: String):
	var data = get_persistent_data_dict()
	SaveHelper.save_json(path.path_join("inventory.json"), data)

func load_data(data :Dictionary):
	for token in data.keys():
		var dictionary_inventory :Dictionary= data[token]
		for part in dictionary_inventory.keys() :
			var item :Variant = dictionary_inventory[part]
			if item != null:
				dictionary_inventory[part] = ItemDatabase.get_old_item(item.itemid, item.item_stats)
			else: 
				dictionary_inventory[part] = null
		
		inventories[token] = dictionary_inventory

func get_persistent_data_dict() -> Dictionary:
	var persistent_data := {}
	for token in inventories :
		var dictionary_inventory: Dictionary = {}
		var inventory :Dictionary= inventories[token]
		for part in inventory.keys():
			if inventory[part] != null :
				dictionary_inventory[part] = inventory[part].to_dict()
			else :
				dictionary_inventory[part] = null
		persistent_data[token] = dictionary_inventory
	
	return persistent_data

func get_player_persistent_data(token:String) -> Dictionary:
	var persistent_data := {}
	var inv :Dictionary = inventories.get(token, {})
	if inv != {}:
		for part in inv.keys():
			if inv[part] != null :
				persistent_data[part] = inv[part].to_dict()
			else :
				persistent_data[part] = null
	return persistent_data

func load_inventory():
	pass

func get_inventory_base() ->Dictionary:
	return PLAYER_INVENTORY_TEMPLATE.duplicate()

func register_inventory(token: String, is_player: bool = true) -> void:
	if inventories.has(token):
		return

	if is_player:
		# deep copy so each player has their own
		if inventory_exist(token):
			print("🎒 Inventory already exist.")
		else:
			inventories[token] = PLAYER_INVENTORY_TEMPLATE.duplicate(true)
			print("🎒 Inventory created with token (%s)." % [token])
	else:
		inventories[token] = {}  # storage system, not focus right now

func unregister_inventory(token: String) -> void:
	inventories.erase(token)


func inventory_exist(token)->bool:
	return inventories.has(token)
# ===========================
# Validation
# ===========================

func can_equip(slot: String, item: Item) -> bool:
	if item == null:
		return false
	if not (item is ItemEquipment or item is ItemWeapon):
		return false
	var equip: Item = item
	
	match slot:
		"head": return item is ItemEquipment and equip.equipment_type == ItemEquipment.EquipmentTypes.head
		"body": return item is ItemEquipment and equip.equipment_type == ItemEquipment.EquipmentTypes.body
		"vest": return item is ItemEquipment and equip.equipment_type == ItemEquipment.EquipmentTypes.vest
		"bag": return item is ItemEquipment and equip.equipment_type == ItemEquipment.EquipmentTypes.bag
		"weapon1", "weapon2": return item is ItemGun
		"melee": return item is ItemMelee
		_: return false


func can_store_in_equipment(equipment: ItemEquipment, item: Item) -> bool:
	if equipment == null:
		return false
	if not (equipment is ItemEquipment):
		return false
	if (item is ItemEquipment or item is ItemWeapon) and not equipment.can_store_equipment:
		return false
	return true

# ===========================
# Helpers
# ===========================

func get_item_at(token: String, root: String, index: int) -> Item:
	if not inventories.has(token):
		return null
	var inv = inventories[token]
	if not inv.has(root):
		return null

	var container = inv[root]

	# root slot item
	if index == -1:
		return container

	# inside slots
	if container is ItemEquipment and index >= 0 and index < container.max_slots:
		return container.slots[index]

	return null

func set_item_at(token: String, root: String, index: int, item: Item) -> bool:
	if not inventories.has(token):
		return false
	var inv = inventories[token]
	if not inv.has(root):
		return false

	var container = inv[root]

	# root slot
	if index == -1:
		inv[root] = item
		return true

	# inside slots
	if container is ItemEquipment and index >= 0 and index < container.max_slots:
		container.slots[index] = item
		return true

	return false


func get_available_slot(player_token: String, find_can_store_equipment: bool =false) -> Dictionary:
	if not inventories.has(player_token):
		return {}
	
	var inv = inventories[player_token]
	if inv.is_empty():
		return {}
	
	for root in inv.keys():
		var equip: ItemEquipment = inv[root]
		if find_can_store_equipment == true and equip.can_store_equipment != false:
			continue
		if equip:
			var idx = equip.slots.find(null)
			if idx != -1:
				return {"root": root, "index": idx}
	return {}


# ===========================
# Equip / Unequip
# ===========================

func equip_item(player_token: String, root: String, item: Item) -> bool:
	if not can_equip(root, item):
		return false

	var current = get_item_at(player_token, root, -1)
	if current != null:
		if not unequip_item(player_token, root):
			return false

	return set_item_at(player_token, root, -1, item)

func unequip_item(player_token: String, root: String) -> bool:
	var item: Item = get_item_at(player_token, root, -1)
	if item == null:
		return true

	var free_slot = get_available_slot(player_token)
	if free_slot.size() > 0:
		set_item_at(player_token, free_slot.root, free_slot.index, item)
	else:
		WorldManager.spawn_item(item, PlayerManager.get_position(player_token))

	set_item_at(player_token, root, -1, null)
	return true

func empty_item(item: Item)-> Array[Item]:
	if !item is ItemEquipment  :
		return []
	var residual_items :Array[Item]= []
	for i in item.slots.size():
		if item.slots[i] != null:
			residual_items.append(item.slots[i])
			item.slots[i] = null
	return residual_items

func place_in_available_slot(token:String, item:Item):
	if !item in [ItemWeapon, ItemEquipment]:
		var slot := get_available_slot(token)
		if slot : set_item_at(token, slot.root, slot.index, item)
		else: drop_item(item)
		
	else : 
		var slot := get_available_slot(token)
		if slot : set_item_at(token, slot.root, slot.index, item)
		else: drop_item(item)

func drop_item(item:Item):
	# PLACE HOLDER
	print("Item dropped: ", item.name)
# ===========================
# Transfer
# ===========================

func transfer_item(
	src_token: String, src_root: String, src_index: int,
	dst_token: String, dst_root: String, dst_index: int
) -> bool:
	var src_item = get_item_at(src_token, src_root, src_index)
	var dst_item := get_item_at(dst_token, dst_root, dst_index) 
	if src_item == null:
		return false

	# ✅ Prevent root item being stored inside its own container
	if src_index == -1 and dst_root == src_root and dst_index >= 0:
		return false
	
	var player:PlayerCharacter = PlayerManager.get_player_node(src_token)

	# Destination: root equip slot / equipping
	if dst_index == -1:
		if not can_equip(dst_root, src_item):
			return false

		set_item_at(src_token, src_root, src_index, null)
		if src_index == -1 :
			emit_signal("item_unequipped", src_token, src_root)
		
		set_item_at(dst_token, dst_root, -1, src_item)
		# swap the item if dst has item
		if dst_item != null :
			set_item_at(src_token, src_root, src_index, dst_item)
			if src_index == -1 :
				emit_signal("item_equipped", src_token, src_root)
			#emit_signal("item_equipped", dst_token, src_root)
			
		var dst_residual := empty_item(dst_item)
		for i in dst_residual:
			place_in_available_slot(dst_token, i)
		#Audio Application
		emit_signal("item_equipped", dst_token, dst_root)
		if player: cue_audio(player, src_item)
		return true
	
	#Source : root slot swapping from any item
	if src_index == -1:
		if not can_store_in_equipment(get_item_at(dst_token, dst_root, -1), src_item): return false
		if dst_item != null :
			if not can_equip(src_root, dst_item): return false
			set_item_at(dst_token, dst_root, dst_index, src_item)
			set_item_at(src_token, src_root, src_index, null)
			emit_signal("item_unequipped", src_token, src_root)
			# swap the item if dst has item
			if dst_item != null :
				set_item_at(src_token, src_root, src_index, dst_item)
				emit_signal("item_equipped", src_token, dst_root)
			emit_signal("item_equipped", dst_token, src_root)
		else :
			set_item_at(dst_token, dst_root, dst_index, src_item)
			set_item_at(src_token, src_root, src_index, null)
			emit_signal("item_unequipped", src_token, src_root)
			
			
		var src_residual := empty_item(src_item)
		for i in src_residual:
			place_in_available_slot(dst_token, i)
		
		if player: cue_audio(player, src_item)
		return true
	
	# Destination: inside container
	var dst_equipment: ItemEquipment = get_item_at(dst_token, dst_root, -1)
	if not (dst_equipment is ItemEquipment):
		return false
	if not can_store_in_equipment(dst_equipment, src_item):
		return false
	if dst_index >= dst_equipment.max_slots:
		return false
	#if get_item_at(dst_token, dst_root, dst_index) != null:
		#return false # occupied
	# Place item
	set_item_at(dst_token, dst_root, dst_index, src_item)
	set_item_at(src_token, src_root, src_index, null)
	if dst_index != null:
		set_item_at(src_token, src_root, src_index, dst_item)
	
	if player: AudioManager.spawn_audio.rpc(AudioManager.inventory_feedback.pick_random(), player.global_position)
	return true

# ===========================
# Split Item
# ===========================

func split_item(player_token: String, root: String, index: int, amount: int) -> bool:
	var item: Item = get_item_at(player_token, root, index)
	if item == null or not item.is_stackable:
		return false

	if amount <= 0 or amount >= item.amount:
		return false

	# Perform split
	var new_item: Item = ItemDatabase.get_old_item(item.itemid, {"amount": amount})
	item.amount -= amount

	# Find free slot anywhere
	var free_slot = get_available_slot(player_token)
	if free_slot.size() > 0:
		set_item_at(player_token, free_slot.root, free_slot.index, new_item)
	else:
		WorldManager.spawn_item(new_item, PlayerManager.get_position(player_token))

	return true

# ======================================
# RPC CALLS
# ========================================
@rpc("any_peer", "call_local")
func request_transfer_item(src_player_token: String, src_root: String, src_index: int, dst_player_token:String, dst_root: String, dst_index: int) -> void:
	var peer_id := multiplayer.get_remote_sender_id()
	
	var is_busy := PlayerManager.get_player_node(src_player_token).is_busy()
	
	if is_busy :
		return
	
	var success :bool= transfer_item(src_player_token, src_root, src_index, dst_player_token, dst_root, dst_index)
	
	if success:
		if src_root in ["melee", "weapon1", "weapon2"]:
			reset_weapon_index(src_player_token)
		# Push the new state back to the client
		var snapshot = get_player_persistent_data(src_player_token)
		GameUI.rpc_id(peer_id, "update_local_inventory", snapshot)
		#print("%s local: data sent to %s" % [multiplayer.get_unique_id(), peer_id])
	
@rpc("any_peer", "call_local")
func request_update_inventory(token: String):
	var snapshot = get_player_persistent_data(token)
	GameUI.rpc_id(multiplayer.get_remote_sender_id(), "update_local_inventory", snapshot)

# Returns consume time of consumable at slot
func get_consume_time(token: String, slot: int) -> float:
	var inv: Dictionary = inventories.get(token, {})
	if inv.is_empty():
		return 0.0
	
	var item = inv.get(slot, null)
	if item == null or not item.has("consume_time"):
		return 0.0
	
	return item["consume_time"]

# ============================================
# WEAPON FUNCTIONS
# ==========================================

func get_player_current_weapon(token: String, index : int)->ItemWeapon:
	var inventory :Dictionary= inventories.get(token, {})
	if inventory.is_empty():
		return null
	
	match index:
		0 : return get_item_at(token, "melee", -1)
		1 : return get_item_at(token, "weapon1", -1)
		2 : return get_item_at(token, "weapon2", -1)
	
	return null

	
	

# Returns reload time of weapon at slot
func get_reload_time(token: String, slot: int) -> float:
	var inv: Dictionary = inventories.get(token, {})
	if inv.is_empty():
		return 0.0

	var root_slot:String = ""
	match slot:
		1: root_slot = "weapon1"
		2: root_slot = "weapon2"

	var weapon :ItemGun= inv.get(root_slot, null)
	if weapon == null : return 0.0

	
	return weapon.reload_time

@rpc("any_peer", "call_local")
func request_reload(token: String):
	if not multiplayer.is_server():
		return
	
	var inv: Dictionary = inventories.get(token, {})
	if inv.is_empty():
		return

	# look up the active weapon slot internally
	var player :PlayerCharacter = PlayerManager.get_player_node(token)
	var active_index: int = player.get("active_weapon_index")
	var slot_name := "melee"
	match active_index:
		0: slot_name = "melee"
		1: slot_name = "weapon1"
		2: slot_name = "weapon2"
		_: "melee"

	var weapon: ItemGun = inv.get(slot_name, null)
	if weapon == null:
		return
	var ammo_id: String = weapon.ammo_id
	var max_ammo: int = weapon.max_ammo
	var current_ammo: int = weapon.ammo
	var available_ammo := find_ammo_slot(token, ammo_id)
	
	var needed_ammo :int = max_ammo - current_ammo
	var ammo_item := get_item_at(token, available_ammo.root, available_ammo.index)
	var ammo_item_amount := ammo_item.amount
	
	if ammo_item_amount > needed_ammo :
		ammo_item.amount = ammo_item.amount - needed_ammo
		weapon.ammo = weapon.ammo + needed_ammo
	else :
		set_item_at(token,  available_ammo.root, available_ammo.index, null)
		weapon.ammo = weapon.ammo + ammo_item.amount

	AudioManager.spawn_audio.rpc(AudioManager.RELOAD_RIFLE, Vector2.ZERO, 2000, 10.5, player)


func can_reload(token: String, slot: int) -> bool:
	var inv: Dictionary = inventories.get(token, {})
	if inv.is_empty():
		return false
	
	var root_slot:String = ""
	match slot:
		1: root_slot = "weapon1"
		2: root_slot = "weapon2"
	
	var weapon :ItemGun= inv.get(root_slot, null)
	if weapon == null:
		return false
	
	var ammo_id: String = weapon.ammo_id
	var mag_size: int = weapon.max_ammo
	var current_ammo: int = weapon.ammo
	var available_ammo := find_ammo_slot(token, ammo_id)

	# no need to reload if already full
	if current_ammo >= mag_size:
		return false
	
	if available_ammo.is_empty():
		return false
	
	return true

func find_ammo_slot(player_token: String, ammo_id: String) -> Dictionary:
	if not inventories.has(player_token):
		return {}
	
	var inv = inventories[player_token]
	if inv.is_empty():
		return {}
	
	for root in inv.keys():
		var equip: Item = inv[root]
		if equip == null or !equip is ItemEquipment:
			continue
		
		for i in range(equip.slots.size()):
			var item = equip.slots[i]
			if item and item.itemid == ammo_id:
				return {"root": root, "index": i}
	
	return {}

@rpc("any_peer", "call_local")
func reset_weapon_index(token:String):
	if not multiplayer.is_server():
		return
	var _player := PlayerManager.get_player_node(token)
	var _peer_id := PlayerManager.get_peer_id(token)

	_player.rpc_id(_peer_id, "confirm_swap_weapon", 0)
	_player.rpc("confirm_swap_weapon", 0) # for other peers
	GameUI.rpc_id(_peer_id, "update_local_swap_btn", 0)

@rpc("any_peer", "call_local")
func request_swap_weapon(token: String):
	if not multiplayer.is_server():
		return
	var _peer_id: int = PlayerManager.get_peer_id(token)
	var inv: Dictionary = inventories.get(token, {})
	if inv.is_empty():
		return

	# build the priority list
	var order: Array[int] = [0] # melee always valid
	if inv["weapon1"] != null:
		order.append(1)
	if inv["weapon2"] != null:
		order.append(2)

	if order.is_empty():
		return

	# get player node and current slot
	var _player: PlayerCharacter = PlayerManager.get_player_node(token)
	if _player == null:
		return

	var current_index := _player.active_weapon_index
	var idx := order.find(current_index)

	var next_slot: int
	if idx == -1 or idx == order.size() - 1:
		next_slot = order[0] # wrap around
	else:
		next_slot = order[idx + 1]

	# confirm swap back to player + others
	
	
	_player.rpc_id(_peer_id, "confirm_swap_weapon", next_slot)
	_player.rpc("confirm_swap_weapon", next_slot) # for other peers
	#GameUI.rpc_id(_peer_id, "update_local_swap_btn", next_slot)

func get_weapon_data(player_token:String, index: int)->Dictionary:
	if not multiplayer.is_server():
		return {}
	var data := {
				"item": null,
				"type" : ""
				}
	var inv: Dictionary = inventories.get(player_token, {})
	if inv.is_empty():
		return {}
	var root_slot : String
	match index :
		0 : 
			root_slot = "melee"
			data.type = "melee"
		1 :
			root_slot = "weapon1"
			data.type = "gun"
		2 :
			root_slot = "weapon2"
			data.type = "gun"
		
	var weapon : ItemWeapon = get_item_at(player_token, root_slot, -1)
	if weapon != null:
		data.item = weapon
	return data
	

# ============================================
# AUDIO CUE
# ==========================================

func cue_audio(player :PlayerCharacter, src_item:Item):
	if player: 
		match src_item.item_type:
			src_item.ItemTypes.equipment:
				AudioManager.spawn_audio.rpc(AudioManager.GEARPICK, player.global_position)
			src_item.ItemTypes.weapon:
				AudioManager.spawn_audio.rpc(AudioManager.PICK_RIFLE, player.global_position)
