# TileChunkResource.gd
extends Resource
class_name OldMapStructureResource


@export var chunk_id: Vector2i
@export var layer_names: PackedStringArray
@export var layer_positions: Array[PackedVector2Array]
@export var layer_source_ids: Array[PackedInt32Array]
@export var layer_atlas_coords: Array[PackedVector2Array]
