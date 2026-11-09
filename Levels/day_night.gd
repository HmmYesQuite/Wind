extends CanvasModulate
class_name DayNight

@export var dayLength: float = 300.0
@export var colors: Gradient

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta / dayLength
	
	if GameInput.is_action_just_pressed("debug_time"):
		time += 0.25
	
	if time >= 1.0:
		time -= 1.0
	color = colors.sample(time)
