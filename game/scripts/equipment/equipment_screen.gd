extends CanvasLayer

signal back_pressed

# Equipment slots (in order for display)
const SLOT_ORDER = [
	ItemData.Slot.HELMET,
	ItemData.Slot.WEAPON,
	ItemData.Slot.CHEST,
	ItemData.Slot.BOOTS,
	ItemData.Slot.RING_1,
	ItemData.Slot.RING_2
]

const SLOT_ICONS = {
	ItemData.Slot.HELMET: "Helmet",
	ItemData.Slot.WEAPON: "Weapon",
	ItemData.Slot.CHEST: "Chest",
	ItemData.Slot.BOOTS: "Boots",
	ItemData.Slot.RING_1: "Ring 1",
	ItemData.Slot.RING_2: "Ring 2"
}

var selected_character: String = "archer"
var selected_slot: int = -1
var selected_inventory_item: ItemData = null

@onready var back_button: Button = $Panel/VBoxContainer/HeaderContainer/BackButton
@onready var character_tabs: HBoxContainer = $Panel/VBoxContainer/HeaderContainer/CharacterTabs
@onready var equipment_slots: GridContainer = $Panel/VBoxContainer/ContentContainer/EquipmentPanel/EquipmentSlots
@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/ContentContainer/InventoryPanel/ScrollContainer/InventoryGrid
@onready var item_details: VBoxContainer = $Panel/VBoxContainer/ContentContainer/DetailsPanel/ItemDetails
@onready var equip_button: Button = $Panel/VBoxContainer/ContentContainer/DetailsPanel/EquipButton
@onready var unequip_button: Button = $Panel/VBoxContainer/ContentContainer/DetailsPanel/UnequipButton

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	equip_button.pressed.connect(_on_equip_pressed)
	unequip_button.pressed.connect(_on_unequip_pressed)

	_setup_character_tabs()
	_refresh_display()

func _setup_character_tabs() -> void:
	# Clear existing tabs
	for child in character_tabs.get_children():
		child.queue_free()

	# Create tabs for each character
	for char_id in ["archer", "knight"]:
		var tab = Button.new()
		tab.text = char_id.capitalize()
		tab.custom_minimum_size = Vector2(120, 40)
		tab.toggle_mode = true
		tab.button_pressed = (char_id == selected_character)
		tab.pressed.connect(_on_character_tab_pressed.bind(char_id))
		character_tabs.add_child(tab)

		_style_tab_button(tab, char_id == selected_character)

