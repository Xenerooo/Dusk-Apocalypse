# WorldSaveResource.gd
extends Resource
class_name WorldSaveResource

@export var tile_size: int
@export var chunk_size: int
@export var chunks: Dictionary  # key: Vector2i (chunk_id), value: Dictionary with prefab_id and optional overrides
