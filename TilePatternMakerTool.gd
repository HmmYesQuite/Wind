@tool
extends TileMapLayer

@export var pieceSize := Vector2i(16, 16)
@export var fileLoc := "res://Terrain/Cliff/CliffPieces/"

@export_tool_button("Bake") var bakeButton = bake

func bake() -> void:
	var bounds = get_used_rect()
	for sy in range(bounds.position.y / pieceSize.y, bounds.end.y / pieceSize.y + 1):
		for sx in range(bounds.position.x / pieceSize.x, bounds.end.x / pieceSize.x + 1):
			var origin := Vector2i(sx, sy) * pieceSize
			var cells: Array[Vector2i] = []
			for c in get_used_cells():
				if Rect2i(origin, pieceSize).has_point(c):
					cells.append(c)
			if cells.is_empty():
				continue
			
			var fileName := fileLoc + "piece_%d_%d.tres" % [sx, sy]
			var piece: CliffPiece = load(fileName) if ResourceLoader.exists(fileName) else CliffPiece.new()
			piece.pattern = get_pattern(cells)
			var minCell: Vector2i = cells[0]
			for c in cells:
				minCell = Vector2i(mini(minCell.x, c.x), mini(minCell.y, c.y))
			piece.offset = minCell - origin
			ResourceSaver.save(piece, fileName)
			
