extends Node

signal changed


var pockets: Dictionary[String, ItemContainer] = {}
var cursor := ItemContainer.new(1)
var foundUniques: Array[ItemData] = []
var workbenchRange := 24.0

const WORKBENCH := preload("res://Items/Placeable/Workbench/Workbench.tres")
var workbenchUnlocked := false


func _ready() -> void:
	var left := ItemContainer.new(4)
	var right := ItemContainer.new(4)
	
	
	# For testing only
	pockets["LeftPocket"] = left
	pockets["RightPocket"] = right
	
	
	
	left.changed.connect(changed.emit)
	right.changed.connect(changed.emit)
	
	give_starting_items()


func all_containers() -> Array[ItemContainer]:
	var list: Array[ItemContainer] = [Hotbar.container]
	
	list.append_array(pockets.values())
	return list

func add_item(item: ItemData) -> bool:
	for container in all_containers():
		if container.stack_item(item):
			return true
	
	
	
	
	
	for container in all_containers():
		if container.place_item(item):
			return true
	return false

func count_of(item: ItemData) -> int:
	var total := 0
	for container in all_containers():
		total += container.count_of(item)
	return total

func remove_item(item: ItemData, amount: int) -> bool:
	if count_of(item) < amount:
		return false
	
	for container in all_containers():
		var take := mini(container.count_of(item), amount)
		if take > 0:
			container.remove_item(item, take)
			amount -= take
		if amount <= 0:
			break
	
	return true

func return_cursor() -> void:
	var item := cursor.slots[0]
	var count := cursor.counts[0]
	if item == null:
		return
	cursor.remove_item(item, count)
	for n in count:
		add_item(item)

func can_craft(recipe: Recipe) -> bool:
	if recipe.needsWorkbench and not near_workbench():
		return false
	
	for item in recipe.ingredients:
		var needed := recipe.ingredients[item]
		if count_of(item) < needed:
			return false
	return true

func craft(recipe: Recipe) -> void:
	if not can_craft(recipe):
		return
	for item in recipe.ingredients:
		remove_item(item, recipe.ingredients[item])
	
	if recipe.result == WORKBENCH:
		workbenchUnlocked = true
	
	for n in recipe.resultCount:
		add_item(recipe.result)
	
	SaveManager.request_save()


func near_workbench() -> bool:
	var player: DynamicProp = get_tree().get_first_node_in_group("player")
	for bench: Node2D in get_tree().get_nodes_in_group("workbenches"):
		if bench.global_position.distance_to(player.visual.global_position) <= workbenchRange:
			return true
	return false


func give_starting_items() -> void:
	
	Hotbar.add_item(preload("res://Items/FishingRod/fishing_rod.tres"))
	
	#test stuff
	Hotbar.add_item(preload("res://Items/Placeable/Workbench/Workbench.tres"))
	for i in 8:
		Hotbar.add_item(preload("res://Items/Blocks/WoodFrame.tres"))
		Hotbar.add_item(preload("res://Items/Blocks/WoodPlatform.tres"))
	workbenchUnlocked = true


func reset() -> void:
	for container in all_containers():
		container.clear()
	cursor.clear()
	foundUniques.clear()
	workbenchUnlocked = false
	Hotbar.select(0)
	give_starting_items()
