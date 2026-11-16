extends Node2D


@export var maxRopeLength: float = 64.0

var item: ItemData
var hoverVessel: Vessel = null
var hoverCell: Vector2i
var firstVessel: Vessel = null
var firstCell: Vector2i
#first is for the vessel the player is currently on (or the one they clicked first)
#hover is vice versa


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	top_level = true
	item = Hotbar.get_selected_item()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	
	find_cell(GameInput.get_mouse_position(self))
	
	if GameInput.is_action_just_pressed("use_item") and hoverVessel != null:
		if firstVessel == null:
			firstVessel = hoverVessel
			firstCell = hoverCell
		elif hoverVessel != firstVessel and in_range():
			tie()
	
	elif GameInput.is_action_just_pressed("use_item_alt"):
		firstVessel = null
	
	queue_redraw()

func find_cell(mouse: Vector2) -> void:
	hoverVessel = null
	for vessel: Vessel in get_tree().get_nodes_in_group("vessels"):
		var cell := vessel.hull.local_to_map(vessel.hull.to_local(mouse))
		if vessel.hull.get_cell_source_id(cell) != -1:
			hoverVessel = vessel
			hoverCell = cell
			return

func anchor_point(vessel: Vessel, cell: Vector2i) -> Vector2:
	return vessel.to_global(vessel.hull.map_to_local(cell))


func in_range() -> bool:
	return anchor_point(firstVessel, firstCell).distance_to(anchor_point(hoverVessel, hoverCell)) <= maxRopeLength


func tie() -> void:
	var rope: Rope = item.placeScene.instantiate()
	rope.item = item
	# get the two vessels setup using a and b points
	rope.vesselA = firstVessel
	rope.tileA = firstCell
	rope.vesselB = hoverVessel
	rope.tileB = hoverCell
	get_tree().current_scene.add_child(rope)
	
	Inventory.remove_item(item, 1)
	firstVessel = null
	SaveManager.request_save()

func _draw() -> void:
	if firstVessel == null:
		return
	#skip if no vessel bc that would need to be rendered
	
	var start := anchor_point(firstVessel, firstCell)
	var mouse := GameInput.get_mouse_position(self)
	var color := Color.WHITE
	if start.distance_to(mouse) > maxRopeLength:
		color = Color.RED
	#might set up more universal way of showing a thing cant be placed/ attached
	
	draw_line(start, mouse, color, 1.0)
