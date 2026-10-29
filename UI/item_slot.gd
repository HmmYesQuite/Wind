extends Panel
class_name ItemSlot

@onready var icon: TextureRect = $Icon
@onready var countLabel: Label = $Count


func show_item(item: ItemData, count: int) -> void:
	if item != null:
		icon.texture = item.icon
		if count > 1:
			countLabel.text = str(count)
		else:
			countLabel.text = ""
	else:
		icon.texture = null
	
