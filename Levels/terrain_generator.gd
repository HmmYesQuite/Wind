extends TileMapLayer
class_name TerrainGenerator

@export var pieces: Array[CliffPiece] = []
@export var height: int = 20
@export var pieceSize := Vector2i(16, 16)
@export var centerTile: CliffPiece

var grid: Dictionary[Vector2i, CliffPiece] = {}


func _ready() -> void:
	
	add_to_group("terrain")
	generate(1)

func generate(genSeed: int) -> void:
	clear()
	
	grid.clear()
	
	var rng := RandomNumberGenerator.new()
	rng.seed = genSeed
	
	
	for y in height:
		for x in 2: #incase decide to do more spread out
			var slot := Vector2i(x ,-y)
			var piece := choose_piece(slot, rng)
			if piece == null or piece.pattern == null:
				continue
			if x > 0:
				# for the filler solid color tiles, might remove later
				piece = centerTile
				grid[slot] = piece
				set_pattern(slot * pieceSize + piece.offset, piece.pattern)
				
			else:
				grid[slot] = piece
				set_pattern(slot * pieceSize + piece.offset, piece.pattern)

func choose_piece(slot: Vector2i, rng: RandomNumberGenerator) -> CliffPiece:
	# later add rules for deciding if the tiles above and to the left fit in.
	var options : Array[CliffPiece] = []
	var leftPiece: CliffPiece = grid.get(slot + Vector2i.LEFT)
	var belowPiece: CliffPiece = grid.get(slot + Vector2i.DOWN)
	
	for p in pieces:
		
		
		options.append(p)
		
	
	return pick_weighted(options, rng)


func pick_weighted(options: Array[CliffPiece], rng: RandomNumberGenerator) -> CliffPiece:
	var total := 0.0
	for p in options:
		total += p.pickWeight
	var roll := rng.randf() * total
	for p in options:
		roll -= p.pickWeight
		if roll <= 0.0:
			return p
	return options.back()
