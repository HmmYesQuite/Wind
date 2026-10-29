extends CanvasLayer

const SLOT_SCENE := preload("res://UI/item_slot.tscn")

@onready var slotsBox: HBoxContainer = $Slots


var selectedStyle: StyleBoxFlat


func _ready() -> void:
	
	slotsBox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	slotsBox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	
	selectedStyle = make_style(Color(1, 0.85, 0.3), 1)
	Hotbar.changed.connect(rebuild)
	rebuild()


func make_style(borderColor: Color, borderWidth: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0.45)
	style.border_color = borderColor
	style.set_border_width_all(borderWidth)
	return style
	

func rebuild() -> void:
	for child in slotsBox.get_children():
		child.queue_free()
	for i in Hotbar.container.slots.size():
		
		var slot: ItemSlot = SLOT_SCENE.instantiate()
		slot.size_flags_vertical = Control.SIZE_SHRINK_END
		
		if i == Hotbar.selectedIndex:
			slot.add_theme_stylebox_override("panel", selectedStyle)
		slotsBox.add_child(slot)
		slot.show_item(Hotbar.container.slots[i], Hotbar.container.counts[i])
		
		
