extends MultiplayerSynchronizer
var player :PlayerCharacter

@export var local_move_input :Vector2 

func _physics_process(delta: float) -> void:
	if player and is_multiplayer_authority():
		var dir :Vector2= GameUI.player_controls.move_stick.output
		local_move_input = dir
