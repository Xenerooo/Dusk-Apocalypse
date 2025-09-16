extends InteractiveTouchscreenButton

@export var melee_texture :Texture
@export var weapon1_texture :Texture
@export var weapon2_texture :Texture

func update_btn(index:int):
	match index :
		0:
			texture_normal = melee_texture
		1:
			texture_normal = weapon1_texture
		2:
			texture_normal = weapon2_texture
