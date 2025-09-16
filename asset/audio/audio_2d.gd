extends AudioStreamPlayer2D

@export var path : String = ""
@export var dist : int = 2000
@export var att : float
var following : bool = false
var follow_target: Node2D

func _ready() -> void:
	if path.is_empty() :
		queue_free()
	max_distance = dist
	stream = load(path)
	attenuation = att
	playing = true
	
	if multiplayer.is_server():
		set_process(following == true)
	

func _on_finished() -> void:
	if multiplayer.is_server():
		queue_free()

func _process(delta: float) -> void:
	if following:
		global_position = follow_target.global_position
