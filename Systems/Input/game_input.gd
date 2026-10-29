extends Node

var blocked := false

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
