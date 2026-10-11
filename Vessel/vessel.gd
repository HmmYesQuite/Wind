extends RigidBody2D
class_name  Vessel

@onready var hull: TileMapLayer = $Hull
@onready var zone_hull: TileMapLayer = $Zone/ZoneHull

var startY: float
var time: float = 0.0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	zone_hull.tile_map_data = hull.tile_map_data # Copies every tile from the visible Hull into the ZoneHull
	startY = position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time += delta
	position.y = startY + sin(time) * 5
	rotation = sin(time*0.75) * 0.1
