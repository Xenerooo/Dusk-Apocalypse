@tool
extends Control
class_name EquipmentSlot
@export var player_token: String
@export var root: String

@export var root_slot: Control
@export var grid: FlowContainer
@onready var label: Label = $MarginContainer/VBoxContainer/HBoxContainer/Label
@onready var margin_container: MarginContainer = $MarginContainer
@onready var panel: Panel = $Panel



@export var has_slots := true :
	set(value):
		has_slots = value
		if Engine.is_editor_hint() :
			tool_adjust_slot(value)

var slot_refs: Array = []

var index := -1

const SLOT_UI = preload("res://scenes/ui/inventory/slot_ui.tscn")

func tool_adjust_slot(state:bool):
	if Engine.is_editor_hint() == false:
		return
	#var s := $MarginContainer/VBoxContainer/HBoxContainer/Label
	#var g := $MarginContainer/VBoxContainer/ScrollContainer
	#if s == null and g == null :
		#return
	#if state == true :
		#g.hide()
		#s.hide()
	#else :
		#g.show()
		#s.show()
	#pass

func adjust_slot(state: bool):

	if state == false:
		$MarginContainer/VBoxContainer/HBoxContainer/Label.show()
		$MarginContainer/VBoxContainer/ScrollContainer.show()
	else:
		$MarginContainer/VBoxContainer/HBoxContainer/Label.hide()
		$MarginContainer/VBoxContainer/ScrollContainer.hide()
		#root_slot.size_flags_vertical = Control.SIZE_EXPAND_FILL
		#root_slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		#$MarginContainer/VBoxContainer/HBoxContainer.size_flags_vertical = Control.SIZE_EXPAND_FILL
		

# ---------------------------------
# Setup
# ---------------------------------
func setup() -> void:
	# Root slot setup
	var slot_ui: Control = root_slot
	slot_ui.player_token = player_token
	slot_ui.root = root
	slot_ui.index = -1
	
	adjust_slot(has_slots)
# Called by InventoryUI when server syncs data
func refresh(equipment: Dictionary) -> void:
	# Root slot update
	#var root_item: Dictionary = equipment.get("root", {})
	#print(equipment)
	
	if equipment.is_empty() :
		margin_container.hide()
		panel.hide()
		label.text = ""
	else:
		set_stats(equipment)
		panel.show()
		margin_container.show()
	
	root_slot.refresh(equipment)

	# Clear old slots
	for slot in slot_refs:
		if is_instance_valid(slot):
			slot.queue_free()

	slot_refs.clear()
	# Populate child slots from server data
	var slots: Array = equipment.get("item_stats", {}).get("slots", [])
	for i in range(slots.size()):
		var new_slot: Control = SLOT_UI.instantiate()
		new_slot.player_token = player_token
		new_slot.root = root
		new_slot.index = i
		new_slot.refresh({} if slots[i] == null else slots[i])
		grid.add_child(new_slot)
		slot_refs.append(new_slot)

func set_stats(item :Dictionary):
	var item_id :String= item.get("itemid", "")
	var item_data :Dictionary= ItemDatabase.get_data(item_id)
	var item_durability :int = item.get("item_stats", {}).get("durability", 0)

	label.text = str("%.1f" % ((item_durability / item_data.max_durability) * 100), "%")

func _can_drop_data(pos, data):
	# Must contain valid transfer info
	return data.has("src_root") and data.has("src_index")

func _drop_data(pos, data):
	# Prevent dropping into same slot
	if data.src_root == root and data.src_index == index:
		return
	
	# Tell server to handle transfer
	InventoryManager.rpc_id(1, "request_transfer_item",
		data.player_token, data.src_root, data.src_index,
		player_token, root, index
	)
