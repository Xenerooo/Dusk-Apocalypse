extends Node2D
@onready var chunk_manager: ChunkManagerMP = $ChunkManager

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()
	if event.is_action_pressed("cam_zoom"):
		get_viewport().get_camera_2d().zoom.x +=.1 
		get_viewport().get_camera_2d().zoom.y +=.1 
	if event.is_action_pressed("cam_zoom_out"):
		get_viewport().get_camera_2d().zoom.x -=.1 
		get_viewport().get_camera_2d().zoom.y -=.1 

func _ready() -> void:
	GameSession.set_player_container(self)
	

func load_world_data():
	var world_data = WorldManager.get_world_data()
	var chunks = WorldManager.get_chunks()

	#chunk_manager.setup(
		#world_data.map_size,
		#world_data.tile_size,
		#world_data.chunk_size,
		#world_data.seed
	#)
	
