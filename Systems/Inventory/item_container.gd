extends RefCounted
class_name  ItemContainer

signal changed

var slots: Array[ItemData] = []
var counts: Array[int] = []

func _init(size: int) -> void:
	slots.resize(size)
	counts.resize(size)


func add_item(item: ItemData) -> bool:
	return stack_item(item) or place_item(item)
	
func stack_item(item: ItemData) -> bool:
	for i in counts.size():
		if slots[i] == item:
			if counts[i] > 0 and counts[i] < item.maxStack:
				counts[i] += 1
				changed.emit()
				return true
	return false
	
func place_item(item: ItemData) -> bool:
	for i in slots.size():
		if slots[i] == null:
			counts[i] = 1
			slots[i] = item
			changed.emit()
			return true
	return false

func count_of(item: ItemData) -> int:
	var total := 0
	for i in slots.size():
		if item == slots[i]:
			total += counts[i]
	
	return total

func remove_item(item: ItemData, amount: int) -> bool:
	if count_of(item) < amount:
		return false
	
	for i in slots.size():
		if slots[i] == item:
			
			var take := mini(counts[i], amount)
			counts[i] -= take
			amount -= take
			if counts[i] <= 0:
				slots[i] = null
			
			if amount <= 0:
				break
	
	changed.emit()
	
	return true
	


func swap(index: int, other: ItemContainer, otherIndex: int) -> void:
	var tempItem: = slots[index]
	var tempCount := counts[index]
	slots[index] = other.slots[otherIndex]
	counts[index] = other.counts[otherIndex]
	other.slots[otherIndex] = tempItem
	other.counts[otherIndex] = tempCount
	changed.emit()
	other.changed.emit()
	

func merge(index: int, other: ItemContainer, otherIndex: int) -> bool:
	var item := slots[index]
	if item == null or item != other.slots[otherIndex]:
		return false
	var moving := mini(item.maxStack - counts[index], other.counts[otherIndex])
	if moving <= 0:
		return false
	counts[index] += moving
	other.counts[otherIndex] -= moving
	if other.counts[otherIndex] <= 0:
		other.slots[otherIndex] = null
	changed.emit()
	other.changed.emit()
	return true
