@tool
class_name VirtualJoystick

extends Control

## A simple virtual joystick for touchscreens, with useful options.
## Github: https://github.com/MarcoFazioRandom/Virtual-Joystick-Godot

# EXPORTED VARIABLE

signal analogic_chage(move: Vector2)
signal analogic_released
signal analogic_pressed
signal active(status)
signal pressed(status)
## The color of the button when the joystick is pressed.
@export var pressed_color := Color.GRAY

## If the input is inside this range, the output is zero.
@export_range(0, 200, 1) var deadzone_size : float = 10

## The max distance the tip can reach.
@export_range(0, 500, 1) var clampzone_size : float = 75

@export  var active_zone :float = 0.1

var _active := false :
	get:
		return _active

@export var input_action:StringName

@export var _scale :=  .5

func is_active() -> bool :
	return _active

enum Joystick_mode {
	FIXED, ## The joystick doesn't move.
	DYNAMIC ## Every time the joystick area is pressed, the joystick position is set on the touched position.
}

## If the joystick stays in the same position or appears on the touched position when touch is started
@export var joystick_mode := Joystick_mode.FIXED

enum Visibility_mode {
	ALWAYS, ## Always visible
	TOUCHSCREEN_ONLY ## Visible on touch screens only
}

## If the joystick is always visible, or is shown only if there is a touchscreen
@export var visibility_mode := Visibility_mode.ALWAYS

## If true, the joystick uses Input Actions (Project -> Project Settings -> Input Map)
@export var use_input_actions := true

@export var action_left := "ui_left"
@export var action_right := "ui_right"
@export var action_up := "ui_up"
@export var action_down := "ui_down"

# PUBLIC VARIABLES

## If the joystick is receiving inputs.
var is_pressed := false : 
	set(value) :
		is_pressed = value
		emit_signal("pressed", is_pressed)

# The joystick output.
var output := Vector2.ZERO

# PRIVATE VARIABLES

var _touch_index : int = -1

@onready var _base := $Base
@onready var _tip := $Base/Tip

@onready var _base_radius = _base.size / 2

@onready var _base_default_position : Vector2 = _base.position
@onready var _tip_default_position : Vector2 = _tip.position

@onready var _default_color : Color = _tip.modulate

# FUNCTIONS

func _ready() -> void:
	if not DisplayServer.is_touchscreen_available() and visibility_mode == Visibility_mode.TOUCHSCREEN_ONLY:
		hide()
	self.pivot_offset = size  / 2
	_base_radius = _base.size / 2
	_base.pivot_offset = _base.size / 2
	_tip_default_position = _base_radius / 2
	_tip.pivot_offset = _tip.size / 2
	
	#_base_default_position = _base_radius / 2
	#update()
func _on_resized() -> void:
	self.pivot_offset = size  / 2
	_base_radius = _base.size / 2
	_base.pivot_offset = _base.size / 2
	_tip.pivot_offset = _tip.size / 2
	#_tip_default_position
	_base_default_position = _base.position
	_tip_default_position =  _base_radius - _tip.pivot_offset
	#print()
	#_tip_default_position = _base.position
	#_base_default_position = _base_radius / 2
	pass

func _gui_input(event: InputEvent) -> void:
	
	if event is InputEventScreenTouch:
		if event.pressed:
			if _is_point_inside_joystick_area(event.position) and _touch_index == -1:
				if joystick_mode == Joystick_mode.DYNAMIC or (joystick_mode == Joystick_mode.FIXED and _is_point_inside_base(event.position)):
					if joystick_mode == Joystick_mode.DYNAMIC:
						_move_base(event.position)
					_touch_index = event.index
					_tip.modulate = pressed_color
					_update_joystick(event.position)
					get_viewport().set_input_as_handled()
		elif event.index == _touch_index:
			_reset()
			get_viewport().set_input_as_handled()
	elif event is InputEventScreenDrag:
		if event.index == _touch_index:
			_update_joystick(event.position)
			get_viewport().set_input_as_handled()

func _move_base(new_position: Vector2) -> void:
	_base.position = new_position - _base.pivot_offset

func _move_tip(new_position: Vector2) -> void:
	_tip.position = new_position - _tip.pivot_offset

func _is_point_inside_joystick_area(point: Vector2) -> bool:
	var x: bool = point.x >= position.x and point.x <= position.x + _base.size.x
	var y: bool = point.y >= position.y and point.y <= position.y + _base.size.y
	return true

func _is_point_inside_base(point: Vector2) -> bool:
	var center : Vector2 = _base.size / 2
	var vector : Vector2 = point - center
	if vector.length_squared() <= _base_radius.x * _base_radius.x:
		return true
	else:
		return false

func _update_joystick(touch_position: Vector2) -> void:
	var center : Vector2 = _base.position + _base_radius
	var vector : Vector2 = touch_position - center
	vector = vector.limit_length(clampzone_size)
	
	_move_tip(center + vector)
	
	if vector.length_squared() > deadzone_size * deadzone_size:
		is_pressed = true
		output = (vector - (vector.normalized() * deadzone_size)) / (clampzone_size - deadzone_size)
		emit_signal("analogic_chage", output)
		if output.length() > active_zone :
			_active = true
			emit_signal("active", _active)
			_tip.modulate = Color.RED
			action_active()
		elif  output.length() < active_zone : 
			_active = false
			emit_signal("active", _active)
			_tip.modulate = Color.WHITE
			action_release()
			
	else:
		is_pressed = false
		_active = false
		output = Vector2.ZERO

		emit_signal("active", _active)
		emit_signal("analogic_chage", output)
		emit_signal("analogic_released")
		
	
	if use_input_actions:
		if output.x > 0:
			_update_input_action(action_right, output.x)
		else:
			_update_input_action(action_left, -output.x)

		if output.y > 0:
			_update_input_action(action_down, output.y)
		else:
			_update_input_action(action_up, -output.y)

func _update_input_action(action:String, value:float):
	if value > InputMap.action_get_deadzone(action):
		Input.action_press(action, value)
	elif Input.is_action_pressed(action):
		Input.action_release(action)

func _reset():
	is_pressed = false
	_active = false
	output = Vector2.ZERO
	action_release()
	emit_signal("active", _active)
	emit_signal("analogic_chage", output)
	_touch_index = -1
	_tip.modulate = _default_color
	_base.position = _base_default_position
	_tip.position = _tip_default_position
	if use_input_actions:
		for action in [action_left, action_right, action_down, action_up]:
			if Input.is_action_pressed(action) or Input.is_action_just_pressed(action):
				Input.action_release(action)

func joystick_held():
	var event = InputEventAction.new()
	event.action = input_action
	event.pressed = true
	Input.parse_input_event(event)

func joystick_released():
	var event = InputEventAction.new()
	event.action = input_action
	event.pressed = false
	Input.parse_input_event(event)
	
func action_active():
	var event = InputEventAction.new()
	event.action = input_action
	event.pressed = true
	Input.parse_input_event(event)
	
func action_release():
	var event = InputEventAction.new()
	event.action = input_action
	event.pressed = false
	Input.parse_input_event(event)
