extends CanvasLayer

const SLOT_SCENE := preload("res://UI/item_slot.tscn")
@onready var bar: TextureRect = $Bar
@onready var slotsBox: HBoxContainer = $Bar/Slots
@onready var selector: TextureRect= $Bar/Selector

@export var visibleTime := 4.0
@export var fadeOutSpeed := 0.5
@export var fadeInSpeed := 4.0

@export var inventoryUi: CanvasLayer

var idleTime: float

func _ready() -> void:
	
	Hotbar.changed.connect(rebuild)
	rebuild()

func rebuild() -> void:
	wake()
	for child in slotsBox.get_children():
		child.queue_free()
	for i in Hotbar.container.slots.size():
		
		var slot: ItemSlot = SLOT_SCENE.instantiate()
		slot.size_flags_vertical = Control.SIZE_SHRINK_END
		
		
		slot.custom_minimum_size = Vector2(16, 16)
		slot.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
		
		slotsBox.add_child(slot)
		slot.container = Hotbar.container
		slot.index = i
		slot.show_item(Hotbar.container.slots[i], Hotbar.container.counts[i])
		
	selector.position = Vector2(16 + 16 * Hotbar.selectedIndex, 16)


func _process(delta: float) -> void:
	visible = not GameInput.blocked or inventoryUi.visible
	idleTime += delta
	if GameInput.blocked:
		wake()
	var targetAlpha := 1.0 if visibleTime > idleTime else 0.0
	var speed := fadeInSpeed if targetAlpha == 1.0 else fadeOutSpeed
	bar.modulate.a = move_toward(bar.modulate.a, targetAlpha, speed * delta)

func wake() -> void:
	idleTime = 0
