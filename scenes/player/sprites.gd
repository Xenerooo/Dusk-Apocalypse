extends Node2D
@export var human_sprite : Sprite2D
@export var part_body : Sprite2D
@export var part_head : Sprite2D
@export var part_vest : Sprite2D
@export var part_bag : Sprite2D

func _on_part_bottom_frame_changed() -> void:
	pass # Replace with function body.

func _on_part_top_frame_changed() -> void:
	pass # Replace with function body.

func _on_body_frame_changed() -> void:
	part_body.frame = human_sprite.frame
	part_head.frame = human_sprite.frame
	part_vest.frame = human_sprite.frame
	part_bag.frame = human_sprite.frame
