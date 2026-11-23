extends CanvasLayer
class_name HotairBurnerUI

@onready var increaseButton: Button = $PanelContainer/VBoxContainer/Increase
@onready var decreaseButton: Button = $PanelContainer/VBoxContainer/Decrease
@onready var closeButton: Button = $PanelContainer/VBoxContainer/Close

#need to only change the lift of each vessel. Eventually setup a max and min lift.

var burner: hotair_burner

func _ready() -> void:
	add_to_group("hotair_burner_ui")
	visible = false
	increaseButton.pressed.connect(increase_lift)
	decreaseButton.pressed.connect(decrease_lift)
	closeButton.pressed.connect(close)
	

func increase_lift() -> void:
	burner.change_target(0.1)
func decrease_lift() -> void:
	burner.change_target(-0.1)

func open(target: hotair_burner) -> void:
	burner = target
	visible = true
	GameInput.blocked = true

func close() -> void:
	burner = null
	visible = false
	GameInput.blocked = false
