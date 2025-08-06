
@tool
extends Node
# Configuration
@export var MAP_SIZE := Vector2i(10, 10)
@export var  SINGLE_CITIES := 4
@export var  MULTI_CITIES := [
	{ "size": Vector2i(2, 1), "count": 0 },
	{ "size": Vector2i(2, 2), "count": 0 },
	{ "size": Vector2i(4, 2), "count": 0 }
]

@export var city_lookup :StructureLookups

var map := {}
var big_map := {
	"seed": 0,
	"map_size": MAP_SIZE,
	"chunk_size": 200,
	"tile_size": 24,
	"chunks": {} # Dictionary<Vector2i, Dictionary>
}

@export_tool_button("Generate Map", "🔨")
var tool_gen = generate_map
func generate_map(seed:String)->Dictionary:
	var rng :RandomNumberGenerator= RandomNumberGenerator.new()
	rng.seed = hash(seed)
	big_map.seed = rng.seed
	populate_map(rng)
	connect_roads()
	assign_road_variants()
	debug_print_map()

	#serialize_map_data(big_map)
	#save_world_as_json(serialize_map_data(big_map),  "res://saves/test_map.json")
	#save_world_save_resource(big_map,  "res://saves/test_map.tres" )
	return big_map
	print("✅ Generation Done")
	
@export_category("Loading")
@export var json_directory := ""
@export_tool_button("Import") var tool_import_json = import_map
func import_map():
	var data := load_world_from_json(json_directory)
	var deserialized := deserialize_map_data(data)
	print(deserialized)
	

# Step 1: Generate map and place cities
func populate_map(rng:RandomNumberGenerator):
	var regions = {}
	var city_id_counter := 1

	# Fill all with empty regions
	for y in MAP_SIZE.y:
		for x in MAP_SIZE.x:
			regions[Vector2i(x, y)] = {
				"type": "structure_empty",
				"prefab_id": "structure_empty",
				"size": Vector2i(1, 1),
				"meta_data": {
				}
			}

	## Place single cities
	var placed := 0
	while placed < SINGLE_CITIES:
		var pos = Vector2i(rng.randi() % MAP_SIZE.x, rng.randi() % MAP_SIZE.y)
		if regions[pos]["type"] == "structure_empty":
			regions[pos] = {
				"type": "city",
				"prefab_id": "city_single",
				"size": Vector2i(1, 1),
				"meta_data": {
					"root": pos,
					"local": Vector2i(0, 0),
					"city_id": city_id_counter
				}
			}
			placed += 1
			city_id_counter += 1
			regions[pos].prefab_id = city_lookup.variants.pick_random()

	# Place multi-tile cities
	for entry in MULTI_CITIES:
		var size: Vector2i = entry["size"]
		var count: int = entry["count"]
		var done := 0

		while done < count:
			var origin = Vector2i(rng.randi() % (MAP_SIZE.x - size.x + 1), rng.randi() % (MAP_SIZE.y - size.y + 1))
			var valid = true

			for y in size.y:
				for x in size.x:
					var check_pos = origin + Vector2i(x, y)
					if regions.get(check_pos, {}).get("type", "") != "empty":
						valid = false
						break

			if not valid:
				continue

			# Place tiles for multi-city
			for y in size.y:
				for x in size.x:
					var local_pos = Vector2i(x, y)
					var global_pos = origin + local_pos
					regions[global_pos] = {
						"type": "city",
						"prefab_id": "city_large",
						"size": size,
						"meta_data": {
							"root": origin,
							"local": local_pos,
							"city_id": city_id_counter
						}
					}

			done += 1
			city_id_counter += 1
#
	big_map["chunks"] = regions

# Step 2: Connect cities with roads
func connect_roads():
	var regions = big_map["chunks"]
	var size = big_map["map_size"]

	# Collect root city positions
	var city_roots := []
	for pos in regions.keys():
		var cell = regions[pos]
		if cell["type"] == "city":
			var root = cell.get("meta_data", {}).get("root", pos)
			if root == pos and not city_roots.has(root):
				city_roots.append(root)

	# Sort for predictable connection
	city_roots.sort_custom(func(a, b): return a.x < b.x if a.x != b.x else a.y < b.y)

	# Connect each city to the next
	for i in city_roots.size() - 1:
		var from = city_roots[i]
		var to = city_roots[i + 1]
		create_road_path(from, to, regions)

