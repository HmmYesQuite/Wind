extends DynamicProp

@export var flySpeed: float =120.0
var flying: bool = false

const SPEED = 48.0
const ACCEL = 400.0
const JUMP_STRENGTH = 96.0
@export var jump_bias: float = 0.5 # 0 is relative to ship 1 is relative to world

@export var interactionMoveSpeed: float = 0.5
@export var interactionJumpSpeed: float = 0.5

@export var turnSpeed: float = 8.0
var facing := 1.0



func move_prop(delta: float) -> void:
	
	if GameInput.is_action_just_pressed("debug_fly"):
		flying = not flying
		$CollisionShape2D.set_deferred("disabled", flying)
		if flying and vessel != null:
			transfer_to(null)
	if flying:
		var flyInput := Vector2(
			GameInput.get_axis("move_left", "move_right"),
			float(GameInput.is_key_pressed(KEY_S)) - float(GameInput.is_key_pressed(KEY_W)))
		velocity = flyInput * flySpeed
		return
	
	var moveScale := 1.0
	var jumpScale := 1.0
	var fishingRod := visual.get_node("Hand").held as FishingRod
	if fishingRod != null and fishingRod.state == FishingRod.State.CAST:
		moveScale *= interactionMoveSpeed
		jumpScale *= interactionJumpSpeed
	
	# Jumping
	if GameInput.is_action_just_pressed("jump") and is_on_floor():
		var vesselUp := Vector2.UP
		var worldUp := Vector2.UP
		if vessel != null:
			worldUp = Vector2.UP.rotated(-vessel.global_rotation)
		var jumpDir := vesselUp.lerp(worldUp, jump_bias).normalized()
		velocity.y = 0
		velocity += jumpDir * JUMP_STRENGTH * jumpScale
		forceLeave = true
		
	
	# Walking
	var direction := GameInput.get_axis("move_left", "move_right")
	if direction:
		velocity.x = move_toward(velocity.x, direction * SPEED * moveScale, ACCEL * delta)
	elif is_on_floor():
		velocity.x = move_toward(velocity.x, 0, friction * delta)
	
	
	var sprite: PlayerSprite = visual.get_node("Sprite2D")
	var hand: Node2D = visual.get_node("Hand")
	if direction:
		sprite.play("walk")
		facing = signf(direction)
	else:
		sprite.play("idle")
		if fishingRod != null:
			facing = fishingRod.facing
	
	sprite.scale.x = move_toward(sprite.scale.x, facing, turnSpeed * delta)
	hand.scale.x = sprite.scale.x
	#Need to setup so other held items have these / similar rules
	
	


func fell_out_of_world() -> void:
	get_tree().reload_current_scene()
