extends Node

signal changed

var slotCount: int = 6
var container := ItemContainer.new(slotCount)
var selectedIndex: int = 0


func _ready() -> void:
	container.changed.connect(changed.emit)
	add_item(preload("res://Items/FishingRod/fishing_rod.tres"))
	
	
	#add_item(preload("res://Items/TEST Food/Apple.tres"))
	
	

func add_item(item: ItemData) -> bool:
	return container.add_item(item)


func _unhandled_input(event: InputEvent) -> void:
	if GameInput.blocked: return
	if event is InputEventKey and event.pressed and not event.echo:
		var index: int = event.keycode - KEY_1
		if index >= 0 and index < mini(slotCount, 9):
			select(index)
			get_viewport().set_input_as_handled()
	
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			
			if selectedIndex == 0:
				select(slotCount - 1)
			else:
				select(selectedIndex - 1)
			get_viewport().set_input_as_handled()
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			
			if selectedIndex + 1 >= slotCount:
				select(0)
			else:
				select(selectedIndex + 1)
			get_viewport().set_input_as_handled()


func select(index: int) -> void:
	if index < 0 or index >= container.slots.size():
		return
	selectedIndex = index
	changed.emit()
	var item := get_selected_item()
	if item != null and item.itemName == "Debug Item":
		print("Debug item selected")


func get_selected_item() -> ItemData:
	return container.slots[selectedIndex]