func create_road_path(from: Vector2i, to: Vector2i, regions: Dictionary):
	var pos = from

	# Step 1: Horizontal movement
	while pos.x != to.x:
		pos.x += signi(to.x - pos.x)
		if not regions.has(pos) or regions[pos]["type"] == "structure_empty":
			regions[pos] = {
				"type": "road",
				"meta_data": {},
			}

	# Step 2: Vertical movement
	while pos.y != to.y:
		pos.y += signi(to.y - pos.y)
		if not regions.has(pos) or regions[pos]["type"] == "structure_empty":
			regions[pos] = {
				"type": "road",
				"meta_data": {},
			}

func assign_road_variants():
	var regions = big_map["chunks"]
	for pos in regions:
		var cell = regions[pos]
		if cell["type"] != "road":
			continue

		var directions := ""
		for dir in [Vector2i(0, -1), Vector2i(0, 1), Vector2i(-1, 0), Vector2i(1, 0)]:
			var neighbor_pos = pos + dir
			if not regions.has(neighbor_pos):
				continue

			var neighbor = regions[neighbor_pos]
			if neighbor["type"] in ["road", "city"]:
				if dir == Vector2i(0, -1):
					directions += "n"
				elif dir == Vector2i(0, 1):
					directions += "s"
				elif dir == Vector2i(-1, 0):
					directions += "w"
				elif dir == Vector2i(1, 0):
					directions += "e"

		# Sort the directions alphabetically for consistency
		#directions = directions.split("").sort().join("")
		cell["prefab_id"] = "road_" + directions

# Assign road variant based on connected directions
func get_road_variant(pos: Vector2i, regions: Dictionary) -> String:
	var dirs := {
		"N": Vector2i(0, -1),
		"S": Vector2i(0, 1),
		"E": Vector2i(1, 0),
		"W": Vector2i(-1, 0)
	}
	var connected := []

	for dir in ["N", "S", "E", "W"]:
		var neighbor :Vector2i= pos + dirs[dir]
		if regions.has(neighbor) and regions[neighbor].get("type") == "road":
			connected.append(dir)

	return "road_" + "".join(connected)


# Step 3: Debug print the map to output
func debug_print_map():
	var regions = big_map["chunks"]
	var size = big_map["map_size"]
	print("\n=== MAP DEBUG ===")

	for y in size.y:
		var line := ""
		for x in size.x:
			var pos = Vector2i(x, y)
			if not regions.has(pos):
				#line += ". "
				continue

			var cell = regions[pos]
			match cell.get("type", "empty"):
				"structure_empty": line += ". "
				"road": line += "# "
				"city":
					var city_id = cell.get("meta_data", {}).get("city_id", -1)
					line += str(city_id) + " "
				_: line += "? "
		print(line)

	var l := "\n"
	for i in size.x:
		l += "= "
	l += "\n"
	print(l)


func save_world_save_resource(save_data: Dictionary, save_path: String):
	var save_res := WorldSaveResource.new()
	save_res.map_size = save_data.map_size
	save_res.tile_size = save_data.tile_size
	save_res.chunk_size = save_data.chunk_size
	save_res.chunks = save_data.chunks

	var err := ResourceSaver.save(save_res, save_path, ResourceSaver.FLAG_COMPRESS)
	if err != OK:
		push_error("❌ Failed to save world: " + save_path)
	else:
		print("✅ World saved to: ", save_path)

func save_world_as_json(save_data: Dictionary, save_path: String):
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("❌ Failed to open file for writing: " + save_path)
		return

	# Convert data to JSON string
	var json_string = JSON.stringify(save_data, "\t") # Indented for readability
	file.store_string(json_string)
	file.close()
	print("✅ World saved as JSON to: ", save_path)

func serialize_map_data(data: Dictionary) -> Dictionary:
	var output := {}
	for key in data:
		var val = data[key]
		if val is Vector2i:
			output[str(key)] = [val.x, val.y]
		elif val is Dictionary:
			output[str(key)] = serialize_map_data(val)
		else:
			output[str(key)] = val
	return output


func load_world_from_json(json_path: String) -> Dictionary:
	if not FileAccess.file_exists(json_path):
		push_error("❌ JSON file does not exist: " + json_path)
		return {}

	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("❌ Failed to open file: " + json_path)
		return {}

	var json_string = file.get_as_text()
	file.close()

	var result = JSON.parse_string(json_string)
	if result == null:
		push_error("❌ Failed to parse JSON: " + json_path)
		return {}

	return result

func deserialize_map_data(data: Dictionary) -> Dictionary:
	var output := {}
	for key in data:
		var val = data[key]
		# Attempt to re-interpret list values as Vector2i if valid
		if typeof(val) == TYPE_ARRAY and val.size() == 2 and val[0] is int and val[1] is int:
			output[key] = Vector2i(val[0], val[1])
		elif typeof(val) == TYPE_DICTIONARY:
			output[key] = deserialize_map_data(val)
		else:
			output[key] = val
	return output
