extends Resource
class_name InventoryQueue

enum QUEUE_TYPE {
	EQUIP,
	UNEQUIP
}

var inventory_id
var inventory_type :InventoryStatic.INVENTORY_PART= InventoryStatic.INVENTORY_PART.NONE
##IF INVENTORY PART IS MAIN, THE INDEX WILL BE THE INVENTORY PART,
##ELSE THE INDEX IS THE SLOT INSIDE THE INVENTORY PART
var index : int = -1
var item : Item = null
var res_id : int 

func set_queue(_type, _index, _id, _item = null):
	inventory_type = _type
	index = _index
	inventory_id = _id
	item = _item

func reset_queue():
	inventory_id = null
	inventory_type = InventoryStatic.INVENTORY_PART.NONE
	item = null
	index = -1

func is_empty() -> bool:
	return inventory_id == null and index == -1 and inventory_type == InventoryStatic.INVENTORY_PART.NONE

func is_queue_main():
	return index == -1

func same(slot:Array) -> bool:
	return inventory_type == slot[0] and index == slot[1]

func print_att():
	print("\nQueue:\nindex[%s, %s]\nitem: %s" % [inventory_type, index, item])

func as_array()-> Array:
	return [inventory_type, index]
