extends Node2D
class_name Placer


@export var gridRadius: int = 3
@onready var ghost: Sprite2D = $Ghost
@export var placeRange: int = 4
@export var placeDelay: float = 0.05


var hull: TileMapLayer
var mouseCell: Vector2i #2i is integer
var item: ItemData
var size: Vector2i
var topLeft: Vector2i
var canPlace: bool = false
var vessel: Vessel
var placeTimer: float = 0.0
var player: DynamicProp

func _ready() -> void:
	top_level = true
	item = Hotbar.get_selected_item()
	ghost.texture = item.worldSpaceTexture


func _physics_process(delta: float) -> void:
	player = get_tree().get_first_node_in_group("player")
	vessel = player.vessel
	if vessel == null:
		visible = false
		return
	visible = true
	hull = vessel.hull
	global_transform = hull.global_transform
	mouseCell = hull.local_to_map(hull.to_local(GameInput.get_mouse_position(self)))
	
	var tileSize := hull.tile_set.tile_size
	size = Vector2i(ghost.texture.get_size()) / tileSize
	topLeft = Vector2i(mouseCell.x - (size.x / 2), mouseCell.y - size.y + 1)
	ghost.position = Vector2(topLeft * tileSize)
	
	canPlace = can_place()
	if canPlace:
		ghost.modulate = Color(1,1,1,0.5)
	else:
		ghost.modulate = Color(1,0.3,0.3,0.5)
	
	placeTimer -= delta
	if not GameInput.is_action_pressed("use_item"):
		placeTimer = 0
	if canPlace and GameInput.is_action_pressed("use_item") and placeTimer <= 0:
		place()
		placeTimer = placeDelay
	
	
	queue_redraw()


func _draw() -> void:
	if hull == null:
		return
	var tileSize := Vector2(hull.tile_set.tile_size)
	var left := mouseCell.x - gridRadius
	var right := mouseCell.x + gridRadius + 1
	var top := mouseCell.y - gridRadius
	var bottom := mouseCell.y + gridRadius + 1
	for x in range(left, right + 1):
		draw_line(Vector2(x, top) * tileSize, Vector2(x, bottom) * tileSize, Color(1,1,1, 0.25), 0.5)
	for y in range(top, bottom + 1):
		draw_line(Vector2(left, y) * tileSize, Vector2(right, y) * tileSize, Color(1,1,1, 0.25), 0.5)

func can_place() -> bool:
	
	var playerCell := hull.local_to_map(hull.to_local(get_parent().global_position))
	if absi(mouseCell.x - playerCell.x) > placeRange or absi(mouseCell.y - playerCell.y) > placeRange:
		return false
	
	
	for x in range(topLeft.x, topLeft.x + size.x):
		for y in range(topLeft.y, topLeft.y + size.y):
			var cell := Vector2i(x, y)
			if hull.get_cell_source_id(cell) != -1 or vessel.placed.has(cell):
				return false
	
	if not item.placesTiles:
		var belowY := mouseCell.y + 1
		for x in range(topLeft.x, topLeft.x + size.x):
			var data := hull.get_cell_tile_data(Vector2i(x, belowY))
			if data == null or data.get_collision_polygons_count(0) == 0:
				return false
	
	if item.placesTiles:
		var body: CollisionShape2D = player.get_node("CollisionShape2D")
		var playerRect: Rect2 = body.shape.get_rect()
		playerRect.position += player.position + body.position
		var tileSize := hull.tile_set.tile_size
		var tileRect := Rect2(Vector2(mouseCell * tileSize), Vector2(tileSize))
		if playerRect.intersects(tileRect):
			return false
		for dx in range(-1,2):
			for dy in range(-1, 2):
				if dx == 0 and dy == 0:
					continue #skip center
				var data := hull.get_cell_tile_data(mouseCell + Vector2i(dx, dy))
				if data != null and data.get_collision_polygons_count(0) > 0:
					return true
		return false
	
	return true


func place() -> void:
	
	if item.placesTiles:
		vessel.add_tile(mouseCell, item.tileCoords)
	else:
		vessel.place_object(item, topLeft)
	
	Inventory.remove_item(item, 1)
	SaveManager.request_save()
