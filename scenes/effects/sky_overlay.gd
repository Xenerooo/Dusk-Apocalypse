extends CanvasLayer

@export var gradient_texture:GradientTexture1D
@export var light_threshold : Curve
@onready var time : TimeManager= WorldManager.time_manager

@onready var image : Image = Image.create(128, 3, false, Image.FORMAT_RGBAF)
@onready var texture : ImageTexture = ImageTexture.new()
@onready var sky: ColorRect = $Sky

func _physics_process(delta: float) -> void: 
	var camera :Camera2D = get_viewport().get_camera_2d()
	_update_texture(camera)
	var t = Transform2D(0, Vector2())

	var canvas_transform = camera.get_canvas_transform()
	var top_left = (-canvas_transform.origin) #(-canvas_transform.origin / canvas_transform.get_scale())
	t = Transform2D(0, top_left)
	
	sky.material.set_shader_parameter("global_transform", t)
	var value = sin(((time.current_hours * 60) + time.current_minutes) / 1440.0)
	#var value = (sin(time.get_current_hour() - PI / 2.0) + 1.0) / 2.0
	#self.color = gradient_texture.gradient.sample(value)
	sky.material.set_shader_parameter("dark_color", gradient_texture.gradient.sample(value))
	sky.material.set_shader_parameter("light_strength_modifier", light_threshold.sample(value))
	#adjust_cloud()
#func adjust_cloud():
	#$Clouds.material.set_shader_parameter("pos", GameManager.player.global_position)

func _update_texture(camera: Camera2D):
	#var t = Transform2D(0, Vector2.ZERO)
#
	#var canvas_transform = camera.get_canvas_transform()
	#var top_left = (-canvas_transform.origin) #(-canvas_transform.origin / canvas_transform.get_scale())
	#t = Transform2D(0, top_left).affine_inverse()
	
	#print(t)
	# Get all light sources in the level
	var lights = get_tree().get_nodes_in_group("lights")
	# Assign values to the texture
	#image.lock()
	#var c_local : = get
	for i in lights.size():
		var light = lights[i]
		if light is LightSource:
			
			# Store the x and y position in the red and green channels
			# How luminious the light is in the blue channel
			# And the light's radius in the alpha channel
			var light_position = light.global_position #* camera.zoom
			image.set_pixel(i, 0,
			 Color(
					light_position.x,
					light_position.y,
					light.strength,
					light.radius
					)
				)
			# Store the light's color in the 2nd row
			image.set_pixel(i, 1, light.color)
			image.set_pixel(i, 2, Color(camera.zoom.x, 0, 0, 0))
	#image.unlock()
	var txt = texture.create_from_image(image)
		
	sky.material.set_shader_parameter("n_lights", lights.size())
	sky.material.set_shader_parameter("light_data", txt)
