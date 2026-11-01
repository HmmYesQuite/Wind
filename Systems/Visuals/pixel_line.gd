extends Node2D
class_name PixelLine

@export var color: Color = Color.WHITE
@export var pixelSize: float = 0.5
@export var pixelated: bool = true
@export var width: float = 1.0

var points: PackedVector2Array:
	set(value):
		points = value
		queue_redraw()


func _draw() -> void:
	
	if points.size() < 2:
		return
	if not pixelated:
		draw_polyline(points, color, width)
		return
	
	for i in points.size() - 1:
		var a := points[i]
		var b := points[i + 1]
		var steps := maxi(ceili(a.distance_to(b) / pixelSize), 1)
		for s in steps + 1:
			var p := a.lerp(b, float(s) / steps)
			var corner := p - Vector2(width, width) / 2
			var cell := (corner / pixelSize).floor() * pixelSize
			draw_rect(Rect2(cell, Vector2(width, width)), color)
