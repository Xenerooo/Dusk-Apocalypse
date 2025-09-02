extends Control

@export var world_list :VBoxContainer
@export var create_button : Button
@export var back_button : Button

const LIST_CONTAINER = preload("res://scenes/main/main_menu/list_container.tscn")

func _ready() -> void:
	back_button.pressed.connect(_on_BackButton_pressed)
	create_button.pressed.connect(_on_CreateNewWorldButton_pressed)
	
	if not DirAccess.dir_exists_absolute("user://worlds"):
		DirAccess.make_dir_recursive_absolute("user://worlds")
	populate_world_list()
	
func populate_world_list():
	var base_path = "user://worlds"
	if not DirAccess.dir_exists_absolute(base_path):
		DirAccess.make_dir_recursive_absolute(base_path)

	for i in world_list.get_children():
		i.queue_free()

	var dir = DirAccess.open(base_path)
	if not dir:
		push_error("Could not open worlds directory.")
		return

	dir.list_dir_begin()
	var folder = dir.get_next()
	while folder != "":
		if dir.current_is_dir() and folder != "." and folder != "..":
			var world_path = base_path.path_join(folder).path_join("world.bin")
			if FileAccess.file_exists(world_path):
				var _list := LIST_CONTAINER.instantiate()
				_list.world_name = folder
				_list.on_selected_callable = func(): _on_world_selected(folder)
				_list.on_deleted_callable = func(): _on_world_deleted(folder)

				world_list.add_child(_list)
				
				#var btn = Button.new()
				#btn.text = folder
				#btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				#btn.pressed.connect(func(): _on_world_selected(folder))
				#world_list.add_child(btn)
		folder = dir.get_next()

func remove_recursive(directory_path: String) -> void:
	var dir = DirAccess.open(directory_path)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if dir.current_is_dir():
				remove_recursive(directory_path.path_join(file_name))
			else:
				DirAccess.remove_absolute(directory_path.path_join(file_name))
			file_name = dir.get_next()
		DirAccess.remove_absolute(directory_path)
	else:
		print("An error occurred when trying to access the path.")

func _on_world_selected(folder_name: String):
	var path = "user://worlds/%s" % folder_name
	print("💾 %s selected." % [path])
	GameSession.load_world(path)  # Replace with actual loader logic.

func _on_world_deleted(folder_name: String):
	var path = "user://worlds/%s" % folder_name
	remove_recursive(path)
	populate_world_list()

func _on_CreateNewWorldButton_pressed():
	# Optional: Prompt for name, otherwise auto-name
	var _name = "world_" + str(Time.get_unix_time_from_system())
	create_new_world(_name)
	populate_world_list()

func create_new_world(world_name: String):
	GameSession.create_world(world_name)
	#GameSession.load_world(path)


func _on_BackButton_pressed():
	#queue_free()
	hide()
