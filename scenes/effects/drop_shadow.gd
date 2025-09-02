extends Polygon2D

var angle: float = 0.0
var speed: float = 60.0 # degrees per second

func _process(delta: float) -> void:
	angle += speed * delta
	if angle >= 360.0:
		angle -= 360.0
	material.set("shader_parameter/angle", angle)
	pass
#func _process(delta: float) -> void:
	
