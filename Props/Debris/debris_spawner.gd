extends Node2D
class_name DebrisSpawner

@export var debrisScene: PackedScene = preload("res://Props/Debris/debris.tscn")
@export var items: Array[ItemData] = []
@export var maxDebris: int = 8
@export var spawnIntervalMin: float = 2.0
@export var spawnIntervalMax: float = 5.0
@export var driftSpeedMin: float = 4.0
@export var driftSpeedMax: float = 12.0
@export var windResponse: float = 1.0
@export var despawnDistance: float = 500.0

var spawned: Array[Debris] = []
var timer: float = 1.0


func _physics_process(delta: float) -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null or items.is_empty():
		return
	var camPos := camera.get_screen_center_position()
	var halfView := get_viewport_rect().size.x / camera.zoom.x / 2.0
	
	
	for i in range(spawned.size() - 1, -1, -1):
		var debris := spawned[i]
		if not is_instance_valid(debris):
			spawned.remove_at(i)
		elif not debris.hooked and absf(debris.global_position.x - camPos.x) > despawnDistance:
			debris.queue_free()
			spawned.remove_at(i)
	
	timer -= delta
	if timer > 0.0 or spawned.size() >= maxDebris:
		return
	timer = randf_range(spawnIntervalMin, spawnIntervalMax)
	spawn(camPos, halfView)


func spawn(campPos: Vector2, halfView: float) -> void:
	var side := -1.0 if randf() < 0.6 else 1.0
	var x := campPos.x + side * (halfView + 16.0)
	var layer := layer_at(x)
	if layer == null:
		return
	var debris := debrisScene.instantiate() as Debris
	debris.itemData = items.pick_random()
	debris.velocityX = -side * randf_range(driftSpeedMin, driftSpeedMax)
	debris.windDrift = windResponse
	debris.position = to_local(Vector2(x, layer.get_surface_y(x) - 8.0))
	add_child(debris)
	spawned.append(debris)


func layer_at(x: float) -> CloudLayer:
	for node in get_tree().get_nodes_in_group("cloudLayers"):
		var candidate := node as CloudLayer
		if candidate != null and candidate.covers_x(x):
			return candidate
	return null
