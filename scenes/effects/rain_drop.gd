# RainDropEffect.gd
# Displays a rain ripple effect fixed to the ground, rendered behind the player.
# The effect stays aligned with the camera view but gives the illusion of being part of the world.
# Author: Seed (Kode Game Studio)

extends ColorRect

@export var cam: Camera2D        # Reference to the main camera
@export var player: Node2D       # Reference to the player (used to auto-find the camera and z-index placement)

func _ready() -> void:
	player = GameSession.local_player
	# If no camera is assigned, try to find one inside the player node
	if not cam and player:
		cam = player.find_child("Camera2D", true, false) as Camera2D
	
	# Make sure the rain effect is drawn behind the player
	if player:
		z_index = player.z_index - 1

	# Ensure the ColorRect anchors do not stretch unexpectedly
	anchors_preset = PRESET_TOP_LEFT

func _process(delta: float) -> void:
	if not cam:
		return

	# Get the size of the current viewport in pixels
	var view_size: Vector2 = get_viewport_rect().size

	# Position this ColorRect so its top-left corner matches the camera's top-left view
	global_position = cam.get_screen_center_position() - view_size * 0.5
	size = view_size

	# Send world position of the top-left corner and size to the shader
	var mat := material as ShaderMaterial
	if mat:
		mat.set_shader_parameter("world_top_left", global_position)
		mat.set_shader_parameter("rect_size_world", view_size)
