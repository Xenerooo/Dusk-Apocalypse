extends Polygon2D


@export var sun_curve : Curve
@export var shadow_curve : Curve

func _process(delta: float) -> void:
	var time : TimeManager = WorldManager.time_manager
	
	var total_minutes: int = time.current_hours * 60 + time.current_minutes   # 0–1439
	var t: float = float(total_minutes) / 1440.0  # normalized (0–1)
	var angle: float = sun_curve.sample(t) * 360
	var length : float = shadow_curve.sample(t) * 100

	material.set("shader_parameter/angle", angle)
	material.set("shader_parameter/max_dist", length)


	
#func _process(delta: float) -> void:
	
