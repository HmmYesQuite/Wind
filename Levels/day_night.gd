extends CanvasModulate
class_name DayNight

@export var dayLength: float = 300.0
@export var colors: Gradient

@export_storage var time: float = 0.0
#exports now are what get saved, so have to remake all needed vars


func _process(delta: float) -> void:
	time += delta / dayLength
	
	if GameInput.is_action_just_pressed("debug_time"):
		time += 0.25
	
	if time >= 1.0:
		time -= 1.0
	color = colors.sample(time)

func _ready() -> void:
	add_to_group("persist")
