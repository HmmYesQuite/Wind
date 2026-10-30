extends Panel
class_name ItemSlot

@onready var icon: TextureRect = $Icon
@onready var countLabel: Label = $Count

var container: ItemContainer
var index := 0

func show_item(item: ItemData, count: int) -> void:
	if item != null:
		icon.texture = item.icon
	else:
		icon.texture = null
		
	if count > 1:
		countLabel.text = str(count)
	else:
		countLabel.text = ""
	
	

func _gui_input(event: InputEvent) -> void:
	if not GameInput.blocked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		
		if not container.merge(index, Inventory.cursor, 0):
			container.swap(index, Inventory.cursor, 0)
