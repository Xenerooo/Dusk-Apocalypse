extends Control

@export var world_list :VBoxContainer
@export var create_button : Button
@export var back_button : Button

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
			var world_path = base_path.path_join(folder).path_join("world.json")
			if FileAccess.file_exists(world_path):
				var btn = Button.new()
				btn.text = folder
				btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				btn.pressed.connect(func(): _on_world_selected(folder))
				world_list.add_child(btn)
		folder = dir.get_next()


func _on_world_selected(folder_name: String):
	var path = "user://worlds/%s" % folder_name
	print("💾 %s selected." % [path])
	GameSession.load_world(path)  # Replace with actual loader logic.
	
func _on_CreateNewWorldButton_pressed():
	# Optional: Prompt for name, otherwise auto-name
	var _name = "world_" + str(Time.get_unix_time_from_system())
	create_new_world(_name)

func create_new_world(world_name: String):
	var path = "user://worlds/%s" % world_name
	DirAccess.make_dir_recursive_absolute(path)
	
	var _map_gen := preload("res://scenes/ChunkSystem/map_generator.tscn").instantiate()
	var world_data = _map_gen.generate_map(world_name)
	var world_dict = {
		"world_name": world_name,
		"map_size": world_data.map_size,
		"tile_size": world_data.tile_size,
		"chunk_size": world_data.chunk_size,
		"chunks": world_data.chunks,
		"seed": world_data.seed
	}

	SaveHelper.save_json(path.path_join("world.json"), world_dict)
	SaveHelper.save_json(path.path_join("players.json"), {})   # Empty players
	SaveHelper.save_json(path.path_join("storages.json"), {})  # Empty storages
	SaveHelper.save_json(path.path_join("meta.json"), {
		"created_at": Time.get_datetime_string_from_system(),
		"seed": world_data.seed
	})
	
	_map_gen.queue_free()
	print("💾 saved!")
	#GameSession.load_world(path)


func _on_BackButton_pressed():
	#queue_free()
	hide()
