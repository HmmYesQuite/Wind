extends CanvasLayer

const SLOT_SCENE := preload("res://UI/item_slot.tscn")

@onready var body: Control = %Body
@onready var partName: Label = %PartName
@onready var slotGrid: GridContainer = %Slots

@onready var hotbarRow: HBoxContainer = %HotbarRow
@onready var cursorSlot: ItemSlot = %Cursor
var shownPart := ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	
	for area in body.get_children():
		var areaName := String(area.name)
		if Inventory.pockets.has(areaName):
			area.mouse_entered.connect(show_part.bind(areaName))
	
	Inventory.changed.connect(refresh)
	Hotbar.changed.connect(refresh)
	Inventory.cursor.changed.connect(refresh)
	refresh()
	Inventory.return_cursor()

func show_part(part: String) -> void:
	shownPart = part
	refresh()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		
		
		
		visible = not visible
		if not visible:
			Inventory.return_cursor()
		
		GameInput.blocked = visible
		
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	GameInput.blocked = false
	


func fill_slots(box: Container, container: ItemContainer) -> void:
	for child in box.get_children():
		child.queue_free()
	for i in container.slots.size():
		var slot: ItemSlot = SLOT_SCENE.instantiate()
		box.add_child(slot)
		slot.container = container
		slot.index = i
		slot.show_item(container.slots[i], container.counts[i])

func refresh() -> void:
	fill_slots(hotbarRow, Hotbar.container)
	if shownPart != "":
		partName.text = shownPart
		fill_slots(slotGrid, Inventory.pockets[shownPart])
	
	cursorSlot.show_item(Inventory.cursor.slots[0], Inventory.cursor.counts[0])

func _process(delta: float) -> void:
	cursorSlot.position = cursorSlot.get_global_mouse_position() - cursorSlot.size / 2
