extends CanvasLayer

@onready var root: Control = $Root
@onready var resumeButton: Button = $Root/Center/Buttons/Resume
@onready var restartButton: Button = $Root/Center/Buttons/Restart
@onready var quitButton: Button = $Root/Center/Buttons/Quit


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = true
	root.visible = false
	resumeButton.pressed.connect(resume)
	restartButton.pressed.connect(restart)
	quitButton.pressed.connect(quit)
	if OS.has_feature("web"):
		quitButton.visible = false
	

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		if get_tree().paused:
			resume()
		else:
			pause()
		get_viewport().set_input_as_handled()


func pause() -> void:
	get_tree().paused = true
	root.visible = true
	resumeButton.grab_focus()

func resume() -> void:
	get_tree().paused = false
	root.visible = false


func restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()

func quit() -> void:
	get_tree().quit()
