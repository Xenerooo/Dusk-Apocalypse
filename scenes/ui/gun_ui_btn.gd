extends GridContainer
@export var reload_btn: InteractiveTouchscreenButton 
@export var swap_btn: InteractiveTouchscreenButton
@export var switch_mode_btn: InteractiveTouchscreenButton
@export var sneak_btn: InteractiveTouchscreenButton

func update_sneak_btn(index):
	sneak_btn.update_btn(index)
	

func update_container(index):
	swap_btn.update_btn(index)
	match index:
		0:
			switch_mode_btn.hide()
			reload_btn.hide()
		1,2:
			switch_mode_btn.show()
			reload_btn.show()
