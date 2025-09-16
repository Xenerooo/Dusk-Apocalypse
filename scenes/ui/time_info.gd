extends TextureRect
@onready var label: Label = $Text

func _process(delta: float) -> void:
	label.text = WorldManager.time_manager.get_current_time_string()
