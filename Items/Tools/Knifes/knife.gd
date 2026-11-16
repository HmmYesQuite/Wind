extends Node2D



@export var cutDistance: float = 4.0

var hoverRope: Rope = null

func _process(delta: float) -> void:
	var mouse := GameInput.get_mouse_position(self)
	set_hover(find_rope(mouse))
	
	if GameInput.is_action_just_pressed("use_item") and hoverRope != null and Inventory.can_add(hoverRope.item):
		cut()


func find_rope(mouse: Vector2) -> Rope:
	for rope: Rope in get_tree().get_nodes_in_group("ropes"):
		
		var closest := Geometry2D.get_closest_point_to_segment(mouse, rope.get_point_a(), rope.get_point_b())
		if closest.distance_to(mouse) <= cutDistance:
			return rope
	return null #none near mouse

func set_hover(rope: Rope) -> void:
	if is_instance_valid(hoverRope):
		hoverRope.modulate = Color.WHITE
	
	hoverRope = rope
	if hoverRope != null:
		hoverRope.modulate= Color(1, 0.5, 0.5)

func cut() -> void:
	Inventory.add_item(hoverRope.item)
	hoverRope.queue_free()
	hoverRope = null
	SaveManager.request_save()

func _exit_tree() -> void:
	set_hover(null)
