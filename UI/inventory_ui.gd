extends CanvasLayer

const SLOT_SCENE := preload("res://UI/item_slot.tscn")

@onready var body: Control = %Body
@onready var partName: Label = %PartName
@onready var slotGrid: GridContainer = %Slots

var shownPart := ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	
	for area in body.get_children():
		var areaName := String(area.name)
		if Inventory.pockets.has(areaName):
			area.mouse_entered.connect(show_part.bind(areaName))
	
	Inventory.changed.connect(refresh)

func show_part(part: String) -> void:
	shownPart = part
	refresh()

func refresh() -> void:
	for child in slotGrid.get_children():
		child.queue_free()
	if shownPart == "":
		return
	
	partName.text = shownPart
	var container := Inventory.pockets[shownPart]
	for i in container.slots.size():
		var slot: ItemSlot = SLOT_SCENE.instantiate()
		
		slotGrid.add_child(slot)
		slot.show_item(container.slots[i], container.counts[i])
		

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("inventory"):
		
		
		
		visible = not visible
		
		
		GameInput.blocked = visible
		
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	GameInput.blocked = false
