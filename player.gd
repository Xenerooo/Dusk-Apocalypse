extends CharacterBody2D
class_name Player
var token := ""
@export var SPEED := 12000.0

@onready var movement: Node = $Movement
@onready var label: Label = $Label
@onready var InputSync: MultiplayerSynchronizer = $InputSync
@onready var HostSsync: MultiplayerSynchronizer = $HostSync
@onready var camera_2d: Camera2D = $Camera2D

var sync_position: = Vector2.ZERO

func _on_tree_entered() -> void:
	pass # Replace with function body.
	
func host_setup():
	InputSync.set_multiplayer_authority(int(name))
	InputSync.player = self
	camera_2d.enabled = InputSync.is_multiplayer_authority()

func _ready() -> void:
	#if multiplayer.is_server() :
	host_setup()
	movement.player = self
	label.text = token

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		global_position = global_position.lerp(sync_position, .8)
	else:
		sync_position = global_position

func get_input()-> Vector2:
	return InputSync.local_move_input
