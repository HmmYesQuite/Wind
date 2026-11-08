extends Node

const SAVE_PATH := "user://save.json"

var saveQueued := false

func save_game() -> void:
	var data := {"version": 1, "unlocks": get_unlocks(), "inventory": get_inventory(), "ships": get_ships(), "player": get_player(),}
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
	for vessel: Vessel in get_tree().get_nodes_in_group("vessels"):
		if ships.has(String(vessel.name)):
			vessel.load_save(ships[String(vessel.name)])

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
