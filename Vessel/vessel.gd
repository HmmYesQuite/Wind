extends RigidBody2D
class_name  Vessel

@onready var hull: TileMapLayer = $Hull
@onready var zone_hull: TileMapLayer = $Zone/ZoneHull

var startY: float
var time: float = 0.0

var last_position: Vector2 # For getting ship Vel, needed maybe for player momentum
var current_velocity:Vector2 = Vector2.ZERO

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zone_hull.tile_map_data = hull.tile_map_data # Copies every tile from the visible Hull into the ZoneHull
	startY = position.y
	last_position = global_position


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time += delta
	position.y = startY + sin(time) * 5
	rotation = sin(time*0.75) * 0.1
	
	current_velocity = (global_position - last_position) / delta
	last_position = global_position # End of vel calc

func get_zone_bounds() -> Rect2:
	var tile_rect := zone_hull.get_used_rect() # smallest rect that fits tiles
	var tile_size := Vector2(zone_hull.tile_set.tile_size)
	var bounds := Rect2(Vector2(tile_rect.position) * tile_size, Vector2(tile_rect.size) * tile_size)
	return bounds.grow_individual(8, 64, 8, 8) # Need to find way to auto gen this bit
	
	
