extends CanvasLayer

const SLOT_SCENE := preload("res://UI/item_slot.tscn")

const CRAFTING_ART := preload("res://Assets/Ui assets/CraftingMenu.png")
const STORAGE_ART := preload("res://Assets/Ui assets/StorageMenu.png")
const TILE_LIGHT := preload("res://Assets/Ui assets/StorageTileLight.png")
const TILE_DARK := preload("res://Assets/Ui assets/StorageTileDark.png")
const TILE_BACKGROUND := preload("res://Assets/Ui assets/StorageTileBackground.png")
const ARROW := preload("res://Assets/Ui assets/CraftingArrow.png")

@onready var body: Control = %Body
@onready var slotGrid: Control = %Slots
@onready var storageSelector: TextureRect = %StorageSelector
@onready var background: TextureRect = $Root/Background
@onready var tabs: TabContainer = %Tabs
@onready var scroll: ScrollContainer = $Root/Background/Tabs/Crafting/Scroll

@onready var cursorLayer: CanvasLayer = $CursorLayer
@onready var cursorSlot: ItemSlot = %Cursor

@export var recipes: Array[Recipe] = []
@onready var recipeList: VBoxContainer = %RecipeList

var shownPart := ""


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	cursorLayer.visible = false
	tabs.tabs_visible = false
	
	%CraftingTab.pressed.connect(open_tab.bind(0))
	%StorageTab.pressed.connect(open_tab.bind(1))
	
	for area in body.get_children():
		var areaName := String(area.name)
		if Inventory.pockets.has(areaName):
			area.mouse_entered.connect(show_part.bind(areaName))
	
	Inventory.changed.connect(refresh)
	Hotbar.changed.connect(refresh)
	Inventory.cursor.changed.connect(refresh)
	refresh()
	Inventory.return_cursor()
	
	style_scrollbar()

func show_part(part: String) -> void:
	shownPart = part
	storageSelector.position = body.get_node(part).position - Vector2(1, 1)
	storageSelector.visible = true
	
	refresh()

func open_tab(index: int) -> void:
	tabs.current_tab = index
	if index == 0:
		background.texture = CRAFTING_ART
	else:
		background.texture = STORAGE_ART


func _input(event: InputEvent) -> void:
	
	if event.is_action_pressed("inventory"):
		
		visible = not visible
		cursorLayer.visible = visible
		if visible:
			refresh()
		if not visible:
			Inventory.return_cursor()
		
		GameInput.blocked = visible
		
		get_viewport().set_input_as_handled()

func _exit_tree() -> void:
	GameInput.blocked = false
	


func fill_slots(box: Control, container: ItemContainer) -> void:
	for child in box.get_children():
		child.queue_free()
		
	
	for i in container.slots.size():
		var back := TextureRect.new()
		
		back.texture = TILE_BACKGROUND
		back.mouse_filter = Control.MOUSE_FILTER_IGNORE
		back.position = slot_position(i) - Vector2(1, 1)
		box.add_child(back)
	
	for i in container.slots.size():
		var slot: ItemSlot = SLOT_SCENE.instantiate()
		
		box.add_child(slot)
		slot.position = slot_position(i)
		slot.custom_minimum_size = Vector2(16, 16)
		var style := StyleBoxTexture.new()
		var column := i % 4
		var row := int(i / 4.0)
		
		style.texture = TILE_DARK if (column + row) % 2 == 0 else TILE_LIGHT
		
		slot.add_theme_stylebox_override("panel", style)
		slot.container = container
		slot.index = i
		slot.show_item(container.slots[i], container.counts[i])

func slot_position(i: int) -> Vector2:
	return Vector2(i % 4, int(i / 4.0)) * 16

func refresh() -> void:
	
	if shownPart != "":
		fill_slots(slotGrid, Inventory.pockets[shownPart])
	
	cursorSlot.show_item(Inventory.cursor.slots[0], Inventory.cursor.counts[0])
	fill_recipes()

func _process(delta: float) -> void:
	cursorSlot.position = cursorSlot.get_global_mouse_position() - cursorSlot.size / 2


func fill_recipes() -> void:
	for child in recipeList.get_children():
		child.queue_free()
	for recipe in recipes:
		if recipe.needsWorkbench and not Inventory.workbenchUnlocked:
			continue
		
		var row := HBoxContainer.new()
		recipeList.add_child(row)
		
		for item in recipe.ingredients:
			var needed := recipe.ingredients[item]
			var slot :=  make_icon(row, item, needed)
			slot.countLabel.text = "%d/%d" % [Inventory.count_of(item), needed]
		
		
		var arrow := TextureRect.new()
		arrow.texture = ARROW
		arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		arrow.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		row.add_child(arrow)
		
		var result := make_icon(row, recipe.result, recipe.resultCount)
		var frame: Control = result.get_parent()
		
		if Inventory.can_craft(recipe):
			frame.mouse_filter = Control.MOUSE_FILTER_STOP
			frame.gui_input.connect(craft_click.bind(recipe))
		else:
			frame.modulate = Color(0.6, 0.6, 0.6)

func craft_click(event: InputEvent, recipe: Recipe) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		Inventory.can_craft(recipe)


func make_icon(row: HBoxContainer, item: ItemData, count: int) -> ItemSlot:
	
	var back:= TextureRect.new()
	back.texture = TILE_BACKGROUND
	back.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	row.add_child(back)
	
	var slot: ItemSlot = SLOT_SCENE.instantiate()
	slot.mouse_filter = Control.MOUSE_FILTER_IGNORE
	back.add_child(slot)
	slot.custom_minimum_size = Vector2(16, 16)
	slot.position = Vector2(1, 1)
	
	var style := StyleBoxTexture.new()
	style.texture = TILE_LIGHT if row.get_child_count() % 2 == 1 else TILE_DARK
	slot.add_theme_stylebox_override("panel", style)
	
	slot.show_item(item, count)
	return slot

func style_scrollbar() -> void:
	var bar := scroll.get_v_scroll_bar()
	bar.add_theme_stylebox_override("scroll", pixel_box(Color("3d3333"), 2))
	bar.add_theme_stylebox_override("scroll_focus", pixel_box(Color("3d3333"), 2))
	bar.add_theme_stylebox_override("grabber", pixel_box(Color("6b544f"), 0))
	bar.add_theme_stylebox_override("grabber_highlight", pixel_box(Color("806f6b"), 0))
	bar.add_theme_stylebox_override("grabber_pressed", pixel_box(Color("614a46"), 0))
	#all the params of the default scroll bar, using colors from godot pallet


func pixel_box(color: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = color
	box.anti_aliasing = false
	box.content_margin_left = width
	box.content_margin_right = width
	return box
