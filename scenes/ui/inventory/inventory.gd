extends Control

@export var player_token: String

@export var head_panel: Control
@export var vest_panel: Control
@export var bag_panel: Control
@export var body_panel: Control
@export var weapon1_panel: Control
@export var weapon2_panel: Control
@export var melee_panel: Control

# panels dictionary: root -> PanelUI
var panels: Dictionary = {}

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_accept"):
		if GameSession.on_session == false:
			return
		InventoryManager.rpc_id(1, "request_update_inventory", player_token)

func open_inventory():
	show()
	InventoryManager.rpc_id(1, "request_update_inventory", player_token)

func _ready() -> void:
	# Collect pre-placed panels
	hide()
	player_token = PlayerProfile.token ##TODO : MAKE A PROPER ON JOIN SETUP
	panels = {
		"head": head_panel,
		"vest": vest_panel,
		"bag": bag_panel,
		"body": body_panel,
		"weapon1": weapon1_panel,
		"weapon2": weapon2_panel,
		"melee": melee_panel
	}
	for panel in panels.values():
		panel.player_token = player_token
		panel.setup()
	
	
	#for child in panel_container.get_children():
		#panels[child.root] = child
		#child.player_token = player_token
		#child.setup()
	# Ask server for initial sync
	#rpc_id(1, "request_inventory_sync", player_token)

# ---------------------------------
# Refresh (only update existing panels)
# ---------------------------------
func refresh_inventory(inventory: Dictionary) -> void:
	# inventory looks like:
	# { "head": {"root": {...}, "slots": [...]}, ... }

	for root in panels.keys():
		if inventory.has(root):
			panels[root].refresh({} if inventory[root] ==  null else inventory[root])
		else:
			# no data for this root → clear it
			panels[root].refresh({"root": null, "slots": []})

# ---------------------------------
# RPCs
# ---------------------------------
func sync_inventory(inventory: Dictionary) -> void:
	refresh_inventory(inventory)

@rpc("any_peer", "reliable", "call_local")
func request_inventory_sync(token: String) -> void:
	if GameSession.on_session == false:
		var sender := multiplayer.get_remote_sender_id()
		InventoryManager


func _on_hide_button_pressed() -> void:
	hide()
