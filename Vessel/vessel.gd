extends RigidBody2D
class_name  Vessel

@onready var buildLayer: HullLayer = $Hull
@onready var zone_hull: TileMapLayer = $Zone/ZoneHull
@onready var zone: SubViewport = $Zone
@onready var props: Node2D = $Props
@export var rightingStrength: float = 8.0
@export var rightingDamping: float = 3.0
@export var windDrag: float = 1.0
@export var massPerTile: float = 0.10

@export var proxyRange: float = 200.0
var proxies: Dictionary = {}

var current_velocity:Vector2 = Vector2.ZERO
var collisionPolys: Array[CollisionPolygon2D] = []
var balloonLift: float = 0.0

var propCount: int = 0

var balloonLiftMultiplier: float = 1.0 # min of 0 for no lift, it just has normal weight
#max of 1 for multiplier of 2. each ballon allready has lift of 2 so make sure to subtract 1 (actual block weight)

var placed: Dictionary[Vector2i, Node2D] = {}
var builtCell: Dictionary[Vector2i, ItemData] = {}

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("vessels")
	add_to_group("persist")
	zone_hull.tile_set = buildLayer.tile_set
	zone_hull.tile_map_data = buildLayer.tile_map_data # Copies every tile from the visible Hull into the ZoneHull
	
	
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
	
	balloonLift = 0
	
	for poly in collisionPolys:
		poly.queue_free()
	collisionPolys.clear()
	
	for cell in buildLayer.get_used_cells():
		var tileData := buildLayer.get_cell_tile_data(cell)
		if tileData == null:
			continue
		
		
		var scaledLift: float = 0.0
		if tileData.get_custom_data("lift") > 0:
			scaledLift = (tileData.get_custom_data("lift") * massPerTile)
			balloonLift += scaledLift
		# scaled lift gets the additional tiles that should be lifted and adds a multiplier
		# on them, then the actuall lift adds back the starting weight + the mult
		
		
		for i in tileData.get_collision_polygons_count(0):
			var poly := CollisionPolygon2D.new()
			poly.polygon = tileData.get_collision_polygon_points(0, i)
			poly.one_way_collision = tileData.is_collision_polygon_one_way(0, i)
			poly.position = buildLayer.map_to_local(cell)
			add_child(poly)
			collisionPolys.append(poly)
	mass = maxf(1.0, collisionPolys.size() * massPerTile)

func set_lift_multiplier(value: float) -> void:
	balloonLiftMultiplier = clampf(value, 0.0 , 2.0)
	


func _integrate_forces(state: PhysicsDirectBodyState2D) -> void:
	
	var dt := state.step
	var vel := state.linear_velocity
	var pos := state.transform.origin
	
	var density: float = Wind.get_air_density_at(pos)
	var lift := balloonLift * density * state.total_gravity.y * balloonLiftMultiplier
	state.apply_central_force(Vector2(0, - lift))
	
	vel.y -= vel.y * Wind.airDrag * dt
	
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


func add_tile(cell: Vector2i, item: ItemData) -> void:
	buildLayer.set_cell(cell, 0, item.tileCoords)
	
	zone_hull.set_cell(cell, 0, item.tileCoords)
	builtCell[cell] = item
	rebuild_collision()
	clear_my_proxies()
	
	


func place_object(item: ItemData, topLeft: Vector2i) -> Node2D:
	var placedThing: Node2D = item.placeScene.instantiate()
	props.add_child(placedThing)
	placedThing.position = Vector2(topLeft * buildLayer.tile_set.tile_size)
	placedThing.reset_physics_interpolation()
	placedThing.set_meta("item", item)
	
	var size := Vector2i(item.worldSpaceTexture.get_size()) / buildLayer.tile_set.tile_size
	for x in range(topLeft.x, topLeft.x + size.x):
		for y in range(topLeft.y, topLeft.y + size.y):
			placed[Vector2i(x, y)] = placedThing
	return placedThing


