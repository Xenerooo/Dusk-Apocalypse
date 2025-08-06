extends CanvasLayer
@onready var line_edit: LineEdit = $DynamicMargin/Prompt/prompt/Panel/VBoxContainer/LineEdit
@onready var button: Button = $DynamicMargin/Prompt/prompt/Panel/VBoxContainer/Button

func _ready() -> void:
	button.pressed.connect(_on_confirmed_pressed)
	
func _on_confirmed_pressed():
	var _name := line_edit.text.strip_edges()
	if _name =="":
		return
	
	PlayerProfile.generate_profile(_name)
	self.queue_free()
