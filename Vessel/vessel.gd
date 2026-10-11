extends RigidBody2D
class_name  Vessel

@onready var hull: TileMapLayer = $Hull
@onready var zone_hull: TileMapLayer = $Zone/ZoneHull
@onready var zone: SubViewport = $Zone
@onready var props: Node2D = $Props

var startY: float
var time: float = 0.0

var last_position: Vector2 # For getting ship Vel, needed maybe for player momentum
var current_velocity:Vector2 = Vector2.ZERO

var collisionPolys: Array[CollisionPolygon2D] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("vessels")
	zone_hull.tile_map_data = hull.tile_map_data # Copies every tile from the visible Hull into the ZoneHull
	startY = position.y
	last_position = global_position
	
	rebuild_collision()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time += delta
	position.y = startY + sin(time) * 5
	rotation = sin(time*0.75) * 0.1
	
	current_velocity = (global_position - last_position) / delta
	last_position = global_position # End of vel calc

func get_zone_bounds() -> Rect2:
	var tile_rect := zone_hull.get_used_rect() # smallest rect that fits tiles
	var tile_size := Vector2(zone_hull.tile_set.tile_size)
	var bounds := Rect2(Vector2(tile_rect.position) * tile_size, Vector2(tile_rect.size) * tile_size)
	return bounds.grow_individual(8, 64, 8, 8) # Need to find way to auto gen this bit

func rebuild_collision() -> void:
	for poly in collisionPolys:
		poly.queue_free()
	collisionPolys.clear()
	
	for cell in hull.get_used_cells():
		var tileData := hull.get_cell_tile_data(cell)
		if tileData == null:
			continue
		for i in tileData.get_collision_polygons_count(0):
			var poly := CollisionPolygon2D.new()
			poly.polygon = tileData.get_collision_polygon_points(0, i)
			poly.one_way_collision = tileData.is_collision_polygon_one_way(0, i)
			poly.position = hull.map_to_local(cell)
			add_child(poly)
			collisionPolys.append(poly)
