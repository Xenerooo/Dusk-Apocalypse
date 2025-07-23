extends Resource
class_name MapStructureResource

@export var chunk_id: Vector2i
@export var layers: Dictionary  # { "LayerName": { "positions": ..., "source_ids": ..., "atlas_coords": ... } }
