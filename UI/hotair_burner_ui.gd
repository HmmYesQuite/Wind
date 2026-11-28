extends CanvasLayer
class_name HotairBurnerUI

@onready var increaseButton: TextureButton = $Panel/Increase
@onready var decreaseButton: TextureButton = $Panel/Decrease
@onready var targetMarker: TextureRect = $Panel/TargetMarker
@onready var liftMarker: TextureRect = $Panel/LiftMarker
@onready var loadedSlot: ItemSlot = $Panel/Loaded
@onready var fuelList: VBoxContainer = $Panel/FuelList

#prop dont need to be exports
@export var barTop := 24.0
@export var barBottom := 56.0 

const SLOT_SCENE := preload("res://UI/item_slot.tscn")

@export var liftStep := 0.25

#need to only change the lift of each vessel. Eventually setup a max and min lift.

var burner: hotair_burner

func _ready() -> void:
	add_to_group("hotair_burner_ui")
	visible = false
	increaseButton.pressed.connect(increase_lift)
	decreaseButton.pressed.connect(decrease_lift)
	Inventory.changed.connect(rebuild_fuel)
	Hotbar.changed.connect(rebuild_fuel) #if inventory and hotbar ever get merged remove this
	

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("pause"):
		close()
		get_viewport().set_input_as_handled()

func _process(delta: float) -> void:
	if burner == null:
		return
	place_marker(targetMarker, burner.targetLift)
	place_marker(liftMarker, burner.currentLift)
	loadedSlot.show_item(burner.fuelItem, burner.fuelCount)

func place_marker(marker: TextureRect, value: float) -> void:
	var y := remap(value, 0.0, 2.0, barBottom, barTop)
	marker.position.y = roundf(y - marker.size.y / 2.0)


func get_fuel_types() -> Array[ItemData]:
	
	var fuelTypes: Array[ItemData] = []
	for container in Inventory.all_containers():
		for item in container.slots:
			if item != null and item.burnTime > 0 and not fuelTypes.has(item): #note to self: Order matters in if statments with repeated ands
				fuelTypes.append(item)
	return fuelTypes

func open(target: hotair_burner) -> void:
	burner = target
	visible = true
	
	GameInput.blocked = true
	rebuild_fuel()


func rebuild_fuel() -> void:
	if not visible:
		return
	
	for child in fuelList.get_children():
		child.queue_free()
		
	for item in get_fuel_types():
		var slot: ItemSlot = SLOT_SCENE.instantiate()
		
		slot.custom_minimum_size = Vector2(16, 16) #in case I change the texture size
		fuelList.add_child(slot)
		slot.show_item(item, Inventory.count_of(item))
		slot.clicked.connect(add_fuel.bind(item))


func add_fuel(item: ItemData) -> void:
	if burner == null:
		return
	
	if burner.add_fuel(item):
		Inventory.remove_item(item, 1)
		SaveManager.request_save()

func increase_lift() -> void:
	burner.change_target(liftStep)
func decrease_lift() -> void:
	burner.change_target(-liftStep)


func close() -> void:
	burner = null
	visible = false
	GameInput.blocked = false
