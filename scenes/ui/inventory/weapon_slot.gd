extends EquipmentSlot

func setup():
	super()

func refresh(equipment:Dictionary):
	#print(self, equipment)
	super(equipment)
	label.hide()
	grid.hide()
