extends Node2D
class_name  CloudField

@export var cloudTextures: Array[Texture2D]= []

@export var cloudLayers: Array[int] = []

@export var randomFlip: bool = false
@export var maxTilt: float = 2.0
@export var tintColor: Color = Color.WHITE
@export_range(0.0, 1.0) var tintAmount: float = 0.0

@export var cloudCount: int = 24
@export var heightRange: Vector2 = Vector2(-160, 40)

@export var depthBias: float = 2.0
@export var windMultiplier: float = 4.0
@export var skyColor: Color =Color(0.55, 0.7, 0.85)

@export var maxBlur: float = 3.0
@export var frontBlur: float = 2.0
var blurShader := preload("res://Systems/Atmosphere/cloud_blur.gdshader")

@export_group("Near (depth 0)")
@export var nearScale: float = 1.0
@export var nearParallax: float = 0.7
@export var nearDrift: float = 1.0
@export var nearZ: int = -2

@export_group("Far (depth 1)")
@export var farScale: float = 0.35
@export var farParallax: float = 0.05
@export var farDrift: float = 0.15
@export var farFade: float = 0.8
@export var farZ: int = -9


@export_group("Front Overlay")
@export_range(0.0, 1.0) var frontChance: float = 0.1
@export var frontParallax: float = 1.3
@export var frontScale: float = 1.3
@export_range(0.0, 1.0) var frontAlpha: float = 0.5
@export var frontZ: int = 10



class Cloud:
	var sprite: Sprite2D
	var basePos: Vector2
	var depth: float
	var parallax: float
	var drift: float

var clouds: Array[Cloud] = []
var scattered: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	process_physics_priority = 20
	for i in cloudCount:
		var cloud := Cloud.new()
		cloud.sprite = Sprite2D.new()
		
		var blurMaterial := ShaderMaterial.new()
		blurMaterial.shader = blurShader
		cloud.sprite.material = blurMaterial
		
		cloud.sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		add_child(cloud.sprite)
		clouds.append(cloud)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	
	modulate = Color.WHITE.lerp(tintColor, tintAmount)
	var camera := get_viewport().get_camera_2d()
	if camera == null or cloudTextures.is_empty():
		return
	var camPos := camera.get_screen_center_position()
	var viewSize := get_viewport_rect().size / camera.zoom
	
	if not scattered:
		for cloud in clouds:
			respawn(cloud, camPos, viewSize, 0.0)
		scattered = true
	
	var windX: float =Wind.get_wind_at(camPos).x * windMultiplier
	
	for cloud in clouds:
		cloud.basePos.x += windX * cloud.drift * delta
		var drawn := cloud.basePos + camPos * (1.0 - cloud.parallax)
		cloud.sprite.global_position = drawn
		
		var limit := viewSize.x / 2.0 + get_half_width(cloud) + 16.0
		if drawn.x < camPos.x - limit:
			respawn(cloud, camPos, viewSize, 1.0)
		elif drawn.x > camPos.x + limit:
			respawn(cloud, camPos, viewSize, -1.0)


func respawn(cloud: Cloud, camPos: Vector2, viewSize: Vector2, side: float) -> void:
	
	var index := randi_range(0, cloudTextures.size() - 1)
	var layer := -1
	if index < cloudLayers.size():
		layer = cloudLayers[index]
	var t := 1.0 - pow(randf(), depthBias)
	if layer >= 0 and layer <= 2:
		cloud.depth = (layer + t) / 3.0
	else:
		cloud.depth = t
	
	
	cloud.parallax = lerpf(nearParallax, farParallax, cloud.depth)
	cloud.drift = lerpf(nearDrift, farDrift, cloud.depth)
	
	var isFront := layer <= 0 and randf() < frontChance
	
	
	if isFront:
		cloud.parallax = frontParallax
		cloud.drift = nearDrift
	
	
	
	var sprite := cloud.sprite
	sprite.texture = cloudTextures[index]
	sprite.flip_h = randomFlip and randf() < 0.5
	sprite.rotation_degrees = randf_range(-maxTilt, maxTilt)
	
	
	var cloudScale := lerpf(nearScale, farScale, cloud.depth)
	
	sprite.modulate = Color.WHITE.lerp(skyColor, cloud.depth * farFade)
	sprite.z_index = int(round(lerpf(float(nearZ), float(farZ), cloud.depth)))
	var blur := cloud.depth * maxBlur
	if isFront:
		cloudScale = frontScale
		sprite.modulate = Color(1, 1, 1, frontAlpha)
		sprite.z_index = frontZ
		blur = frontBlur
	sprite.material.set_shader_parameter("blurSize", blur)
	sprite.scale = Vector2(cloudScale, cloudScale)
	
	
	var drawnX: float
	if side == 0.0:
		drawnX = camPos.x + randf_range(-viewSize.x / 2.0, viewSize.x / 2.0)
	else:
		drawnX = camPos.x + side * (viewSize.x / 2.0 + get_half_width(cloud) + 8.0)
	
	cloud.basePos = Vector2(drawnX - camPos.x * (1.0- cloud.parallax), randf_range(heightRange.x, heightRange.y))
	sprite.global_position = cloud.basePos + camPos * (1.0 - cloud.parallax)
	sprite.reset_physics_interpolation()
	

func get_half_width(cloud: Cloud) -> float:
	return cloud.sprite.texture.get_width() * cloud.sprite.scale.x / 2.0
