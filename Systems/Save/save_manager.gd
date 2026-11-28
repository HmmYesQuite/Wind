extends Node

const SAVE_PATH := "user://save.dat"
const VERSION := 3 #just in case someone had an old save file and they need to be updated.
const SAVE_FLAGS := PROPERTY_USAGE_SCRIPT_VARIABLE | PROPERTY_USAGE_STORAGE

var saveQueued := false


func save_game() -> void:
	var level := get_tree().current_scene
	
	var fixed := {}
	
	for node in get_tree().get_nodes_in_group("persist"):
		
		if node.is_in_group("spawned"):
			continue
		
		fixed[key_of(node)] = collect(node)
	
	var spawned := []
	for node in get_tree().get_nodes_in_group("spawned"):
		spawned.append({
			"scene": node.scene_file_path,
			"name": node.name,
			"parent": level.get_path_to(node.get_parent()),
			"data": collect(node),
		})
	
	var data := {
		"version": VERSION,
		"fixed": fixed,
		"spawned": spawned,
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
	
	var level := get_tree().current_scene
	var spawnedData: Array = data.get("spawned", [])
	
	# rebuilds everything built, eventually need to make it so this dosnt get overloaded with huge save files
	var made := []
	for entry in spawnedData:
		var node: Node = load(entry["scene"]).instantiate()
		node.name = entry["name"]
		spawn(node, level.get_node(entry["parent"]))
		
		made.append(node)
	
	# fill them in, seperate so no data is missing from the full list
	for i in made.size():
		apply(made[i], spawnedData[i]["data"])
	
	var fixed: Dictionary = data["fixed"]
	for node in get_tree().get_nodes_in_group("persist"):
		if node.is_in_group("spawned"):
			continue
		
		var key := key_of(node)
		if fixed.has(key):
			apply(node, fixed[key])

func collect(node: Object) -> Dictionary:
	var data := {}
	
	for prop in node.get_property_list():
		var usage: int = prop["usage"]
		if (usage & SAVE_FLAGS) != SAVE_FLAGS or (usage & PROPERTY_USAGE_EDITOR):
			continue
		
		var value = node.get(prop["name"])
		if value is Resource:
			value = value.resource_path
		
		data[prop["name"]] = value
	
	if node.has_method("to_save"):
		data["custom"] = node.to_save()
	
	return data

func apply(node: Object, data: Dictionary) -> void:
	
	for prop in node.get_property_list():
		var propName: String = prop["name"]
		
		if not data.has(propName):
			continue
		
		var value = data[propName]
		if prop["type"] == TYPE_OBJECT and value is String:
			value = load(value) if value != "" else null
		
		node.set(propName, value)
	
	if data.has("custom") and node.has_method("load_save"):
		node.load_save(data["custom"])

func key_of(node: Node) -> String:
	if node.has_method("save_key"):
		return node.save_key()
	return String(get_tree().current_scene.get_path_to(node))

func spawn(node: Node, parent: Node) -> void:
	node.add_to_group("spawned")
	parent.add_child(node, true)

func new_game() -> void:
	DirAccess.remove_absolute(SAVE_PATH)
	Inventory.reset()
	get_tree().paused = false
	get_tree().reload_current_scene()


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
	
