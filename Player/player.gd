extends CharacterBody2D

@export var visual: Node2D
# These two make it so you can assign the stuff
@export var vessel: Vessel

const SPEED = 64.0
const JUMP_VELOCITY = -128.0
const GRAVITY_MULT = 0.5

const ACCEL = 400.0
@export var friction: float = 300.0
const JUMP_STRENGTH = 128.0
@export var jump_bias: float = 0.5 # 0 is relative to ship 1 is relative to world

@export var leaveDelay: float = 0.05
var airTime: float = 0.0
@export var solidGrace: float = 0.1

@export var playerWeight: float = 20
@export var stepHeight: int = 4
@export var stepSmoothing: float =15.0
var visualOffset: Vector2 = Vector2.ZERO


func _ready() -> void:
	if vessel == null:
		var zoneNode := get_parent()
		if zoneNode is SubViewport and zoneNode.get_parent() is Vessel:
			vessel = zoneNode.get_parent()
	if vessel != null:
		vessel.propCount += 1

func _physics_process(delta: float) -> void:
	# Add the gravity.
	var gravity := get_gravity() * GRAVITY_MULT
	if vessel != null:
		gravity = gravity.rotated(-vessel.global_rotation)
	if not is_on_floor():
		velocity.y += gravity.y * delta
	velocity.x += gravity.x * delta

	# Handle jump.
	var jumped := false
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var vesselUp := Vector2.UP
		var worldUp := Vector2.UP
		if vessel != null:
			worldUp = Vector2.UP.rotated(-vessel.global_rotation)
		var jumpDir := vesselUp.lerp(worldUp, jump_bias).normalized()
		velocity.y = 0
		velocity += jumpDir * JUMP_STRENGTH
		jumped = true

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	move_and_slide()
	
	if is_on_floor():
		airTime = 0.0
	else:
		airTime += delta
	
	set_collision_layer_value(4, vessel == null and airTime < solidGrace)
	
	var targetAngle := 0.0
	if vessel != null:
		visual.global_position = vessel.to_global(position) +visualOffset
		targetAngle = vessel.global_rotation
		
		if is_on_floor():
			vessel.apply_force(Vector2(0, playerWeight), vessel.to_global(position) - vessel.global_position)

		var proxySource := get_floor_proxy_source()
		var overlapSource := get_overlapping_proxy_source()
		if proxySource is Vessel:
			transfer_to(proxySource as Vessel)
		elif overlapSource is Vessel:
			for h in range(1, stepHeight + 1):
				var raised := global_transform.translated(Vector2(0, -h))
				if not test_move(raised, Vector2.ZERO, null, safe_margin, true):
					visualOffset += Vector2(0, h).rotated(vessel.global_rotation)
					position.y -= h
					transfer_to(overlapSource as Vessel)
					break
		elif jumped or airTime > leaveDelay or not vessel.get_zone_bounds().has_point(position):
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
		
	visualOffset =visualOffset.lerp(Vector2.ZERO, clamp(stepSmoothing * delta, 0.0, 1.0))
	visual.rotation = lerp_angle(visual.global_rotation, targetAngle, 10.0 * delta)



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
