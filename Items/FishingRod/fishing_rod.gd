extends Node2D
class_name FishingRod

enum State { READY, CAST }

@export var throwSpeed: float = 90.0
@export var throwUp: float = 50.0
@export var hookGravity: float = 250.0

@export var startLength: float = 60.0
@export var minLineLength: float = 4.0
@export var maxLineLength: float = 400.0
@export var lineSpeed: float = 60.0
@export var reelSpeed: float = 100.0
@export var aimStrength: float = 1.5
@export var aimRange: float = 40.0

@export var airDrag: float = 2
@export var lowerSpeed: float = 60.0

@onready var tip: Marker2D = $Tip
@onready var line: Line2D = $Line
@onready var hook: Sprite2D = $Hook

@export var windEffect: float = 8.0
@export var sagSegments: int = 10

@export var snagRadius: float = 6.0
@export var attachSpeed: float = 12.0
@export var attachDuration: float = 0.2

@export var revealSpeed: float = 3.0
@export var turnSpeed: float = 8.0

var facing := 1.0

var state: State = State.READY
var hookPos: Vector2 = Vector2.ZERO
var hookVel: Vector2 = Vector2.ZERO
var lineLength: float = 0.0
var lineOut: float
var canReel: bool = false
var hooked: Debris = null
var attachOffset: Vector2 = Vector2.ZERO
var attachTime: float = 0.0
var reelVel: float = 0.0


var previousTarget: Node2D = null

var linePointsPos: PackedVector2Array
var oldLinePos: PackedVector2Array

@export var lineGravity: float = 300.0
@export var lineDamping: float = 0.90
@export var lineIterations: int = 20
@export var reelAccel: float = 200.0


func _ready() -> void:
	process_physics_priority = 2
	hook.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	line.visible = false
	hook.visible = false


func _physics_process(delta: float) -> void:
	
	scale.x = move_toward(scale.x, facing, turnSpeed * delta)
	
	var visibleTarget := 1.0 if state == State.CAST else 0.0
	for node in get_tree().get_nodes_in_group("cloudLayers"):
		var layer := node as CloudLayer
		if layer == null:
			continue
		layer.visiblePoint = hookPos
		layer.visibleAmount = move_toward(layer.visibleAmount, visibleTarget, revealSpeed * delta)
	
	if state == State.READY:
		var side := signf(get_global_mouse_position().x - global_position.x)
		if side != 0.0:
			scale.x = side
		if GameInput.is_action_just_pressed("use_item"):
			cast()
		return
	else:
		
		var dx := hookPos.x - global_position.x
		if absf(dx) > 6: # Deadzone is 6 rn
			scale.x = signf(dx)
	
	var mouse := get_global_mouse_position()
	
	if not GameInput.is_action_pressed("use_item"):
		canReel = true
	var reeling := canReel and GameInput.is_action_pressed("use_item")
	
	var reelTarget := 0.0
	
	if reeling:
		
		if hooked != null and hooked.itemData != null:
			reelTarget = reelSpeed / hooked.itemData.weight
		else:
			reelTarget = reelSpeed
		
	elif GameInput.is_action_pressed("use_item_alt"):
		
		lineLength = minf(lineLength + lowerSpeed * delta, maxLineLength)
	
	
	reelVel = move_toward(reelVel, reelTarget, reelAccel * delta)
	lineLength -= reelVel * delta
	if lineLength <= minLineLength:
		end_cast()
		return
	
	simulate(delta, mouse)
	
	if hooked == null:
		try_snag()
	else:
		var hangPos := hookPos + Vector2(0, 4)
		attachTime = minf(attachTime + delta, attachDuration)
		var t := attachTime / attachDuration
		var settle := 1.0 - pow(1.0 - t, 3.0)
		hooked.global_position = hangPos + attachOffset * (1.0 - settle)
			
	update_line(delta)


func cast() -> void:
	state = State.CAST
	hookPos = tip.global_position
	hookVel = Vector2(scale.x * throwSpeed, -throwUp)
	hook.global_position = hookPos
	line.visible = true
	hook.visible = true
	lineLength = startLength
	canReel = false
	linePointsPos.resize(sagSegments + 1)
	linePointsPos.fill(tip.global_position)
	oldLinePos.resize(sagSegments + 1)
	oldLinePos.fill(tip.global_position)
	reelVel = 0.0
	lineOut = 0
	
	follow_hook_with_camera()


func simulate(delta: float, mouse: Vector2) -> void:
	
	var oldPos := hookPos
	
	hookVel.x += clampf(mouse.x - hookPos.x, -aimRange, aimRange) * aimStrength * delta
	
	var wind: Vector2 = Wind.get_wind_at(hookPos)
	hookVel.x += wind.x * windEffect * delta
	
	hookVel.y += hookGravity * delta
	hookVel *= maxf(0.0, 1.0 - airDrag * delta)
	hookPos += hookVel * delta
	
	var offset := hookPos - tip.global_position
	if offset.length() > lineLength:
		var dir := offset.normalized()
		hookPos = tip.global_position + dir * lineLength
		
	
	hookVel = (hookPos - oldPos) / delta
	
	hook.global_position = hookPos

func end_cast() -> void:
	
	# Need to change when proper inventory is added, also need to account for stuff like chests and crates
	if hooked != null:
		if hooked.itemData != null and Inventory.add_item(hooked.itemData):
			hooked.queue_free()
		else:
			hooked.hooked = false
		hooked = null
	
	state = State.READY
	line.visible = false
	hook.visible = false
	restore_camera()


func update_line(delta: float) -> void:
	var start := tip.global_position
	
	
	for i in range(1, sagSegments):
		var velocity := linePointsPos[i] - oldLinePos[i]
		oldLinePos[i] = linePointsPos[i]
		linePointsPos[i] += velocity * lineDamping + Vector2(0, lineGravity) * delta * delta
	
	linePointsPos[0] = start
	linePointsPos[sagSegments] = hookPos
	
	lineOut = minf(maxf(lineOut, start.distance_to(hookPos)), lineLength)
	
	var segmentLength := lineOut / sagSegments
	for i in lineIterations:
		for j in sagSegments:
			var offset := linePointsPos[j + 1] - linePointsPos[j]
			var dist := offset.length()
			if dist == 0:
				continue
			var correction := offset * ((dist - segmentLength) / dist) * 0.5
			linePointsPos[j] += correction
			linePointsPos[j + 1] -= correction
		linePointsPos[0] = start
		linePointsPos[sagSegments] = hookPos
	
	
	line.points = linePointsPos
	
	var direction := linePointsPos[sagSegments - 1] - hookPos
	hook.rotation = direction.angle() + (PI / 2)


func follow_hook_with_camera() -> void:
	var camera = get_viewport().get_camera_2d()
	if camera == null or not ("target" in camera):
		return
	previousTarget = camera.target
	camera.target = hook


func restore_camera() -> void:
	var camera = get_viewport().get_camera_2d()
	
	if camera != null and previousTarget != null and is_instance_valid(previousTarget):
		camera.target = previousTarget
	previousTarget = null


func _exit_tree() -> void:
	if hooked != null and is_instance_valid(hooked):
		hooked.hooked = false
	restore_camera()


func try_snag() -> void:
	for node in get_tree().get_nodes_in_group("debris"):
		var debris := node as Debris
		if debris != null and not debris.hooked and debris.global_position.distance_to(hookPos) <= snagRadius:
			hooked = debris
			debris.hooked = true
			attachOffset = debris.global_position - (hookPos + Vector2(0, 4))
			attachTime = 0.0
			return
