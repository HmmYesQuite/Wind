extends Node2D
class_name Interactable

signal interacted(interactor: Node)

@export var promptText: String = "Use"
@export var enabled: bool = true

var prompt := Label.new()

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("interactables")
	prompt.text = "[E] " + promptText
	prompt.add_theme_font_size_override("font_size", 8)
	prompt.horizontal_alignment =HORIZONTAL_ALIGNMENT_CENTER
	prompt.size = Vector2(48, 10)
	prompt.position = Vector2(-24, -18)
	prompt.z_index = 10
	prompt.visible = false
	add_child(prompt)

func set_focused(isFocused: bool) -> void:
	prompt.visible = isFocused

func interact(interactor: Node) -> void:
	if enabled:
		interacted.emit(interactor)