func _style_tab_button(button: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	if is_selected:
		style.bg_color = Color(0.3, 0.3, 0.4, 1.0)
		style.border_color = Color(0.5, 0.5, 0.7, 1.0)
	else:
		style.bg_color = Color(0.15, 0.15, 0.2, 1.0)
		style.border_color = Color(0.3, 0.3, 0.4, 1.0)

	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("pressed", style)

func _on_character_tab_pressed(char_id: String) -> void:
	selected_character = char_id
	selected_slot = -1
	selected_inventory_item = null

	# Update tab visuals
	var idx = 0
	for child in character_tabs.get_children():
		if child is Button:
			child.button_pressed = (idx == 0 and char_id == "archer") or (idx == 1 and char_id == "knight")
			_style_tab_button(child, child.button_pressed)
			idx += 1

	_refresh_display()

func _refresh_display() -> void:
	_refresh_equipment_slots()
	_refresh_inventory()
	_refresh_details()

func _refresh_equipment_slots() -> void:
	# Clear existing slots
	for child in equipment_slots.get_children():
		child.queue_free()

	# Create slot buttons
	for slot in SLOT_ORDER:
		var slot_button = _create_slot_button(slot)
		equipment_slots.add_child(slot_button)

func _create_slot_button(slot: ItemData.Slot) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(100, 120)
	button.pressed.connect(_on_slot_pressed.bind(slot))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	# Get equipped item
	var equipped = EquipmentManager.get_equipped_item(selected_character, slot) if EquipmentManager else null

	# Slot label
	var slot_label = Label.new()
	slot_label.text = SLOT_ICONS[slot]
	slot_label.add_theme_font_size_override("font_size", 12)
	slot_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(slot_label)

	# Icon container
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(64, 64)

	if equipped:
		if equipped.icon_path != "" and ResourceLoader.exists(equipped.icon_path):
			var icon = TextureRect.new()
			icon.texture = load(equipped.icon_path)
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(48, 48)
			icon_container.add_child(icon)

		# Item name
		var name_label = Label.new()
		var display_name = equipped.get_full_name()
		if display_name.length() > 10:
			display_name = display_name.substr(0, 8) + ".."
		name_label.text = display_name
		name_label.add_theme_font_size_override("font_size", 10)
		name_label.add_theme_color_override("font_color", equipped.get_rarity_color())
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(icon_container)
		vbox.add_child(name_label)
	else:
		# Empty slot placeholder
		var empty_label = Label.new()
		empty_label.text = "Empty"
		empty_label.add_theme_font_size_override("font_size", 12)
		empty_label.add_theme_color_override("font_color", Color(0.4, 0.4, 0.4))
		icon_container.add_child(empty_label)
		vbox.add_child(icon_container)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.15, 1.0)
	if equipped:
		style.border_color = equipped.get_rarity_color()
	else:
		style.border_color = Color(0.3, 0.3, 0.3, 1.0)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)

	if slot == selected_slot:
		style.border_color = Color(1.0, 1.0, 1.0, 1.0)
		style.set_border_width_all(3)

	button.add_theme_stylebox_override("normal", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(vbox)
	button.add_child(margin)

	return button

func _on_slot_pressed(slot: ItemData.Slot) -> void:
	selected_slot = slot
	selected_inventory_item = null
	_refresh_display()

func _refresh_inventory() -> void:
	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()

	if not EquipmentManager:
		return

	# Get all inventory items
	var items = EquipmentManager.inventory

	# Filter by selected slot if one is selected
	if selected_slot >= 0:
		items = EquipmentManager.get_items_for_slot(selected_slot)

	# Create item cards
	for item in items:
		var card = _create_inventory_card(item)
		inventory_grid.add_child(card)

	# If no items, show placeholder
	if items.size() == 0:
		var empty = Label.new()
		empty.text = "No items in inventory"
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		inventory_grid.add_child(empty)

func _create_inventory_card(item: ItemData) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(80, 100)
	button.pressed.connect(_on_inventory_item_pressed.bind(item))

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Icon
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(48, 48)

	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40, 40)
		icon_container.add_child(icon)

	vbox.add_child(icon_container)

	# Name
	var name_label = Label.new()
	var display_name = item.get_full_name()
	if display_name.length() > 8:
		display_name = display_name.substr(0, 6) + ".."
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Equipped indicator
	if item.equipped_by != "":
		var equipped_label = Label.new()
		equipped_label.text = "(%s)" % item.equipped_by.substr(0, 1).to_upper()
		equipped_label.add_theme_font_size_override("font_size", 8)
		equipped_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(equipped_label)

	# Style
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 1.0)
	style.border_color = item.get_rarity_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)

	if selected_inventory_item and selected_inventory_item.id == item.id:
		style.border_color = Color(1.0, 1.0, 1.0, 1.0)
		style.set_border_width_all(3)

	button.add_theme_stylebox_override("normal", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 2)
	margin.add_theme_constant_override("margin_right", 2)
	margin.add_theme_constant_override("margin_top", 2)
	margin.add_theme_constant_override("margin_bottom", 2)
	margin.add_child(vbox)
	button.add_child(margin)

	return button

func _on_inventory_item_pressed(item: ItemData) -> void:
	selected_inventory_item = item
	selected_slot = item.slot
	_refresh_display()

