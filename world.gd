extends Node2D
@onready var chunk_manager: ChunkManagerMP = $ChunkManager
@onready var entity_container: Node2D = $EntityContainer
@onready var audio_container: Node2D = $Audio

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("reset"):
		get_tree().reload_current_scene()


func _ready() -> void:
	GameSession.set_player_container(self)
	AudioManager.set_audio_container($Audio)

	
func load_world_data():
	var world_data = WorldManager.get_world_data()
	var chunks = WorldManager.get_chunks()

	#chunk_manager.setup(
		#world_data.map_size,
		#world_data.tile_size,
		#world_data.chunk_size,
		#world_data.seed
	#)
	
