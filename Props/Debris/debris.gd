extends Node2D
class_name Debris

@export var itemData: ItemData
@export var itemSize: float = 8.0

@export var floatHeight: float = -10.0

@export var bobAmount: float = 1.5
@export var bobSpeed: float = 1.2
@export var windDrift: float = 0.1
@export var swayAmount: float = 0.12
@export var settleSpeed: float = 4.0

@onready var itemSprite: Sprite2D = $Item

var layer: CloudLayer = null
var time: float = 0.0
var hooked: bool = false
var velocityX: float = 0.0




func _ready() -> void:
	add_to_group("debris")
	time = randf() * TAU
	if itemData != null and itemData.icon != null:
		itemSprite.texture = itemData.icon
		var iconSize := itemData.icon.get_size()
		itemSprite.scale = Vector2.ONE * (itemSize / maxf(iconSize.x, iconSize.y))
	reset_physics_interpolation()
	itemSprite.reset_physics_interpolation()
	
	
	
	
	reset_physics_interpolation()
	itemSprite.reset_physics_interpolation()


func _physics_process(delta: float) -> void:
	time += delta
	if hooked:
		z_index = 1
		itemSprite.modulate = Color.WHITE
		rotation = lerp_angle(rotation, 0.0, 10.0 * delta)
		
		
		return # when hooked the other physics don't run.
	if layer == null:
		layer = find_layer_below()
		if layer == null:
			return
	
	var wind: Vector2 = Wind.get_wind_at(global_position)
	global_position.x += (velocityX + wind.x * windDrift) * delta
	
	var targetY := layer.get_surface_y(global_position.x) - floatHeight + sin(time * bobSpeed) * bobAmount
	
	global_position.y = lerpf(global_position.y, targetY, clampf(settleSpeed * delta, 0.0,  1.0))
	rotation = sin(time * 0.9) * swayAmount
	
	#put a tint on the inside clouds



func find_layer_below() -> CloudLayer:
	var best: CloudLayer = null
	var bestY := INF
	for node in get_tree().get_nodes_in_group("cloudLayers"):
		var candidate := node as CloudLayer
		if candidate == null or not candidate.covers_x(global_position.x):
			continue
		var surface := candidate.get_surface_y(global_position.x)
		if surface >= global_position.y - 4.0 and surface < bestY:
			best = candidate
			bestY = surface
	return best



		
