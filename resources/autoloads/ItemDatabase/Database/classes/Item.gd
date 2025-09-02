extends Resource
class_name Item

@export  var itemid : String= ""
@export  var name :String= ""
@export  var is_stackable :bool = false
@export_range (0, 50) var max_amount : = 0
enum ItemTypes {consumable, weapon, equipment, material}
@export var item_type :ItemTypes= ItemTypes.material
@export var icon : Texture2D 
@export var description : String = ""
var amount := 0


func to_dict() -> Dictionary :
	var data := {
		"itemid" : itemid,
		"item_stats" : {
			"amount" : amount
		}
	}
	return data
