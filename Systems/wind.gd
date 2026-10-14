extends Node

var windScale: float = 0.1 # switching to 0 toggles off for debug
var maxWindSpeed: float = 40.0

var windMapSize: float = 0.002
var directionBoost: float = 1.5

var morphSpeed: float = 4.0

var time: float = 0.0

var noiseWindStrength := FastNoiseLite.new()
var noiseWindDirection := FastNoiseLite.new()


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	noiseWindStrength.noise_type = FastNoiseLite.TYPE_PERLIN
	noiseWindStrength.seed = randi()
	noiseWindStrength.frequency = windMapSize

	noiseWindDirection.noise_type = FastNoiseLite.TYPE_PERLIN
	noiseWindDirection.seed = randi()
	noiseWindDirection.frequency = windMapSize
	
	# CHANGE TO SEEDED GAMES LATER

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta: float) -> void:
	time += delta


func get_strength_at(pos: Vector2) -> float:
	var windStrength: float = noiseWindStrength.get_noise_3d(pos.x, pos.y, time * morphSpeed) # -1 to 1
	return remap(windStrength, -1.0, 1.0, 0.0, 1.0)
func get_direction_at(pos: Vector2) -> float:
	var windDirection: float = noiseWindDirection.get_noise_3d(pos.x, pos.y, time * morphSpeed) # -1 to 1
	return clamp(windDirection * directionBoost, -1.0, 1.0)
func get_wind_at(pos: Vector2) -> Vector2:
	var windSpeed: float = get_direction_at(pos) * get_strength_at(pos) * maxWindSpeed * windScale
	return Vector2(windSpeed, 0)
