extends CanvasLayer

@export var slotSize: int = 14

@onready var slotsBox: HBoxContainer = $Slots

var normalStyle: StyleBoxFlat
var selectedStyle: StyleBoxFlat


func _ready() -> void:
	
	slotsBox.grow_horizontal = Control.GROW_DIRECTION_BOTH
	slotsBox.grow_vertical = Control.GROW_DIRECTION_BEGIN
	
	normalStyle = make_style(Color(1, 1, 1, 0.2), 1)
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
	for i in Hotbar.slots.size():
		
		
		var slot := Panel.new()
		var count := Hotbar.counts[i]
		
		
		slot.custom_minimum_size = Vector2(slotSize, slotSize)
		slot.size_flags_vertical = Control.SIZE_SHRINK_END
		var style := selectedStyle if i == Hotbar.selectedIndex else normalStyle
		slot.add_theme_stylebox_override("panel", style)
		
		var item: ItemData = Hotbar.slots[i]
		if item != null and item.icon != null:
			var icon := TextureRect.new()
			icon.texture = item.icon
			icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 2)
			slot.add_child(icon)
		
		if count > 1:
			var itemCount := Label.new()
			itemCount.text = str(count)
			itemCount.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT, Control.PRESET_MODE_KEEP_SIZE, 2)
			itemCount.add_theme_font_size_override("font_size", 4)
			itemCount.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			itemCount.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
			slot.add_child(itemCount)
		
		slotsBox.add_child(slot)
