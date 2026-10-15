extends DynamicProp




const SPEED = 64.0



const ACCEL = 400.0

const JUMP_STRENGTH = 128.0
@export var jump_bias: float = 0.5 # 0 is relative to ship 1 is relative to world


func move_prop(delta: float) -> void:
	
	# Jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		var vesselUp := Vector2.UP
		var worldUp := Vector2.UP
		if vessel != null:
			worldUp = Vector2.UP.rotated(-vessel.global_rotation)
		var jumpDir := vesselUp.lerp(worldUp, jump_bias).normalized()
		velocity.y = 0
		velocity += jumpDir * JUMP_STRENGTH
		forceLeave = true
		
	
	# Walking
	var direction := Input.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED, ACCEL * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
