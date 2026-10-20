extends Node2D

var currentItem: ItemData = null
var held: Node = null


func _ready() -> void:
	Hotbar.changed.connect(refresh)
	refresh()


func refresh() -> void:
	var item := Hotbar.get_selected_item()
	if item == currentItem:
		return
	currentItem = item
	if held != null:
		held.queue_free()
		held = null
	if item != null and item.heldScene != null:
		held = item.heldScene.instantiate()
		add_child(held)
