extends CanvasLayer
class_name HotairBurnerUI

@onready var increaseButton: Button = $PanelContainer/VBoxContainer/Increase
@onready var decreaseButton: Button = $PanelContainer/VBoxContainer/Decrease
@onready var closeButton: Button = $PanelContainer/VBoxContainer/Close

#need to only change the lift of each vessel. Eventually setup a max and min lift.

var vessel: Vessel

func _ready() -> void:
	add_to_group("hotair_burner_ui")
	visible = false
	increaseButton.pressed.connect(increase_lift)
	decreaseButton.pressed.connect(decrease_lift)
	closeButton.pressed.connect(close)
	

func increase_lift() -> void:
	vessel.set_lift_multiplier(vessel.balloonLiftMultiplier + 0.1)
func decrease_lift() -> void:
	vessel.set_lift_multiplier(vessel.balloonLiftMultiplier - 0.1)

func open(target: Vessel) -> void:
	vessel = target
	visible = true
	GameInput.blocked = true

func close() -> void:
	vessel = null
	visible = false
	GameInput.blocked = false
