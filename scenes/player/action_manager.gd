# ActionManager.gd
extends Node2D
class_name ActionManager

# 🔒 Types of locks
enum ActionType {
	NONE,
	RELOAD,
	CONSUME,
	INTERACT,
	CRAFT,
	MELEE,
	WEAPON_SWAP
}

var token := ""
var current_action: ActionType = ActionType.NONE
var locked_data: Dictionary = {}
var lock_movement: bool = false

@onready var _timer: Timer = Timer.new()
@export var progress: TextureProgressBar

func _ready():
	if multiplayer.is_server():
		_timer.connect("timeout", Callable(self, "_on_timer_timeout"))
	_timer.one_shot = true
	add_child(_timer)

@rpc("any_peer", "call_local", "unreliable")
func display_start_timer(duration: float):
	progress.show()
	progress.max_value = duration
	_timer.start(duration)
	set_process(true)

@rpc("any_peer", "call_local", "unreliable")
func display_stop_timer():
	progress.hide()
	set_process(false)

func _process(delta: float) -> void:
	progress.value = _timer.time_left

# 🚦 Start a new action
func start_action(action: ActionType, duration: float, data: Dictionary = {}, block_movement: bool = false) -> bool:
	if current_action != ActionType.NONE:
		print("Currently Busy")
		return false # already locked

	current_action = action
	locked_data = data
	lock_movement = block_movement
	_timer.start(duration)

	display_start_timer.rpc(duration)
	return true

# ⏹ Cancel the current action
func cancel_action():
	_timer.stop()
	current_action = ActionType.NONE
	locked_data.clear()
	lock_movement = false
	display_stop_timer.rpc()

# ✅ Called when timer finishes
func _on_timer_timeout():
	match current_action:
		ActionType.RELOAD:
			InventoryManager.request_reload(token)
			PlayerManager.get_player_node(token).reset_animation.rpc()
		ActionType.CONSUME:
			InventoryManager.request_consume(token, locked_data.get("slot", -1))
		ActionType.INTERACT:
			pass
		ActionType.CRAFT:
			pass
		ActionType.MELEE:
			PlayerManager.get_player_node(token).reset_animation.rpc()

	current_action = ActionType.NONE
	locked_data.clear()
	lock_movement = false
	display_stop_timer.rpc()

func busy() -> bool:
	return current_action != ActionType.NONE
