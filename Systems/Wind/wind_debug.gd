extends Node2D

# Wind debug overlay. Press F1 to cycle: Off -> Strength -> Direction -> Combined
# Strength:  black = no wind, white = full strength
# Direction: red = blows left, purple = still, blue = blows right
# Combined:  direction colour, darkened where the wind is weak

enum Mode { OFF, STRENGTH, DIRECTION, COMBINED }

var mode: Mode = Mode.OFF
var cellSize: float = 4.0 # world pixels per sampled square (smaller = sharper but slower)
var refreshTime: float = 0.1 # seconds between redraws
var overlayAlpha: float = 0.6 # how see-through the overlay is

var sprite := Sprite2D.new()
var refreshTimer: float = 0.0


func _ready() -> void:
	z_index = 100 # draw on top of everything
	sprite.centered = false
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.modulate.a = overlayAlpha
	sprite.visible = false
	add_child(sprite)


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		mode = ((mode + 1) % Mode.size()) as Mode
		sprite.visible = mode != Mode.OFF
		refreshTimer = 0.0
		print("Wind debug: ", Mode.keys()[mode])


func _process(delta: float) -> void:
	if mode == Mode.OFF:
		return
	refreshTimer -= delta
	if refreshTimer > 0.0:
		return
	refreshTimer = refreshTime
	redraw()


func redraw() -> void:
	var camera := get_viewport().get_camera_2d()
	if camera == null:
		return

	# Work out which part of the world is on screen, snapped to the grid so it doesn't shimmer
	var viewSize := get_viewport_rect().size / camera.zoom
	var topLeft := camera.get_screen_center_position() - viewSize / 2.0
	topLeft = (topLeft / cellSize).floor() * cellSize
	var cellsX := int(ceil(viewSize.x / cellSize)) + 2
	var cellsY := int(ceil(viewSize.y / cellSize)) + 2

	# One image pixel per cell, then stretch it back up to world size
	var image := Image.create(cellsX, cellsY, false, Image.FORMAT_RGBA8)
	for y in cellsY:
		for x in cellsX:
			var worldPos := topLeft + Vector2(x + 0.5, y + 0.5) * cellSize
			image.set_pixel(x, y, get_debug_color(worldPos))

	sprite.texture = ImageTexture.create_from_image(image)
	sprite.global_position = topLeft
	sprite.scale = Vector2(cellSize, cellSize)


func get_debug_color(worldPos: Vector2) -> Color:
	var strength: float = Wind.get_strength_at(worldPos)
	var direction: float = Wind.get_direction_at(worldPos)
	var directionColor := Color.RED.lerp(Color.BLUE, (direction + 1.0) / 2.0)

	match mode:
		Mode.STRENGTH:
			return Color(strength, strength, strength)
		Mode.DIRECTION:
			return directionColor
		_:
			return Color(directionColor.r * strength, directionColor.g * strength, directionColor.b * strength)
