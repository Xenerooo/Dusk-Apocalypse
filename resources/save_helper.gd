# SaveHelper.gd
extends Node
class_name SaveHelper

## Saves a Dictionary as a JSON file at the given path
static func save_json(path: String, data: Dictionary) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		var json_string := JSON.stringify(data, "\t")  # Pretty print with tabs
		file.store_string(json_string)
		file.close()
	else:
		push_error("Failed to save JSON: " + path)

## Loads and parses a JSON file into a Dictionary
static func load_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("File doesn't exist: " + path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if file:
		var text := file.get_as_text()
		var result = JSON.parse_string(text)
		if typeof(result) == TYPE_DICTIONARY:
			return result
		else:
			push_error("Invalid JSON format in: " + path)
	else:
		push_error("Failed to open file: " + path)
	return {}


static func string_to_vector2(vector_string: String) -> Vector2:
	if vector_string.is_empty():
		return Vector2.ZERO

	# Remove parentheses and split by comma
	var cleaned_string = vector_string.replace("(", "").replace(")", "")
	var components = cleaned_string.split(", ")

	if components.size() == 2:
		var x = float(components[0])
		var y = float(components[1])
		return Vector2(x, y)
	else:
		# Handle cases where the format might be incorrect
		# You could print an error or return Vector2.ZERO
		print("Error: Invalid Vector2 string format: ", vector_string)
		return Vector2.ZERO
