extends Node2D


const GEARPICK = "res://asset/audio/gearpick.ogg"
const PICK_1 = "res://asset/audio/pick1.ogg"
const PICK_2 = "res://asset/audio/pick2.ogg"
const PICK_PISTOL = "res://asset/audio/pick_pistol.ogg"
const PICK_RIFLE = "res://asset/audio/pick_rifle.ogg"
var inventory_feedback := [PICK_1, PICK_2]

const RELOAD_PISTOL = "res://resources/audio/reload_pistol.ogg"
const RELOAD_RIFLE = "res://resources/audio/reload_rifle.ogg"

const AUDIO_2D = preload("res://asset/audio/audio_2d.tscn")

@export var concrete := ["res://resources/audio/concrete_run_1.ogg",
"res://resources/audio/concrete_run_2.ogg",
 "res://resources/audio/concrete_run_3.ogg",
 "res://resources/audio/concrete_run_4.ogg"]

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

@rpc("authority", "call_local")
func spawn_audio(path :String, pos: Vector2, dist: int = 2000, attenuation :int = 10.5,target = null) :
	if multiplayer.is_server() :
		if target :
			spawn_following_audio.rpc(path, pos, dist, target)
		else :
			spawn_static_audio.rpc(path, pos, dist, attenuation)

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

@rpc("authority", "call_local")
func spawn_static_audio(path:String, pos: Vector2, _dist: int, attenuation:int) :
	var a = AUDIO_2D.instantiate()
	a.following = false
	a.dist = _dist
	a.path = path
	a.global_position = pos
	a.attenuation = attenuation
	add_child(a, true)

func spawn_following_audio(path, pos, _dist, target) :
	var a = AUDIO_2D.instantiate()
	a.follow_target = target
	a.dist = _dist
	a.path = path
	a.global_position = pos
	add_child(a, true)
