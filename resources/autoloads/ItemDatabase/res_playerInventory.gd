extends Resource
class_name PlayerInventory

enum INVENTORY_PART {
	HEAD,
	BODY,
	VEST,
	BAG,
	PRIMARY,
	SECONDARY,
	MELEE,
	VICINITY
}

enum INVENTORY_TYPE {
	PLAYER
}

var player_id :String = ""
var inventory := {
	INVENTORY_PART.HEAD: null,
	INVENTORY_PART.BODY: null,
	INVENTORY_PART.VEST: null,
	INVENTORY_PART.BAG: null,
	INVENTORY_PART.PRIMARY : null,
	INVENTORY_PART.SECONDARY: null,
	INVENTORY_PART.MELEE: null
}

var item_node_vicinity:= []
var vicinity := []

var health :float
var hunger: float
var thirst: float

func as_dict():
	var data :Dictionary = {}
	for i in inventory.keys():
		data[i] = null
		if inventory[i] != null :
			data[i] = inventory[i].to_dict()

	data[INVENTORY_PART.VICINITY] = []
	for i in vicinity :
		data[INVENTORY_PART.VICINITY].append(i.to_dict())
	
	return data

		
