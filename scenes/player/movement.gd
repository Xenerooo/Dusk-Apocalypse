extends Node

var player :CharacterBody2D
var move_vector:= Vector2.ZERO
@export var SPEED := 12000.0


func _physics_process(delta: float) -> void:
	if player:
		#var dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down").normalized()
		var dir :Vector2= GameUI.player_controls.move_stick.output
		if dir:
			player.velocity = dir * player.SPEED * delta
		else:
			player.velocity.x = move_toward(player.velocity.x, 0,600)
			player.velocity.y = move_toward(player.velocity.y, 0,600)
		
		player.move_and_slide()
