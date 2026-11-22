extends Resource
class_name CliffPiece


@export var pattern: TileMapPattern
@export var topType: StringName = &"rock"
@export var bottomType: StringName = &"rock"
@export var pickWeight: float = 1.0
@export var offset: Vector2i = Vector2i.ZERO
@export var centerTile: bool = false
