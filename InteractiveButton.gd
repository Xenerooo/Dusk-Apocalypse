class_name InteractiveButton
extends Button

const DefaultValues := {
	"expand" : true,
	"ignore_texture_size" : true,
	"stretch_mode" : TextureButton.STRETCH_KEEP_ASPECT_CENTERED,
	"action_mode" : TextureButton.ACTION_MODE_BUTTON_PRESS,
	"focus_mode" : TextureButton.FOCUS_NONE,
}

var double_click_time_threshold : float = 0.1
var last_click_time : float = 0.0

@export var input_action:StringName
@export var use_default_values := true
@export var touchscreem_only := false
var click_pending : bool = false
var touch_index := 0
var released := true

func _init():
	if use_default_values :
		for k in DefaultValues.keys() :
			self.set(k, DefaultValues.get(k))
	
	if touchscreem_only and not DisplayServer.is_touchscreen_available() :
		hide()
	
	self.button_up.connect(func():
		release())

func press():
	var event = InputEventAction.new()
	event.action = input_action
	event.pressed = true
	Input.parse_input_event(event)
	released = false 


func release():
	var event = InputEventAction.new()
	event.action = input_action
	event.pressed = false
	Input.parse_input_event(event)
	released = true
	

func is_in(pos:Vector2) -> bool:
	if int(pos.x) in range(global_position.x, global_position.x+size.x) :
		if int(pos.y) in range(global_position.y, global_position.y+size.y) :
			return true
	return false
	
func _pressed() -> void:
	var current_time = Time.get_ticks_msec() / 1000.0
	if current_time - last_click_time < double_click_time_threshold:
		# Double-click detected, cancel the single-click action
		if click_pending:
			#print("double clicked")
			click_pending = false  # Reset for the next click
	else:
		# Single-click detected, set up for the possible double-click
		click_pending = true
		last_click_time = current_time
		# Start a timer to detect a single-click delay
		await get_tree().create_timer(double_click_time_threshold).timeout
		if click_pending:  # No double-click happened, it's a single-click
			#print("single click")
			click_pending = false  # Reset for the next click
	press()
