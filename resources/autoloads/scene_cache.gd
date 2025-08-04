extends Node

func _ready() -> void:
	warm_up_folder("res://scenes/structures/")

func warm_up_folder(folder_path: String):
	var dir = DirAccess.open(folder_path)
	if dir == null:
		push_error("Cannot open folder: " + folder_path)
		return

	dir.list_dir_begin()
	var filename = dir.get_next()
	while filename != "":
		if not dir.current_is_dir() and filename.ends_with(".tscn"):
			var scene_path = folder_path.path_join(filename)
			var scene = load(scene_path)
			if scene and scene is PackedScene:
				var instance = scene.instantiate()
				add_child(instance)
				instance.visible = false
				instance.queue_free()
				print("✅ Scene cached.")
		filename = dir.get_next()

	dir.list_dir_end()
