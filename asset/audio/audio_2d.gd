extends AudioStreamPlayer2D

var path : String = ""
var dist : int = 192
var following : bool = false
var follow_target: Node2D

func _ready() -> void:
	#if multiplayer.is_server() :
	if path.is_empty() :
		queue_free()
	max_distance = dist
	stream = load(path)
	playing = true
	#else :
		#max_distance = dist
		#stream = load(path)
		#playing = true
	
	set_process(following == true)

func _on_finished() -> void:
	queue_free()

func _process(delta: float) -> void:
	if multiplayer.is_server() and following:
		global_position = follow_target.global_position
