extends InteractiveTouchscreenButton

@export var sneak_on :Texture
@export var sneak_off :Texture

func update_btn(index:int):
	match index :
		0:
			texture_normal = sneak_off
		1:
			texture_normal = sneak_on
