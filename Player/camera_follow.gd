extends Camera2D

@export var target: Node2D

@export var zoomStep: float = 1.1
@export var minZoom: float = 0.25
@export var maxZoom: float = 4.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	global_position = target.global_position


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom *= zoomStep
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom /= zoomStep
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			zoom = Vector2.ONE
		zoom =zoom.clamp(Vector2(minZoom, minZoom), Vector2(maxZoom, maxZoom))
