extends Resource
class_name ShipPrefab

@export var prefabName: String = "Ship"
@export var scene: PackedScene
@export var cost: Dictionary[ItemData, int] = {}
