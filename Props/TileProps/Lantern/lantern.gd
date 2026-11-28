extends Node2D
class_name Lantern

@onready var interactable: Interactable = $Interactable
@onready var sprite: Sprite2D = $Sprite2D
@onready var light: PointLight2D = $PointLight2D

@export_storage var lit: bool = false: set = set_lit


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("lanterns")
	interactable.interacted.connect(_on_interacted)
	set_lit(lit)


func _on_interacted(interactor: Node) -> void:
	set_lit(not lit)
	SaveManager.request_save()

func set_lit(value: bool) -> void:
	lit = value
	if not is_node_ready():
		return
	
	if lit:
		sprite.region_rect = Rect2(0, 16, 8, 8)
		light.enabled = true
	else:
		sprite.region_rect = Rect2(0, 24, 8, 8)
		light.enabled = false
