extends CanvasLayer
class_name BlueprintUI

@onready var closeButton: Button = $PanelContainer/VBoxContainer/Close

@export var prefabs: Array[ShipPrefab] = []
@onready var prefabList: VBoxContainer = %PrefabList

@export var panSpeed: float = 60.0

const SLOT_SCENE := preload("res://UI/item_slot.tscn")

var placing: ShipPrefab = null
var preview: TileMapLayer = null
@onready var camera: CameraFollow = get_viewport().get_camera_2d()

func _ready() -> void:
	add_to_group("blueprint_ui")
	visible = false
	closeButton.pressed.connect(close)

func open() -> void:
	visible = true
	GameInput.blocked = true
	fill_prefabs()

func close() -> void:
	visible = false
	GameInput.blocked = false

func _exit_tree() -> void:
	GameInput.blocked = false

func fill_prefabs() -> void:
	for child in prefabList.get_children():
		child.queue_free()
	for prefab in prefabs:
		
		
		var row := HBoxContainer.new()
		prefabList.add_child(row)
		
		
		var nameLabel := Label.new()
		nameLabel.text = prefab.prefabName
		row.add_child(nameLabel)
		
		
		for item in prefab.cost:
			var needed := prefab.cost[item]
			var slot :=  make_icon(row, item, needed)
			slot.countLabel.text = "%d/%d" % [Inventory.count_of(item), needed]
		
		var button := Button.new()
		button.text = "Build"
		button.disabled = not can_afford(prefab)
		
		button.focus_mode = Control.FOCUS_NONE
		button.pressed.connect(choose.bind(prefab))
		row.add_child(button)


func make_icon(row: HBoxContainer, item: ItemData, count: int) -> ItemSlot:
	var slot: ItemSlot = SLOT_SCENE.instantiate()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(slot)
	slot.show_item(item, count)
	return slot

func can_afford(prefab: ShipPrefab) -> bool:
	for item in prefab.cost:
		if Inventory.count_of(item) < prefab.cost[item]:
			return false
	return true

func choose(prefab: ShipPrefab) -> void:
	visible = false
	placing = prefab
	var ship := prefab.scene.instantiate()
	var buildLayer: TileMapLayer = ship.get_node("Hull")
	preview = TileMapLayer.new()
	preview.tile_set = buildLayer.tile_set
	preview.tile_map_data = buildLayer.tile_map_data
	preview.modulate = Color(1, 1, 1, 0.5)
	preview.collision_enabled = false
	preview.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	get_tree().current_scene.add_child(preview)
	ship.free()
	camera.targetZoom = Vector2(0.5,0.5)
	
	


func _process(delta: float) -> void:
	if placing == null:
		return # skip if not placing
	
	
	camera.targetOffset.x += Input.get_axis("move_left", "move_right") * panSpeed * delta
	
	
	
	preview.global_position = preview.get_global_mouse_position()
	var placeable := can_place()
	if placeable:
		preview.modulate = Color(1, 1, 1, 0.5)
	else:
		preview.modulate = Color(1, 0, 0, 0.5)
	if Input.is_action_just_pressed("use_item") and placeable:
		place()
	elif Input.is_action_just_pressed("use_item_alt"):
		stop_placing()


func place() -> void:
	var vessel: Vessel = placing.scene.instantiate()
	vessel.position = preview.global_position
	get_tree().current_scene.add_child(vessel, true)
	vessel.reset_physics_interpolation()
	
	for item in placing.cost:
		Inventory.remove_item(item, placing.cost[item])
	
	stop_placing()
	SaveManager.request_save()

func stop_placing() -> void:
	
	camera.targetOffset = Vector2.ZERO
	placing = null
	preview.queue_free()
	preview = null
	GameInput.blocked = false
	camera.targetZoom = Vector2(1,1)

func world_rect(layer: TileMapLayer) -> Rect2:
	var cells := layer.get_used_rect()
	var tileSize := Vector2(layer.tile_set.tile_size)
	return Rect2(layer.global_position + Vector2(cells.position) * tileSize, Vector2(cells.size) * tileSize)
	

func can_place() -> bool:
	var previewRect := world_rect(preview).grow(8)
	for vessel: Vessel in get_tree().get_nodes_in_group("vessels"):
		if previewRect.intersects(world_rect(vessel.buildLayer)):
			return false
	return true
