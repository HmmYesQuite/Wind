extends Node2D

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

@export var airDrag: float = 4
@export var lowerSpeed: float = 60.0

@onready var tip: Marker2D = $Tip
@onready var line: Line2D = $Line
@onready var hook: Polygon2D = $Hook

@export var windEffect: float = 8.0
@export var sagSegments: int = 10

@export var snagRadius: float = 6.0

var state: State = State.READY
var hookPos: Vector2 = Vector2.ZERO
var hookVel: Vector2 = Vector2.ZERO
var lineLength: float = 0.0
var canReel: bool = false
var hooked: Debris = null

var previousTarget: Node2D = null


func _ready() -> void:
	process_physics_priority = 2
	hook.physics_interpolation_mode = Node.PHYSICS_INTERPOLATION_MODE_OFF
	line.visible = false
	hook.visible = false


func _physics_process(delta: float) -> void:
	if state == State.READY:
		var side := signf(get_global_mouse_position().x - global_position.x)
		if side != 0.0:
			scale.x = side
		if Input.is_action_just_pressed("use_item"):
			cast()
		return
	
	var mouse := get_global_mouse_position()
	
	if not Input.is_action_pressed("use_item"):
		canReel = true
	var reeling := canReel and Input.is_action_pressed("use_item")
	
	if reeling:
		lineLength -= reelSpeed * delta
		if lineLength <= minLineLength:
			end_cast()
			return
	elif Input.is_action_pressed("use_item_alt"):
		
		lineLength = minf(lineLength + lowerSpeed * delta, maxLineLength)
	
	simulate(delta, mouse)
	
	if hooked == null:
		try_snag()
	else:
		hooked.global_position = hookPos + Vector2(0, 4)
	
	update_line()


func cast() -> void:
	state = State.CAST
	hookPos = tip.global_position
	hookVel = Vector2(scale.x * throwSpeed, -throwUp)
	hook.global_position = hookPos
	line.visible = true
	hook.visible = true
	lineLength = startLength
	canReel = false
	follow_hook_with_camera()


func simulate(delta: float, mouse: Vector2) -> void:
	
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
		var outward := hookVel.dot(dir)
		if outward > 0.0:
			hookVel -= dir * outward
	
	hook.global_position = hookPos

func end_cast() -> void:
	
	# Need to change when proper inventory is added, also need to account for stuff like chests and crates
	if hooked != null:
		if hooked.itemData != null and Hotbar.add_item(hooked.itemData):
			hooked.queue_free()
		else:
			hooked.hooked = false
		hooked = null
	
	state = State.READY
	line.visible = false
	hook.visible = false
	restore_camera()


func update_line() -> void:
	var start := tip.global_position
	var distance := start.distance_to(hookPos)
	var sag := 0.0
	if distance < lineLength:
		sag = sqrt(3.0 * distance * (lineLength - distance) / 8.0)
	
	var points := PackedVector2Array()
	for i in sagSegments + 1:
		var t := float(i) / sagSegments
		points.append(start.lerp(hookPos, t) + Vector2(0, sag * 4.0 * t * (1.0 - t)))
		line.points = points


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
			return
