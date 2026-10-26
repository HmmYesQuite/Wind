extends Node2D
class_name CloudLayer

@export var infiniteWidth: bool = true
@export var width: float = 640.0

@export var clearRadius: float = 10.0
@export var fadeRadius: float = 100.0

@export_group("Clouds")
@export var cloudTextures: Array[Texture2D]
@export var cloudSpacing: float = 24.0
@export var cloudScale: float = 1.0

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
@export var debugDraw: bool = false

@export_group("Depth")
@export var backParallax: float = 0.75
@export var backRise: float = 14.0
@export var backScale: float = 0.65
@export var backFade: float = 0.45
@export var fadeColor: Color = Color(0.55, 0.75, 0.95)

@export_group("Body")
@export var bodyDepth: float = 60.0
@export var bodyTopColor: Color = Color(0.85, 0.91, 0.95, 0.5)
@export var bodyBottomColor: Color = Color(0.12, 0.6, 0.93, 0.5)
@export var rimColor: Color = Color(1, 1, 1, 0)


var noise: = FastNoiseLite.new()
var time: float = 0.0
var driftOffset: float = 0.0

var cloudDepths: Array[float] = []
var rng := RandomNumberGenerator.new()
var body := Polygon2D.new()
var rim := Line2D.new()

var visiblePoint: Vector2
var visibleAmount: float


func _ready() -> void:
	add_to_group("cloudLayers")
	noise.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	noise.seed = randi()
	noise.frequency = 1.0
	
	body.z_index = -3
	add_child(body)
	rim.z_index = -2
	rim.width = 1.0 / absf(global_scale.y)
	rim.default_color = rimColor
	add_child(rim)


func _physics_process(delta: float) -> void:
	time += delta
	if driftWithWind:
		var wind: Vector2 = Wind.get_wind_at(global_position)
		driftOffset += wind.x * windMultiplier * delta
	
	update_clouds()
	
	update_body()
	
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
		var halfView := get_viewport_rect().size.x / camera.zoom.x / 2.0 / backParallax
		var centerX := camera.get_screen_center_position().x
		return Vector2(centerX - halfView - cloudSpacing, centerX + halfView + cloudSpacing)
	return Vector2(global_position.x - width / 2.0, global_position.x + width / 2.0)


func update_clouds() -> void:
	if cloudTextures.is_empty() or get_viewport().get_camera_2d() == null:
		return
	var visibleRange := get_visible_range()
	
	if clouds.is_empty():
		var count := int(ceil((visibleRange.y - visibleRange.x) / cloudSpacing)) + 2
		for i in count:
			var sprite := Sprite2D.new()
			
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			add_child(sprite)
			clouds.append(sprite)
			cloudSlots.append(-999999)
			cloudDepths.append(0.0)
		
	var camX := get_viewport(). get_camera_2d().get_screen_center_position().x
	var firstSlot := int(floor(visibleRange.x / cloudSpacing))
	
	var needsSort := false
	
	for k in clouds.size():
		var slot := firstSlot + k
		var i := posmod(slot, clouds.size())
		var x := slot * cloudSpacing
		var sprite := clouds[i]
		
		var isNew := cloudSlots[i] != slot
		if isNew:
			needsSort = true
			cloudSlots[i] = slot
			rng.seed = hash(slot)
			var depth := rng.randf()
			cloudDepths[i] = depth
			sprite.scale = Vector2.ONE * lerpf(1.0, backScale, depth) * rng.randf_range(0.9, 1.1) * cloudScale
			sprite.modulate = Color.WHITE.lerp(fadeColor, depth * backFade)
			sprite.z_index = int(round(lerpf(1.0, -1.0, depth)))
			sprite.reset_physics_interpolation()
			sprite.texture = cloudTextures[rng.randi_range(0, cloudTextures.size()-1)]
		
		var d := cloudDepths[i]
		var parallax := lerpf(1.0, backParallax, d)
		var drawX := camX + (x - camX) * parallax
		sprite.global_position = Vector2(drawX, get_surface_y(x) - d * backRise)
		
		var distance := sprite.global_position.distance_to(visiblePoint)
		var fade := lerpf(0.15, 1.0, smoothstep(clearRadius, fadeRadius, distance))
		sprite.modulate.a = lerpf(1.0, fade, visibleAmount)
		
		sprite.visible = x <= visibleRange.y
		if isNew:
			sprite.reset_physics_interpolation()
		
	if needsSort:
		var order := range(clouds.size())
		order.sort_custom(func(a, b): return cloudDepths[a] > cloudDepths[b])
		for n in order.size():
			move_child(clouds[order[n]], n)


func update_body() -> void:
	if get_viewport().get_camera_2d() == null:
		return
	var visibleRange := get_visible_range()
	var top := PackedVector2Array()
	var x := visibleRange.x
	while x <= visibleRange.y:
		top.append(to_local(Vector2(x, get_surface_y(x))))
		x += 6.0
	
	var shape := top.duplicate()
	var colors := PackedColorArray()
	for p in top:
		colors.append(bodyTopColor)
	for j in range(top.size() - 1, -1, -1):
		shape.append(to_local(Vector2(to_global(top[j]).x, global_position.y + bodyDepth)))
		colors.append(bodyBottomColor)
	
	body.polygon = shape
	body.vertex_colors = colors
	rim.points = top
