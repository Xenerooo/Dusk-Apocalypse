extends Node

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
	if item is ItemEquipment and not equipment.can_store_equipment:
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

func get_available_slot(player_token: String) -> Dictionary:
	if not inventories.has(player_token):
		return {}

	var inv = inventories[player_token]
	for root in inv.keys():
		var equip: ItemEquipment = inv[root]
		if equip != null and equip is ItemEquipment:
			for i in range(equip.max_slots):
				if equip.slots[i] == null:
					return {"root": root, "index": i}
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

# ===========================
# Transfer
# ===========================

func transfer_item(
	src_token: String, src_root: String, src_index: int,
	dst_token: String, dst_root: String, dst_index: int
) -> bool:
	var src_item = get_item_at(src_token, src_root, src_index)
	if src_item == null:
		return false

	# ✅ Prevent root item being stored inside its own container
	if src_index == -1 and dst_root == src_root and dst_index >= 0:
		return false
	
	var player:PlayerCharacter = PlayerManager.get_player_node(src_token)

	
	# Destination: root equip slot
	if dst_index == -1:
		if not can_equip(dst_root, src_item):
			return false
		set_item_at(dst_token, dst_root, -1, src_item)
		set_item_at(src_token, src_root, src_index, null)
		if player: AudioManager.spawn_audio.rpc(AudioManager.GEARPICK, player.global_position)
		return true

	# Destination: inside container
	var dst_equipment: ItemEquipment = get_item_at(dst_token, dst_root, -1)
	if not (dst_equipment is ItemEquipment):
		return false
	if not can_store_in_equipment(dst_equipment, src_item):
		return false
	if dst_index >= dst_equipment.max_slots:
		return false
	if get_item_at(dst_token, dst_root, dst_index) != null:
		return false # occupied

	# Place item
	set_item_at(dst_token, dst_root, dst_index, src_item)
	set_item_at(src_token, src_root, src_index, null)
	
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
	if not multiplayer.is_server():
		return

	var success = transfer_item(src_player_token, src_root, src_index, dst_player_token, dst_root, dst_index)
	print(success)
	if success:
		# Push the new state back to the client
		var snapshot = get_player_persistent_data(src_player_token)
		#rpc_id(multiplayer.get_remote_sender_id(), "update_inventory", src_player_token, snapshot)
		GameUI.rpc_id(multiplayer.get_remote_sender_id(), "update_local_inventory", snapshot)

@rpc("any_peer", "call_local")
func request_update_inventory(token: String):
	var snapshot = get_player_persistent_data(token)
	GameUI.rpc_id(multiplayer.get_remote_sender_id(), "update_local_inventory", snapshot)
	
