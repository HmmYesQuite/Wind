extends Node2D
class_name hotair_burner

@onready var interactable: Interactable = $Interactable

var vessel: Vessel
var fuelItem: ItemData
var fuelCount: int = 0
var burnLeft: float = 0.0
var heat: float = 0.0
var targetLift: float = 1.0
var currentLift: float = 1.0

@export var heatSpeed: float = 0.2
@export var liftSpeed: float = 0.5


func _ready() -> void:
	vessel = get_vessel()
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if vessel == null:
		return
	#incase placed on land or smth
	var ui: HotairBurnerUI = get_tree().get_first_node_in_group("hotair_burner_ui")
	ui.open(self)

func get_vessel() -> Vessel:
	var search_vessel := get_parent()
	while search_vessel != null:
		if search_vessel is Vessel:
			return search_vessel
		search_vessel = search_vessel.get_parent()
	return null

func add_fuel(item: ItemData) -> bool:
	if fuelItem == null:
		fuelItem = item
		fuelCount = 1
		return true
	if fuelItem == item and fuelCount < item.maxStack:
		fuelCount += 1
		return true
	return false


func _physics_process(delta: float) -> void:
	
	if vessel == null:
		return
	
	if burnLeft <= 0 and fuelCount > 0 and targetLift > 1.0:
		fuelCount -= 1
		burnLeft = fuelItem.burnTime
		if fuelCount == 0:
			fuelItem = null
	
	var targetHeat := 0.0
	
	if burnLeft > 0:
		burnLeft -= delta
		targetHeat = 1.0
	heat = move_toward(heat, targetHeat, heatSpeed * delta)
	
	var maxLift := 1.0 + heat
	var goal := minf(targetLift, maxLift)
	currentLift = move_toward(currentLift, goal, liftSpeed * delta)
	
	vessel.set_lift_multiplier(currentLift)
	

func change_target(amount: float) -> void:
	targetLift = clampf(targetLift + amount, 0.0, 2.0)

func _exit_tree() -> void:
	if vessel != null:
		vessel.set_lift_multiplier(1.0) # go back to default of 1 if burner is broken
		var ui: HotairBurnerUI = get_tree().get_first_node_in_group("hotair_burner_ui")
		if ui != null and ui.burner == self:
			ui.close()
