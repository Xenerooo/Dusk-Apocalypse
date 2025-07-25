extends Resource
class_name BiomeClassifier

@export var biome_thresholds: Dictionary = {
	"forest": { "temp_min": 0.2, "moist_min": 0.5 },
	"dry_plains": { "temp_min": 0.5, "moist_max": 0.3 },
	"plains": { "temp_min": -1.0, "moist_min": 0.3 },
	#"wasteland": { "temp_max": 0.2, "moist_max": 0.3 },
}

func classify(temp: float, moist: float) -> String:
	for biome_name in biome_thresholds.keys():
		var b = biome_thresholds[biome_name]
		if b.has("temp_min") and temp < b.temp_min:
			continue
		if b.has("temp_max") and temp > b.temp_max:
			continue
		if b.has("moist_min") and moist < b.moist_min:
			continue
		if b.has("moist_max") and moist > b.moist_max:
			continue
		return biome_name
	return "default"
