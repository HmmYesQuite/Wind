extends Node

signal changed

var slotCount: int = 3
var slots: Array[ItemData] = []
var selectedIndex: int = 0


func _ready() -> void:
	slots.resize(slotCount)
	add_item(preload("res://Items/fishing_rod.tres"))
	add_item(preload("res://Items/debug_item.tres"))
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < mini(slotCount, 9):
			select(index)
			get_viewport().set_input_as_handled()


func add_item(item: ItemData) -> bool:
	for i in slots.size():
		if slots[i] == null:
			slots[i] = item
			changed.emit()
			return true
	return false


func select(index: int) -> void:
	if index < 0 or index >= slots.size():
		return
	selectedIndex = index
	changed.emit()
	var item := get_selected_item()
	if item != null and item.itemName == "Debug Item":
		print("Debug item selected")


func get_selected_item() -> ItemData:
	return slots[selectedIndex]
	
	
	
	
