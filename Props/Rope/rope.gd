extends Node2D
class_name  Rope

@export var vesselA: Vessel
@export var tileA: Vector2i
@export var vesselB: Vessel
@export var tileB: Vector2i

@export var ropeLength: float = 0.0 # 0 = use the distance at the start
@export var stiffness: float = 40.0
@export var damping: float = 8.0
@export var sagSegments: int = 12
@export var maxTension: float = 500.0

@onready var boards: Sprite2D = get_node_or_null("Bridge/Boards")
@onready var bridge: AnimatableBody2D = get_node_or_null("Bridge")

var zoneBridgeA: AnimatableBody2D
var zoneBridgeB: AnimatableBody2D

@onready var line: PixelLine = $Line2D

@export var anchorOnTop: bool = false #for rope bridge so its not in the middle

var item: ItemData
var localA: Vector2
var localB: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	add_to_group("ropes")
	z_index = -1
	localA = get_anchor_point(vesselA, tileA)
	localB = get_anchor_point(vesselB, tileB)
	
	if anchorOnTop:
		var half := 4 # prob don't need this but just in case
		if get_point_b().x > get_point_a().x:
			localA.x += half
			localB.x -= half
		else:
			localA.x -= half
			localB.x += half
	
	if ropeLength <= 0.0:
		ropeLength = get_point_a().distance_to(get_point_b())
	if bridge != null:
		zoneBridgeA = bridge.duplicate()
		place_bridge(zoneBridgeA, localA, vesselA.to_local(get_point_b()))
		
		vesselA.zone.add_child(zoneBridgeA)
		
		zoneBridgeB = bridge.duplicate()
		place_bridge(zoneBridgeB, vesselB.to_local(get_point_a()), localB)
		vesselB.zone.add_child(zoneBridgeB)
		
		place_bridge(bridge, get_point_a(), get_point_b())
		
		boards.texture = ImageTexture.create_from_image(boards.texture.get_image())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	var pointA := get_point_a()
	var pointB := get_point_b()
	var offset := pointB - pointA
	var distance := offset.length()
	
	if distance > ropeLength and distance > 0.0:
		var dir := offset / distance
		var stretch := distance - ropeLength
		var seperatingSpeed := (get_point_velocity(vesselB, pointB) - get_point_velocity(vesselA, pointA)).dot(dir)
		var tension := maxf(stretch * stiffness + seperatingSpeed * damping, 0.0)
		tension = minf(tension, maxTension)
		var force := dir * tension
		vesselA.apply_force(force, pointA - vesselA.global_position)
		vesselB.apply_force(-force, pointB - vesselB.global_position)
	
	update_visual(pointA, pointB, distance)
	
	if bridge != null:
		place_bridge(bridge, pointA, pointB)
		place_bridge(zoneBridgeA, localA, vesselA.to_local(pointB))
		place_bridge(zoneBridgeB, vesselB.to_local(pointA), localB)
		
		var planks := maxi(1, roundi(distance / 8.0))
		boards.region_rect = Rect2(0, 0, planks * 8, 8)
		boards.scale.x = distance / (planks * 8.0)

func place_bridge(body: AnimatableBody2D, from: Vector2, to: Vector2) -> void:
	body.position = (from + to) / 2.0
	body.rotation = wrapf((to - from).angle(), -PI / 2, PI / 2)
	
	var shape: RectangleShape2D = body.get_node("CollisionShape2D").shape
	shape.size = Vector2(from.distance_to(to), 8)


func get_anchor_point(vessel: Vessel, tile: Vector2i) -> Vector2:
	if vessel.hull.get_cell_source_id(tile) == -1:
		push_warning("Rope: Missing tile %s on vessel %s" % [tile, vessel.name]) #for debug
	
	var point := vessel.hull.map_to_local(tile)
	if anchorOnTop:
		point.y -= vessel.hull.tile_set.tile_size.y / 2.0
	return point

func get_point_a() -> Vector2:
	return vesselA.to_global(localA)
func get_point_b() -> Vector2:
	return vesselB.to_global(localB)

func get_point_velocity(vessel: Vessel, globalPoint: Vector2) -> Vector2:
	var r := globalPoint -vessel.global_position
	return vessel.linear_velocity + Vector2(-r.y, r.x) * vessel.angular_velocity

func update_visual(pointA: Vector2, pointB: Vector2, distance: float) -> void:
	var sag := 0.0
	if distance < ropeLength:
		
		if distance < ropeLength and bridge == null: #the bridge wont have sag for now, cus the collisions would prob be glitchy
			sag = sqrt(3.0 * distance * (ropeLength - distance) / 8.0)
	
	var points := PackedVector2Array()
	for i in sagSegments + 1:
		var t := float(i) / sagSegments
		var p := pointA.lerp(pointB, t) + Vector2(0, sag * 4.0 * t * (1.0 - t))
		points.append(to_local(p))
	line.points = points

func _exit_tree() -> void:
	if is_instance_valid(zoneBridgeA):
		zoneBridgeA.queue_free()
	if is_instance_valid(zoneBridgeB):
		zoneBridgeB.queue_free()
