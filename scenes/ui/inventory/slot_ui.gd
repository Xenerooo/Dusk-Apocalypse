extends Control

@export var icon :TextureRect
@export var player_token: String
@export var root: String
@export var index: int
@export var amount: Label
@export var amount_panel: NinePatchRect

var item_id: String = ""
var item_data: Dictionary = {}


# ---------------------------------
# UI Refresh
# ---------------------------------
func refresh(item: Dictionary) -> void:
	if item.is_empty(): 
		if index == -1:
			set_default_icon(root)
		else:
			set_slot_empty() 
	else:
		set_item_on_slot(item)

func set_default_icon(root:String):
	set_slot_empty()
	match root:
		"head":
			icon.texture = preload("res://asset/user_interface/default_head.tres")
		"body":
			icon.texture = preload("res://asset/user_interface/default_body.tres")
		"vest":
			icon.texture = preload("res://asset/user_interface/default_vest.tres")
		"bag":
			icon.texture = preload("res://asset/user_interface/default_bag.tres")
		_:
			pass

func set_slot_empty():
	item_id = ""
	item_data = {}
	icon.texture = null
	amount.text = ""
	amount_panel.hide()
	

func set_item_on_slot(item:Dictionary):
	item_id = item.get("itemid", "")
	item_data = item
	var icon_path :String= ItemDatabase.get_data(item_id).icon_path
	var exist := ResourceLoader.exists(icon_path)
	var item_amount :int = item.get("item_stats", {}).get("amount", 0)
	
	amount.text = "" if item_amount == 0 else str(item_amount)
	icon.texture = load(icon_path) if exist else load("res://icon.svg")
	amount_panel.set_visible(true if item_amount > 0 else false)
# ---------------------------------
# Drag & Drop
# ---------------------------------

func _get_drag_data(pos):
	if item_id == "":
		return null
	var drag_preview :Control= preload("res://scenes/ui/inventory/icon_draggr.tscn").instantiate()
	# Drag preview icon
	drag_preview.get_node("Icon").texture = icon.texture
	#drag_preview.get_node("Icon").size = icon.size
	#drag_preview.expand = true
	#drag_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT
	set_drag_preview(drag_preview)

	# Send slot info
	return {
		"player_token": player_token,
		"src_root": root,
		"src_index": index,
		"item_id": item_id
	}

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
