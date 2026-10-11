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


func _physics_process(delta: float) -> void:
	# Add the gravity.
	var gravity := get_gravity() * GRAVITY_MULT
	if vessel != null:
		gravity = gravity.rotated(-vessel.global_rotation)
	if not is_on_floor():
		velocity.y += gravity.y * delta
	velocity.x += gravity.x * delta

	# Handle jump.
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var vesselUp := Vector2.UP
		var worldUp := Vector2.UP
		if vessel != null:
			worldUp = Vector2.UP.rotated(-vessel.global_rotation)
		var jumpDir := vesselUp.lerp(worldUp, jump_bias).normalized()
		velocity.y = 0
		velocity += jumpDir * JUMP_STRENGTH

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	

	move_and_slide()
	
	if vessel != null:
		visual.position = position
		if not vessel.get_zone_bounds().has_point(position):
			leave_vessel()
	else:
		visual.global_position = global_position


func leave_vessel() -> void:
	var world_position := vessel.to_global(position)
	var world_velocity := velocity.rotated(vessel.global_rotation) + vessel.current_velocity
	
	var world := vessel.get_parent()
	reparent(world, false)
	visual.reparent(world, false)
	
	global_position = world_position
	velocity = world_velocity
	visual.rotation = 0
	vessel = null
	
	
