# ZombieHordeManager.gd
extends Node

var hordes = []

func spawn_zombies(to) -> void:
	var h = Horde.new()
	hordes.append(h)
	add_child(h)
	h._spawn_zombies(to)

func _process(delta):
	for horde in hordes:
		horde.update_direction()
		horde.move_virtual(delta)

#
