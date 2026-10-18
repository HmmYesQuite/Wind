extends RigidBody2D
class_name  Vessel

@onready var hull: TileMapLayer = $Hull
@onready var zone_hull: TileMapLayer = $Zone/ZoneHull
@onready var zone: SubViewport = $Zone
@onready var props: Node2D = $Props
@export var hoverStrength: float = 20.0
@export var hoverDamping: float = 6.0
@export var rightingStrength: float = 8.0
@export var rightingDamping: float = 3.0
@export var bobHeight: float = 5.0
@export var bobSpeed: float = 1.0

@export var windDrag: float = 1.0

@export var massPerTile: float = 0.10

var targetY: float
var time: float = 0.0

@export var proxyRange: float = 200.0
var proxies: Dictionary = {}

var current_velocity:Vector2 = Vector2.ZERO

var collisionPolys: Array[CollisionPolygon2D] = []

var propCount: int = 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("vessels")
	zone_hull.tile_set = hull.tile_set
	zone_hull.tile_map_data = hull.tile_map_data # Copies every tile from the visible Hull into the ZoneHull
	targetY = global_position.y
	
	rebuild_collision()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	update_proxies()
	
	

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
	mass = maxf(1.0, collisionPolys.size() * massPerTile)


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	var dt := state.step
	time += dt
	var vel := state.linear_velocity
	
	
	var bobTarget := targetY + sin(time * bobSpeed) * bobHeight
	var heightError := bobTarget - state.transform.origin.y
	vel.y += (heightError * hoverStrength - vel.y * hoverDamping) * dt
	vel -= state.total_gravity * dt
	
	var wind: Vector2 = Wind.get_wind_at(state.transform.origin)
	vel.x += (wind.x -vel.x) * windDrag *dt
	
	state.linear_velocity = vel
	var tilt := state.transform.get_rotation()
	state.angular_velocity += (-tilt * rightingStrength - state.angular_velocity * rightingDamping) * dt
	
	current_velocity = state.linear_velocity
	
func make_proxy(source: Vessel) -> AnimatableBody2D:
	var proxy := AnimatableBody2D.new()
	proxy.sync_to_physics = false
	proxy.collision_layer = 2
	proxy.collision_mask = 0
	proxy.set_meta("source", source)
	for poly in source.collisionPolys:
		proxy.add_child(poly.duplicate())
	proxy.transform = global_transform.affine_inverse() * source.global_transform
	zone.add_child(proxy)
	return proxy
	
func clear_proxies() -> void:
	for proxy in proxies.values():
		proxy.queue_free()
	proxies.clear()
	

func update_proxies() -> void:
	if propCount == 0:
		if not proxies.is_empty():
			clear_proxies()
		return
	
	for other: Vessel in get_tree().get_nodes_in_group("vessels"):
		if other == self:
			continue
		var inRange := global_position.distance_to(other.global_position) < proxyRange
		if inRange and not proxies.has(other):
			proxies[other] = make_proxy(other)
		elif not inRange and proxies.has(other):
			proxies[other].queue_free()
			proxies.erase(other)
	
	var toLocal := global_transform.affine_inverse()
	for other in proxies:
		proxies[other].transform = toLocal * other.global_transform
