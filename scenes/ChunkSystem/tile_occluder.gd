extends Node2D

@export var player: Node2D
@export var tile_size := Vector2(24, 24)
@export var radius := 4

@onready var chunk_manager: ChunkManager = get_parent()

var last_player_tile := Vector2i(-1, -1) # Initialized to an invalid position

func _process(_delta):
	if player == null:
		return

	var player_tile := Vector2i(player.global_position / tile_size)

	# Only update if player moved to a new tile
	if player_tile != last_player_tile:
		last_player_tile = player_tile
		update_tile_modulation(player_tile)

func update_tile_modulation(player_tile: Vector2i) -> void:
	GlobalOccluder.current_modulated_tiles.clear()

	for x in range(-radius, radius + 1):
		for y in range(-radius, radius + 1):
			var tile := player_tile + Vector2i(x, y)
			GlobalOccluder.modulated_cells[tile] = Color(1, 1, 1, 0)
			GlobalOccluder.current_modulated_tiles[tile] = true

	for prev_tile in GlobalOccluder.last_modulated_tiles.keys():
		if not GlobalOccluder.current_modulated_tiles.has(prev_tile):
			GlobalOccluder.modulated_cells[prev_tile] = Color(1, 1, 1, 1)  # Reset color instead of erasing

	GlobalOccluder.last_modulated_tiles = GlobalOccluder.current_modulated_tiles.duplicate()
	get_tiles_in_radius()

func get_tiles_in_radius():
	var called :={}
	for pos in GlobalOccluder.modulated_cells.keys():
		var chunk :Chunk= chunk_manager.get_chunk_from_pos(pos)
		if chunk:
			if called.has(chunk.chunk_pos): continue
			called[chunk.chunk_pos] = true
			chunk.visibility_toggle() #the modulation is called here
