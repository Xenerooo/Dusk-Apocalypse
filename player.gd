extends CharacterBody2D
class_name Player

@export var SPEED := 12000.0
@onready var movement: Node = $Movement

func _ready() -> void:
	movement.player = self
