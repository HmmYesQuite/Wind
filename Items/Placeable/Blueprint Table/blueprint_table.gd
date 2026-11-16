extends Node2D
class_name blueprint_table

@onready var interactable: Interactable = $Interactable

func _ready() -> void:
	
	interactable.interacted.connect(_on_interacted)

func _on_interacted(interactor: Node) -> void:
	var ui: BlueprintUI = get_tree().get_first_node_in_group("blueprint_ui")
	ui.open()
