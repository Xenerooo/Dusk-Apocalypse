extends CharacterBody2D
class_name PlayerCharacter

var token := ""
@export var SPEED := 12000.0

@onready var movement: Node = $Movement
@onready var label: Label = $Label
@onready var InputSync: MultiplayerSynchronizer = $InputSync
@onready var HostSsync: MultiplayerSynchronizer = $HostSync
@onready var camera_2d: Camera2D = $Camera2D

var is_local := false
var is_inside_structure: =false

@export var lerp_speed := 10.0

@export var sync_position: = Vector2.ZERO
@export var client_position := Vector2.ZERO

@export var animation_tree: AnimationTree
@export var state_machine: FiniteStateMachine
@export var audios: Node2D 

@onready var remote_transform_2d: RemoteTransform2D = $RemoteTransform2D

func _on_tree_entered() -> void:
	pass # Replace with function body.
	
func host_setup():
	InputSync.set_multiplayer_authority(int(name))
	InputSync.player = self
	camera_2d.enabled = InputSync.is_multiplayer_authority()

func client_setup():
	movement.player = self
	request_player_name_setup.rpc_id(1)
	audios.set_as_current(is_local)
	if is_local:
		remote_transform_2d.remote_path = GameSession.shadow.get_path()

func _ready() -> void:
	host_setup()
	client_setup()

func _physics_process(delta: float) -> void:
	if !multiplayer.is_server():
		client_position = client_position.lerp(sync_position, lerp_speed * delta)
		global_position = client_position
	else:
		#velocity = get_input() * SPEED * delta
		#move_and_slide()
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

func play_footstep():
	audios.footstep(self)
