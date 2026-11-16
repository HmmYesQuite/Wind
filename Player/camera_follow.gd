extends Camera2D
class_name CameraFollow

@export var target: Node2D
@export var zoomSpeed: float = 5.0
var targetZoom := Vector2.ONE
var targetOffset := Vector2.ZERO

func _process(delta: float) -> void:
	var t := 1.0 - exp(-zoomSpeed * delta)
	zoom = zoom.lerp(targetZoom, t)
	offset = offset.lerp(targetOffset, t)

func _physics_process(delta: float) -> void:
	global_position = target.global_position
#func _unhandled_input(event: InputEvent) -> void:
	#if event is InputEventMouseButton and event.pressed:
	#	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
	#		zoom *= zoomStep
	#	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
	#		zoom /= zoomStep
	#	elif event.button_index == MOUSE_BUTTON_MIDDLE:
	#		zoom = Vector2.ONE
	#	zoom =zoom.clamp(Vector2(minZoom, minZoom), Vector2(maxZoom, maxZoom))
