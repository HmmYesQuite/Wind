extends Sprite2D
class_name PlayerSprite

@export var frameWidth: int = 16
@export var fps: float = 8.0
@export var animations: Dictionary[String, Texture2D] = {}
@export var speeds: Dictionary[String, float] = {}

var currentFps := 8.0
var current := ""
var frameTime := 0.0


func play(animName: String) -> void:
	if animName == current or not animations.has(animName):
		return
	current = animName
	frame = 0
	frameTime = 0.0
	texture = animations[animName]
	currentFps = speeds.get(animName, fps)
	hframes = texture.get_width() / frameWidth
	

func _process(delta: float) -> void:
	if hframes <= 1:
		return
	frameTime += delta
	if frameTime >= 1.0 / currentFps:
		frameTime -= 1.0 / currentFps
		frame = (frame + 1) % hframes
