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

## Save a dictionary to a compressed binary file
const COMPRESSION_MODE := FileAccess.COMPRESSION_ZSTD
static func save_dict_to_file(data: Dictionary, path: String) -> void:
	var bytes := var_to_bytes(data)
	var original_size := bytes.size()
	var compressed := bytes.compress(COMPRESSION_MODE)

	var file := FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_32(original_size)  # Save original size
		file.store_buffer(compressed)
		file.close()
		print("💾 Saved: %d bytes → %d bytes compressed" % [original_size, compressed.size()])
	else:
		push_error("❌ Could not open file for writing: %s" % path)

static func load_dict_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_error("❌ File does not exist: %s" % path)
		return {}

	var file := FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("❌ Could not open file for reading: %s" % path)
		return {}

	var original_size = file.get_32()
	var compressed = file.get_buffer(file.get_length() - 4)
	file.close()

	var decompressed := compressed.decompress(original_size, COMPRESSION_MODE)
	if decompressed.size() != original_size:
		push_error("❌ Decompressed size mismatch: expected %d, got %d" % [original_size, decompressed.size()])
		return {}

	var result = bytes_to_var(decompressed)
	if typeof(result) != TYPE_DICTIONARY:
		push_error("❌ Loaded data is not a Dictionary.")
		return {}

	print("📥 Loaded dict from compressed file (%d bytes decompressed)." % decompressed.size())
	return result
