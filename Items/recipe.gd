extends Resource
class_name Recipe

@export var result: ItemData
@export var resultCount: int = 1
@export var ingredients: Dictionary[ItemData, int] = {}
