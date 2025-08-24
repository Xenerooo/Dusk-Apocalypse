extends Node2D

enum {
	DIRT,
	WOOD,
	CONCRETE
}

@onready var dirt: AudioStreamPlayer2D = $dirt
@onready var concrete: AudioStreamPlayer2D = $concrete
@onready var wood: AudioStreamPlayer2D = $wood

@onready var audio_listener_2d: AudioListener2D = $AudioListener2D



func footstep(player: PlayerCharacter):
	if player.is_inside_structure:
		wood.play()
		return

	var audio_type:= WorldManager.get_player_current_audio(player)
	match audio_type:
		0:
			dirt.play()
		1:
			wood.play()
		2: 
			concrete.play()
		_:
			dirt.play()

func set_as_current(local: bool = false):
	if local: audio_listener_2d.make_current() 
