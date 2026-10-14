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

@onready var line: Line2D = $Line2D

var localA: Vector2
var localB: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	z_index = -1
	localA = get_anchor_point(vesselA, tileA)
	localB = get_anchor_point(vesselB, tileB)
	if ropeLength <= 0.0:
		ropeLength = get_point_a().distance_to(get_point_b())

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


func get_anchor_point(vessel: Vessel, tile: Vector2i) -> Vector2:
	if vessel.hull.get_cell_source_id(tile) == -1:
		push_warning("Rope: Missing tile %s on vessel %s" % [tile, vessel.name]) #for debug
	return vessel.hull.map_to_local(tile)

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
		sag = sqrt(3.0 * distance * (ropeLength - distance) / 8.0)
	
	var points := PackedVector2Array()
	for i in sagSegments + 1:
		var t := float(i) / sagSegments
		var p := pointA.lerp(pointB, t) + Vector2(0, sag * 4.0 * t * (1.0 - t))
		points.append(to_local(p))
	line.points = points
