extends Node

signal changed

var pockets: Dictionary[String, ItemContainer] = {}

func _ready() -> void:
	var left := ItemContainer.new(4)
	var right := ItemContainer.new(4)
	
	pockets["LeftPocket"] = left
	pockets["RightPocket"] = right
	
	left.changed.connect(changed.emit)
	right.changed.connect(changed.emit)
	
	var apple := preload("res://Items/TEST Food/Apple.tres")
	for n in 10:
		add_item(apple)
	print(count_of(apple))
	print(pockets["LeftPocket"].counts)


func all_containers() -> Array[ItemContainer]:
	var list: Array[ItemContainer] = [Hotbar.container]
	
	list.append_array(pockets.values())
	return list

func add_item(item: ItemData) -> bool:
	for container in all_containers():
		if container.stack_item(item):
			return true
	
	var order := all_containers()
	
	if item.heldScene == null:
		order.push_back(order.pop_front())
	
	for container in order:
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