func _refresh_details() -> void:
	# Clear existing details
	for child in item_details.get_children():
		child.queue_free()

	# Hide buttons by default
	equip_button.visible = false
	unequip_button.visible = false

	var item_to_show: ItemData = null

	if selected_inventory_item:
		item_to_show = selected_inventory_item
	elif selected_slot >= 0:
		item_to_show = EquipmentManager.get_equipped_item(selected_character, selected_slot) if EquipmentManager else null

	if item_to_show == null:
		var placeholder = Label.new()
		placeholder.text = "Select an item or slot"
		placeholder.add_theme_font_size_override("font_size", 14)
		placeholder.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
		placeholder.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_details.add_child(placeholder)
		return

	# Show item details
	_build_item_details(item_to_show)

	# Show appropriate buttons
	if selected_inventory_item:
		# Can equip if not already equipped by this character
		var can_equip = item_to_show.can_be_equipped_by(selected_character)
		var is_equipped_by_current = item_to_show.equipped_by == selected_character

		equip_button.visible = can_equip and not is_equipped_by_current
		equip_button.disabled = not can_equip

		if item_to_show.equipped_by != "":
			unequip_button.visible = true
			unequip_button.text = "Unequip from %s" % item_to_show.equipped_by.capitalize()
		else:
			unequip_button.visible = false

		if not can_equip:
			equip_button.text = "Wrong Class"
		else:
			equip_button.text = "Equip to %s" % selected_character.capitalize()
	elif selected_slot >= 0:
		var equipped = EquipmentManager.get_equipped_item(selected_character, selected_slot) if EquipmentManager else null
		if equipped:
			unequip_button.visible = true
			unequip_button.text = "Unequip"

func _build_item_details(item: ItemData) -> void:
	# Name
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_details.add_child(name_label)

	# Rarity and slot
	var info_label = Label.new()
	info_label.text = "%s %s" % [item.get_rarity_name(), item.get_slot_name()]
	info_label.add_theme_font_size_override("font_size", 14)
	info_label.add_theme_color_override("font_color", item.get_rarity_color())
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_details.add_child(info_label)

	# Item level
	var level_label = Label.new()
	level_label.text = "Item Level: %d" % item.item_level
	level_label.add_theme_font_size_override("font_size", 12)
	level_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	item_details.add_child(level_label)

	# Separator
	var sep = HSeparator.new()
	item_details.add_child(sep)

	# Stats
	var stats_label = Label.new()
	stats_label.text = item.get_stat_description()
	stats_label.add_theme_font_size_override("font_size", 14)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	item_details.add_child(stats_label)

	# Description
	if item.description != "":
		var desc_label = Label.new()
		desc_label.text = "\"%s\"" % item.description
		desc_label.add_theme_font_size_override("font_size", 12)
		desc_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.5))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		item_details.add_child(desc_label)

	# Equipped status
	if item.equipped_by != "":
		var equipped_label = Label.new()
		equipped_label.text = "Equipped by: %s" % item.equipped_by.capitalize()
		equipped_label.add_theme_font_size_override("font_size", 12)
		equipped_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))
		equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		item_details.add_child(equipped_label)

func _on_equip_pressed() -> void:
	if not selected_inventory_item or not EquipmentManager:
		return

	EquipmentManager.equip_item(selected_inventory_item.id, selected_character, selected_inventory_item.slot)
	_refresh_display()

	if SoundManager:
		SoundManager.play_buff()

func _on_unequip_pressed() -> void:
	if not EquipmentManager:
		return

	if selected_inventory_item and selected_inventory_item.equipped_by != "":
		EquipmentManager.unequip_item_from_character(selected_inventory_item.equipped_by, selected_inventory_item.slot)
	elif selected_slot >= 0:
		EquipmentManager.unequip_item_from_character(selected_character, selected_slot)

	_refresh_display()

func _on_back_pressed() -> void:
	emit_signal("back_pressed")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
