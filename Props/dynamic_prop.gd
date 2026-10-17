extends CharacterBody2D
class_name DynamicProp

@export var visual: Node2D
@export var vessel: Vessel

const GRAVITY_MULT = 0.5
@export var friction: float = 300.0

@export var leaveDelay: float = 0.05
var airTime: float = 0.0
@export var solidGrace: float = 0.1

@export var playerWeight: float = 20
@export var stepHeight: int = 4
@export var stepSmoothing: float = 15.0
var visualOffset: Vector2 = Vector2.ZERO
var forceLeave: bool = false

@export var killHeight : float = 1000.0



func _ready() -> void:
	
	if visual == null:
		visual =get_node_or_null("Visual")
		if visual != null:
			call_deferred("detach_visual")
	if vessel == null:
		var zoneNode := get_parent()
		if zoneNode is SubViewport and zoneNode.get_parent() is Vessel:
			vessel = zoneNode.get_parent()
	if vessel != null:
		vessel.propCount += 1
		
		
func transfer_to(new_vessel: Vessel) -> void:
	
	if vessel != null:
		vessel.propCount -= 1
	
	var worldPos := global_position
	var worldVel := velocity
	if vessel != null:
		worldPos = vessel.to_global(position)
		worldVel = velocity.rotated(vessel.global_rotation) + vessel.current_velocity
	
	
	if new_vessel != null:
		reparent(new_vessel.zone, false)
		
		position = new_vessel.to_local(worldPos)
		velocity = (worldVel - new_vessel.current_velocity).rotated(-new_vessel.global_rotation)
	
	else:
		var world := get_tree().current_scene
		reparent(world, false)
		global_position = worldPos
		velocity = worldVel
		
	
	vessel = new_vessel
	if vessel != null:
		vessel.propCount += 1
	reset_physics_interpolation()
	

func get_floor_proxy_source() -> Node:
	if not is_on_floor():
		return null
	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		if collider != null and collider.has_meta("source") and collision.get_angle(up_direction) <= floor_max_angle:
			return collider.get_meta("source")
	return null
	

func get_overlapping_proxy_source() -> Node:
	var hit := KinematicCollision2D.new()
	if test_move(global_transform, Vector2.ZERO, hit, safe_margin, true):
		var collider := hit.get_collider()
		if collider != null and collider.has_meta("source"):
			return collider.get_meta("source")
	return null
	

func _physics_process(delta: float) -> void:
	# Gravity
	var gravity := get_gravity() * GRAVITY_MULT
	if vessel != null:
		gravity = gravity.rotated(-vessel.global_rotation)
	if not is_on_floor():
		velocity.y += gravity.y * delta
	velocity.x += gravity.x * delta
	
	forceLeave = false
	move_prop(delta)
	
	move_and_slide()
	
	if is_on_floor():
		airTime = 0.0
	else:
		airTime += delta
	
	set_collision_layer_value(4, vessel == null and airTime < solidGrace)

	var targetAngle := 0.0
	if vessel != null:
		visual.global_position = vessel.to_global(position) + visualOffset
		targetAngle = vessel.global_rotation
		if is_on_floor():
			vessel.apply_force(Vector2(0, playerWeight), vessel.to_global(position) - vessel.global_position)
	
		var proxySource := get_floor_proxy_source()
		var overLapSource := get_overlapping_proxy_source()
		if proxySource is Vessel:
			transfer_to(proxySource as Vessel)
		elif overLapSource is Vessel:
			for h in range(1, stepHeight + 1):
				var raised := global_transform.translated(Vector2(0, -h))
				if not test_move(raised, Vector2.ZERO, null, safe_margin, true):
					visualOffset += Vector2(0, h).rotated(vessel.global_rotation)
					position.y -= h
					transfer_to(overLapSource as Vessel)
					break
		elif forceLeave or airTime > leaveDelay or not vessel.get_zone_bounds().has_point(position):
			transfer_to(null)
	
	else:
		visual.global_position = global_position + visualOffset
		if is_on_floor():
			for i in get_slide_collision_count():
				var collision := get_slide_collision(i)
				var hitVessel := collision.get_collider() as Vessel
				if hitVessel != null and collision.get_angle(up_direction) <= floor_max_angle:
					transfer_to(hitVessel)
					break
	
	visualOffset = visualOffset.lerp(Vector2.ZERO, clamp(stepSmoothing * delta, 0.0, 1.0))
	visual.global_rotation = lerp_angle(visual.global_rotation, targetAngle, 10.0 * delta)
	
	if vessel == null and global_position.y > killHeight:
		fell_out_of_world()
	

func move_prop(delta: float) -> void:
	if is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)

func detach_visual() -> void:
	visual.reparent(get_tree().current_scene)
	
func _notification(what: int) -> void:
	if what == NOTIFICATION_PREDELETE and is_instance_valid(visual):
		if is_instance_valid(visual):
			visual.queue_free()
		if is_instance_valid(vessel):
			vessel.propCount -= 1

func fell_out_of_world() -> void:
	queue_free()
