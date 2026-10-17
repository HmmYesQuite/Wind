extends Node2D
class_name CloudLayer

@export var infiniteWidth: bool = true
@export var width: float = 640.0

@export_group("Clouds")
@export var cloudTexture: Texture2D
@export var cloudSpacing: float = 24.0

var clouds: Array[Sprite2D] = []
var cloudSlots: Array[int] =[]

@export_group("Waves")
@export var waveAmplitude: float = 8.0
@export var waveLength: float = 120.0
@export var waveSpeed: float = 0.05

@export_group("Wind")
@export var driftWithWind: bool = true
@export var windMultiplier: float = 2.0

@export_group("Debug")
@export var debugDraw: bool = true

var noise: = FastNoiseLite.new()
var time: float = 0.0
var driftOffset: float = 0.0


func _ready() -> void:
	add_to_group("cloudLayers")
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = randi()
	noise.frequency = 1.0


func _physics_process(delta: float) -> void:
	time += delta
	if driftWithWind:
		var wind: Vector2 = Wind.get_wind_at(global_position)
		driftOffset += wind.x * windMultiplier * delta
	
	update_clouds()
	
	if debugDraw:
		queue_redraw()


func get_surface_y(x: float) -> float:
	var n := noise.get_noise_2d((x- driftOffset) / waveLength, time * waveSpeed)
	return global_position.y + n * waveAmplitude


func covers_x(x: float) -> bool:
	if infiniteWidth:
		return true
	return absf(x - global_position.x) <= width


func _draw() -> void:
	if not debugDraw:
		return
	var left: float
	var right: float
	if infiniteWidth:
		var camera := get_viewport().get_camera_2d()

		if camera == null:
			return
		var halfView := get_viewport_rect().size.x / camera.zoom.x / 2.0
		left = camera.get_screen_center_position().x - halfView
		right = camera.get_screen_center_position().x + halfView
	else:
		left = global_position.x - width / 2.0
		right = global_position.x + width / 2.0
	
	var points := PackedVector2Array()
	var x := left
	while x <= right:
		points.append(Vector2(x - global_position.x, get_surface_y(x) - global_position.y))
		x += 4.0
	if points.size() >= 2:
		draw_polyline(points, Color.MAGENTA, 1.0)


func get_visible_range() -> Vector2:
	if infiniteWidth:
		var camera := get_viewport().get_camera_2d()
		var halfView := get_viewport_rect().size.x / camera.zoom.x / 2.0
		var centerX := camera.get_screen_center_position().x
		return Vector2(centerX - halfView - cloudSpacing, centerX + halfView + cloudSpacing)
	return Vector2(global_position.x - width / 2.0, global_position.x + width / 2.0)


func update_clouds() -> void:
	if cloudTexture == null or get_viewport().get_camera_2d() == null:
		return
	var visibleRange := get_visible_range()
	
	if clouds.is_empty():
		var count := int(ceil((visibleRange.y - visibleRange.x) / cloudSpacing)) + 2
		for i in count:
			var sprite := Sprite2D.new()
			sprite.texture = cloudTexture
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(sprite)
			clouds.append(sprite)
			cloudSlots.append(-999999)
		
	var firstSlot := int(floor(visibleRange.x / cloudSpacing))
	for k in clouds.size():
		var slot := firstSlot + k
		var i := posmod(slot, clouds.size())
		var x := slot * cloudSpacing
		var sprite := clouds[i]
		sprite.global_position = Vector2(x, get_surface_y(x))
		sprite.visible = x <= visibleRange.y
		if cloudSlots[i] != slot:
			cloudSlots[i] = slot
			sprite.reset_physics_interpolation()
