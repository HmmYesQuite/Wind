extends Node2D
class_name hotair_burner

@onready var interactable: Interactable = $Interactable

var vessel: Vessel

func _ready() -> void:
	vessel = get_vessel()
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	if vessel == null:
		return
	#incase placed on land or smth
	var ui: HotairBurnerUI = get_tree().get_first_node_in_group("hotair_burner_ui")
	ui.open(vessel)

func get_vessel() -> Vessel:
	var search_vessel := get_parent()
	while search_vessel != null:
		if search_vessel is Vessel:
			return search_vessel
		search_vessel = search_vessel.get_parent()
	return null
