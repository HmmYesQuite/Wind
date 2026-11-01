extends Node

var blocked := false
var lastMouse := Vector2.ZERO


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS


func is_action_pressed(action: StringName) -> bool:
	return not blocked and Input.is_action_pressed(action)
func is_action_just_pressed(action: StringName) -> bool:
	return not blocked and Input.is_action_just_pressed(action)
func get_axis(negative, positive) -> float:
	if blocked:
		return 0
	else:
		return Input.get_axis(negative, positive)
func is_key_pressed(key: Key) -> bool:
	return not blocked and Input.is_key_pressed(key)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("fullscreen"):
		if DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)

func get_mouse_position(node: CanvasItem) -> Vector2:
	if not blocked:
		lastMouse = node.get_global_mouse_position()
	return lastMouse
