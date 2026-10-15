extends Node2D
class_name Interactor

@export var interactRange: float = 16.0

var focused: Interactable = null



# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var closest: Interactable = null
	var closestDistance := interactRange
	for node in get_tree().get_nodes_in_group("interactables"):
		var interactable := node as Interactable
		if interactable == null or not interactable.enabled:
			continue
		var distance := global_position.distance_to(interactable.global_position)
		if distance <= closestDistance:
			closest = interactable
			closestDistance = distance
	
	if closest != focused:
		if focused != null and is_instance_valid(focused):
			focused.set_focused(false)
		focused = closest
		if focused != null:
			focused.set_focused(true)


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact") and focused != null:
		focused.interact(self)
		get_viewport().set_input_as_handled()
