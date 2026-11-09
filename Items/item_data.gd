extends Resource
class_name ItemData


@export var itemName: String = "Item"
@export var icon: Texture2D
@export var worldSpaceTexture: Texture2D
@export var heldScene: PackedScene
@export var weight: float = 1.0
@export var maxStack: int = 1
@export var unique: bool = false
@export var placeScene: PackedScene
@export var placesTiles: bool = false
@export var tileCoords: Vector2i
@export var breaksTiles: bool = false
