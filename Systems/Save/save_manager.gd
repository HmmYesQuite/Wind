extends Node

const SAVE_PATH := "user://save.dat"
const VERSION := 2 #just in case someone had an old save file and they need to be updated.

var saveQueued := false


func save_game() -> void:
	var fixed := {}
	
	for node in get_tree().get_nodes_in_group("persist"):
		fixed[node.save_key()] = node.to_save()
	
	var data := {
		"version": VERSION,
		"fixed": fixed,
	}
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_var(data)

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return #save path is not found
	
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	var data = file.get_var() #has to be = not := cus it can be any type
	
	if not(data is Dictionary) or data.get("version") != VERSION:
		return # different version or wrong data type (version should allready check this)
	
	var fixed: Dictionary = data["fixed"]
	for node in get_tree().get_nodes_in_group("persist"):
		var key: String = node.save_key()
		if fixed.has(key):
			node.load_save(fixed[key])

func get_unlocks() -> Dictionary:
	var uniques: Array[String] = []
	for item in Inventory.foundUniques:
		uniques.append(item.resource_path)
	return { "workbench": Inventory.workbenchUnlocked, "foundUniques": uniques }


func set_unlocks(unlocks: Dictionary) -> void:
	Inventory.workbenchUnlocked = unlocks["workbench"]
	Inventory.foundUniques.clear()
	for path in unlocks["foundUniques"]:
		Inventory.foundUniques.append(load(path))


func new_game() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	Inventory.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


func get_ships() -> Dictionary:
	var ships := {}
	for vessel: Vessel in get_tree().get_nodes_in_group("vessels"):
		ships[String(vessel.name)] = vessel.to_save()
	return ships

func set_ships(ships: Dictionary) -> void:
	var level := get_tree().current_scene
	for shipName in ships:
		var data: Dictionary = ships[shipName]
		var vessel: Vessel = level.get_node_or_null(shipName)
		if vessel == null:
			if not data.has("scene"):
				continue
			
			vessel = load(data["scene"]).instantiate()
			vessel.name = shipName
			level.add_child(vessel)
		
		vessel.load_save(data)

func get_player() -> Dictionary:
	var player: DynamicProp = get_tree().get_first_node_in_group("player")
	if player.vessel == null:
		return {}
	return { "ship": String(player.vessel.name), "position": [player.position.x, player.position.y] }


func set_player(data: Dictionary) -> void:
	var player: DynamicProp = get_tree().get_first_node_in_group("player")
	for vessel: Vessel in get_tree().get_nodes_in_group("vessels"):
		if String(vessel.name) == data["ship"]:
			if player.vessel != vessel:
				player.transfer_to(vessel)
			player.position = Vector2(data["position"][0], data["position"][1])
			player.velocity = Vector2.ZERO
			player.reset_physics_interpolation()
			player.visual.global_position = vessel.to_global(player.position)
			
			player.visual.reset_physics_interpolation()

func request_save() -> void:
	if saveQueued:
		return
	saveQueued = true
	await get_tree().create_timer(1.0).timeout
	saveQueued = false
	save_game()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		save_game()

func get_time() -> float:
	var dayNight: DayNight = get_tree().get_first_node_in_group("day_night")
	if dayNight == null:
		return 0.0
	return dayNight.time

func set_time(time: float) -> void:
	var dayNight: DayNight = get_tree().get_first_node_in_group("day_night")
	if dayNight != null:
		dayNight.time = time

func get_lanterns() -> Dictionary:
	var lanterns := {}
	for lantern: Lantern in get_tree().get_nodes_in_group("lanterns"):
		lanterns[String(lantern.get_path())] = lantern.lit
	return lanterns

func set_lanterns(lanterns: Dictionary) -> void:
	for lantern: Lantern in get_tree().get_nodes_in_group("lanterns"):
		var path := String(lantern.get_path())
		if lanterns.has(path):
			lantern.set_lit(lanterns[path])

func get_ropes() -> Array:
	var ropes := []
	for rope: Rope in get_tree().get_nodes_in_group("ropes"):
		ropes.append({
			"item": rope.item.resource_path,
			"a": String(get_tree().current_scene.get_path_to(rope.vesselA)),
			"tileA": [rope.tileA.x, rope.tileA.y],
			"b": String(get_tree().current_scene.get_path_to(rope.vesselB)),
			"tileB": [rope.tileB.x, rope.tileB.y],
			"length": rope.ropeLength,
		})
	return ropes

func set_ropes(ropes: Array) -> void:
	var level := get_tree().current_scene
	for data in ropes:
		var item: ItemData = load(data["item"])
		var rope: Rope = item.placeScene.instantiate()
		
		rope.item = item
		rope.vesselA = level.get_node(data["a"])
		rope.tileA = Vector2i(int(data["tileA"][0]), int(data["tileA"][1]))
		
		rope.vesselB = level.get_node(data["b"])
		rope.tileB = Vector2i(int(data["tileB"][0]), int(data["tileB"][1]))
		
		rope.ropeLength = data["length"]
		level.add_child(rope)

func get_terrain() -> Dictionary:
	var terrain: TerrainGenerator = get_tree().get_first_node_in_group("terrain")
	return terrain.to_save() if terrain else {}

func set_terrain(data: Dictionary) -> void:
	var terrain: TerrainGenerator = get_tree().get_first_node_in_group("terrain")
	if terrain and not data.is_empty():
		terrain.load_save(data)
