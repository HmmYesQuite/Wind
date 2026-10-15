extends Node2D

@onready var interactable: Interactable = $Interactable
@onready var sprite: Sprite2D = $Sprite2D

var lit: bool = true


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	interactable.interacted.connect(_on_interacted)
	


func _on_interacted(interactor: Node) -> void:
	lit = not lit
	if lit:
		sprite.modulate = Color.WHITE
	else:
		sprite.modulate = Color(0.3, 0.3, 0.3)
