extends HBoxContainer
@onready var join_world: Button = $JoinWorld
@onready var delete_world: Button = $deleteWorld

var on_selected_callable:Callable 
var on_deleted_callable:Callable 
var world_name := ""

func _ready() -> void:
	set_world_name(world_name)
	join_world.pressed.connect(on_selected_callable)
	delete_world.pressed.connect(on_deleted_callable)
	
func get_world_name()-> String:
	return join_world.text

func set_world_name(_name: String):
	join_world.text = _name
