extends Node2D


const GEARPICK = "res://asset/audio/gearpick.ogg"
const PICK_1 = "res://asset/audio/pick1.ogg"
const PICK_2 = "res://asset/audio/pick2.ogg"
const PICK_PISTOL = "res://asset/audio/pick_pistol.ogg"
const PICK_RIFLE = "res://asset/audio/pick_rifle.ogg"
const EMPTY_CLICK = "res://asset/audio/empty_click.ogg"
var inventory_feedback := [PICK_1, PICK_2]

const RELOAD_PISTOL = "res://asset/audio/reload_pistol.ogg"
const RELOAD_RIFLE = "res://asset/audio/reload_rifle.ogg"

const AUDIO_2D = preload("res://asset/audio/audio_2d.tscn")

@export var concrete := ["res://resources/audio/concrete_run_1.ogg",
"res://resources/audio/concrete_run_2.ogg",
 "res://resources/audio/concrete_run_3.ogg",
 "res://resources/audio/concrete_run_4.ogg"]

@export var punch := [
	"res://asset/audio/punch_swipes_1.ogg",
	"res://asset/audio/punch_swipes_0.ogg"
]

@export var footsteps := ["res://resources/audio/run_1.ogg",
 "res://resources/audio/run_2.ogg",
 "res://resources/audio/run_3.ogg",
 "res://resources/audio/run_4.ogg"]

@export var swipe := [
	"res://resources/audio/punch_swipes_0.ogg",
	"res://resources/audio/punch_swipes_1.ogg"
]

var floor_sound :Array= [
"res://resources/audio/wood_1.ogg",
"res://resources/audio/wood_2.ogg",
"res://resources/audio/wood_3.ogg",
"res://resources/audio/wood_4.ogg",
]

enum cell_noise {
	grass = 0,
	road = 1
	}

var audio_container: Node2D

func set_audio_container(node:Node2D):
	audio_container = node

@rpc("authority", "call_local", "unreliable")
func spawn_audio(path :String, pos: Vector2, dist: int = 2000, attenuation :int = 10.5,target = null) :
	if multiplayer.is_server() :
		if target :
			spawn_following_audio(path, pos, dist, attenuation, target)
		else :
			spawn_static_audio(path, pos, dist, attenuation)

#@rpc("any_peer", "call_local")
#func spawn_noise(p, l, world) :
	#if multiplayer.is_server() :
		#world.spawn_noise(p, l)

func get_tile_audio(audio_type :int):
	var audio
	match audio_type :
		cell_noise.grass :
			audio = footsteps.pick_random()
		cell_noise.road :
			audio = concrete.pick_random()
	return audio

func spawn_static_audio(path:String, pos: Vector2, _dist: int, attenuation:int) :
	var a = AUDIO_2D.instantiate()
	a.following = false

	a.dist = _dist
	a.path = path
	a.global_position = pos
	a.att = attenuation
	audio_container.add_child(a, true)

func spawn_following_audio(path: String, pos: Vector2, _dist :int, attenuation:int, target:Node2D) :
	var a = AUDIO_2D.instantiate()
	a.following = true
	a.dist = _dist
	a.path = path
	a.global_position = pos
	a.att = attenuation
	a.follow_target = target
	audio_container.add_child(a, true)


func reset_manager():
	for i in get_children():
		i.queue_free()
	audio_container = null
