extends Control
@export var decrease_time: InteractiveTouchscreenButton 
@export var label: Label 
@export var increase_time: InteractiveTouchscreenButton 
@export var line_edit : LineEdit

func _ready() -> void:
	line_edit.text_submitted.connect(change_seconds)

func _process(delta: float) -> void:
	
	label.text = WorldManager.time_manager.get_current_time_string()

func _input(event: InputEvent) -> void:
	if multiplayer.is_server() == false: return
	if event.is_action_pressed("inc_time"):
		WorldManager.time_manager.current_hours += 1 % 24
	if event.is_action_pressed("dec_time"):
		WorldManager.time_manager.current_hours = clamp(WorldManager.time_manager.current_hours - 1, 0, 24)

func change_seconds(seconds: String):
	line_edit.clear()
	WorldManager.time_manager.IN_GAME_SECONDS_PER_REAL_SECOND = int(seconds)
