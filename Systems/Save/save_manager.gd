extends Node

const SAVE_PATH := "user://save.json"

var saveQueued := false

func save_game() -> void:
	var data := {
	"version": 1, 
	"unlocks": get_unlocks(), 
	"inventory": get_inventory(), 
	"ships": get_ships(), 
	"player": get_player(),
	"time": get_time(),
	"lanterns": get_lanterns(),
	"ropes": get_ropes(),
	}
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))

func load_game() -> void:
	if not FileAccess.file_exists(SAVE_PATH):
		return
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SAVE_PATH))
	set_unlocks(data["unlocks"])
	if data.has("inventory"):
		set_inventory(data["inventory"])
	if data.has("ships"):
		set_ships(data["ships"])
	if data.has("player") and not data["player"].is_empty():
		set_player(data["player"])
	if data.has("time"):
		set_time(data["time"])
	if data.has("lanterns"):
		set_lanterns(data["lanterns"])
	if data.has("ropes"):
		set_ropes(data["ropes"])
	#all ^ to help if new version is missing or smth and make sure the game dosnt break


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


func get_inventory() -> Dictionary:
	var pockets := {}
	for pocketName in Inventory.pockets:
		pockets[pocketName] = Inventory.pockets[pocketName].to_save()
	return {
		"hotbar": Hotbar.container.to_save(),
		"pockets": pockets,
		"cursor": Inventory.cursor.to_save(),
		"selected": Hotbar.selectedIndex,
	}


func set_inventory(inventory: Dictionary) -> void:
	Hotbar.container.load_save(inventory["hotbar"])
	for pocketName in inventory["pockets"]:
		if Inventory.pockets.has(pocketName):
			Inventory.pockets[pocketName].load_save(inventory["pockets"][pocketName])
	
	Inventory.cursor.load_save(inventory["cursor"])
	Hotbar.select(int(inventory["selected"]))


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
			"a": String(rope.vesselA.name),
			"tileA": [rope.tileA.x, rope.tileA.y],
			"b": String(rope.vesselB.name),
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
