extends HullLayer
class_name TerrainGenerator

@export var pieces: Array[CliffPiece] = []
@export var height: int = 20
@export var pieceSize := Vector2i(16, 16)
@export var centerTile: CliffPiece
@onready var buildLayer: HullLayer = self

var grid: Dictionary[Vector2i, CliffPiece] = {}
var placed: Dictionary[Vector2i, Node2D] = {}
var builtCell: Dictionary[Vector2i, ItemData] = {}

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


func break_at(cell: Vector2i) -> ItemData:
	
	if placed.has(cell):
		var object: Node2D = placed[cell]
		var item: ItemData = object.get_meta("item")
		for c in placed.keys():
			if placed[c] == object:
				placed.erase(c)
		object.queue_free()
		return item
	
	if builtCell.has(cell):
		var item: ItemData = builtCell[cell]
		erase_cell(cell)
		
		builtCell.erase(cell)
		
	
	return null


func item_at(cell: Vector2i) -> ItemData:
	
	if placed.has(cell):
		var object: Node2D = placed[cell]
		var item: ItemData = object.get_meta("item")
		
		return item
	if builtCell.has(cell):
		return builtCell[cell]
	return null

func add_tile(cell: Vector2i, item: ItemData) -> void:
	set_cell(cell, 0, item.tileCoords)
	builtCell[cell] = item

func place_object(item: ItemData, topLeft: Vector2i) -> void:
	var thing: Node2D = item.placeScene.instantiate()
	$Props.add_child(thing)
	thing.position = Vector2(topLeft * tile_set.tile_size)
	thing.reset_physics_interpolation()
	thing.set_meta("item", item)
	var size := Vector2i(item.worldSpaceTexture.get_size()) / tile_set.tile_size
	
	for x in range(topLeft.x, topLeft.x + size.x):
		for y in range(topLeft.y, topLeft.y + size.y):
			placed[Vector2i(x, y)] = thing


func to_save() -> Dictionary:
	var built := []
	for cell in builtCell:
		built.append({ "item": builtCell[cell].resource_path, "cell": [cell.x, cell.y] })
	
	var objects := []
	for thing in $Props.get_children():
		if thing.has_meta("item"):
			var item: ItemData = thing.get_meta("item")
			var cell := Vector2i(thing.position) / tile_set.tile_size
			
			objects.append({ "item": item.resource_path, "cell": [cell.x, cell.y] })
	
	return { "built": built, "objects": objects }

func load_save(data: Dictionary) -> void:
	for b in data["built"]:
		add_tile(Vector2i(int(b["cell"][0]), int(b["cell"][1])), load(b["item"]))
	
	for o in data["objects"]:
		place_object(load(o["item"]), Vector2i(int(o["cell"][0]), int(o["cell"][1])))
	# all the ints needed cus json gives decimals back. Switch over when new system is added