func to_saveOLD() -> Dictionary:
	var objects := []
	for thing in props.get_children():
		if thing.has_meta("item"):
			var item: ItemData = thing.get_meta("item")
			var cell := Vector2i(thing.position) / buildLayer.tile_set.tile_size
			objects.append({ "item": item.resource_path, "cell": [cell.x, cell.y] })
	
	var built := []
	for cell in builtCell:
		built.append({ "item": builtCell[cell].resource_path, "cell": [cell.x, cell.y] })
	
	
	return { 
		"tiles": Marshalls.raw_to_base64(buildLayer.tile_map_data), 
		"objects": objects, 
		"built": built, 
		"scene": scene_file_path, 
		"position": [position.x, position.y], 
		"rotation": rotation,
		}


func load_saveOLD(data: Dictionary) -> void:
	
	if data.has("position"):
		position = Vector2(data["position"][0], data["position"][1])
		rotation = data["rotation"]
		reset_physics_interpolation()
	
	var tiles := Marshalls.base64_to_raw(data["tiles"])
	buildLayer.tile_map_data = tiles
	zone_hull.tile_map_data = tiles
	rebuild_collision()
	clear_my_proxies()
	
	for thing in props.get_children():
		if thing.has_meta("item"):
			thing.queue_free()
	placed.clear()
	for obj in data["objects"]:
		var cell := Vector2i(int(obj["cell"][0]), int(obj["cell"][1]))
		place_object(load(obj["item"]), cell)
	
	builtCell.clear()
	if data.has("built"):
		for b in data["built"]:
			var cell := Vector2i(int(b["cell"][0]), int(b["cell"][1]))
			builtCell[cell] = load(b["item"])


func clear_my_proxies() -> void:
	for other: Vessel in get_tree().get_nodes_in_group("vessels"):
		if other.proxies.has(self):
			other.proxies[self].queue_free()
			other.proxies.erase(self)
			


func break_at(cell: Vector2i) -> ItemData:
	
	if placed.has(cell):
		var object: Node2D = placed[cell]
		var item: ItemData = object.get_meta("item")
		for c in placed.keys():
			if placed[c] == object:
				placed.erase(c)
		object.queue_free()
		return item
	
	if builtCell.has(cell):
		var item: ItemData = builtCell[cell]
		buildLayer.erase_cell(cell)
		zone_hull.erase_cell(cell)
		builtCell.erase(cell)
		rebuild_collision()
		clear_my_proxies()
		return item
	
	
	return null

func item_at(cell: Vector2i) -> ItemData:
	
	if placed.has(cell):
		var object: Node2D = placed[cell]
		var item: ItemData = object.get_meta("item")
		
		return item
	if builtCell.has(cell):
		return builtCell[cell]
	return null

func save_key() -> String:
	return String(name)

func to_save() -> Dictionary:
	
	var objects := []
	for thing in props.get_children():
		if thing.has_meta("item"):
			var item: ItemData = thing.get_meta("item")
			var entry := {
				"item": item.resource_path,
				"cell": Vector2i(thing.position) / buildLayer.tile_set.tile_size,
			}
			
			if thing.has_method("to_save"): # only for objects that have functions attached, others dont care
				entry["data"] = thing.to_save()
			objects.append(entry)
	
	var built := []
	for cell in builtCell:
		built.append({ "item": builtCell[cell].resource_path, "cell": cell })
	
	return {
		"tiles" : buildLayer.tile_map_data,
		"objects": objects, 
		"built": built, 
		"scene": scene_file_path, 
		"position": position,
		"rotation": rotation,
	}

func load_save(data: Dictionary) -> void:
	position = data["position"]
	rotation = data["rotation"]
	reset_physics_interpolation()
	
	buildLayer.tile_map_data = data["tiles"]
	zone_hull.tile_map_data = data["tiles"]
	rebuild_collision()
	clear_my_proxies()
	
	for thing in props.get_children():
		if thing.has_meta("item"):
			thing.queue_free()
	
	placed.clear()
	for obj in data["objects"]:
		var thing := place_object(load(obj["item"]), obj["cell"])
		if obj.has("data"):
			thing.load_save(obj["data"])
	
	builtCell.clear()
	for b in data["built"]:
		builtCell[b["cell"]] = load(b["item"])
