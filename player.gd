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
	#label.text = token
	request_player_name_setup.rpc_id(1)

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		global_position = global_position.lerp(sync_position, .5)
	else:
		sync_position = global_position

func get_input()-> Vector2:
	return InputSync.local_move_input

@rpc("any_peer", "call_local")
func request_player_name_setup():
	var peer_id:= multiplayer.get_remote_sender_id()
	setup_name.rpc_id(peer_id, PlayerManager.players[token].name) 

@rpc("authority", "call_local")
func setup_name(_name: String):
	label.text = _name
