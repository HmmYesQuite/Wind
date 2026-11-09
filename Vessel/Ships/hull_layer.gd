extends TileMapLayer
class_name HullLayer

var hiddenCell: Vector2i
var hiding: bool = false

func _use_tile_data_runtime_update(coords: Vector2i) -> bool:
	return hiding and coords == hiddenCell


func _tile_data_runtime_update(coords: Vector2i, tile_data: TileData) -> void:
	tile_data.modulate.a = 0

func hide_cell(cell: Vector2i) -> void:
	if hiding and hiddenCell == cell:
		return
	
	hiding = true
	hiddenCell = cell
	notify_runtime_tile_data_update()

func show_cells() -> void:
	
	
	if not hiding:
		return
	hiding = false
	var source := get_cell_source_id(hiddenCell)
	var coords := get_cell_atlas_coords(hiddenCell)
	var alt := get_cell_alternative_tile(hiddenCell)
	erase_cell(hiddenCell)
	set_cell(hiddenCell, source, coords, alt)
