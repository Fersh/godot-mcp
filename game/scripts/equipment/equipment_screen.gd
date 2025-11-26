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

const SLOT_NAMES = {
	ItemData.Slot.HELMET: "Helmet",
	ItemData.Slot.WEAPON: "Weapon",
	ItemData.Slot.CHEST: "Chest",
	ItemData.Slot.BOOTS: "Boots",
	ItemData.Slot.RING_1: "Ring",
	ItemData.Slot.RING_2: "Ring"
}

# RPG Colors
const COLOR_BG = Color(0.08, 0.06, 0.1, 1.0)
const COLOR_PANEL = Color(0.12, 0.10, 0.15, 1.0)
const COLOR_BORDER = Color(0.35, 0.28, 0.18, 1.0)
const COLOR_TEXT = Color(0.9, 0.85, 0.75, 1.0)
const COLOR_TEXT_DIM = Color(0.55, 0.50, 0.42, 1.0)
const COLOR_EQUIPPED_HIGHLIGHT = Color(0.9, 0.8, 0.2, 0.3)
const COLOR_SELECTED = Color(1.0, 1.0, 1.0, 1.0)
const COLOR_STAT_UP = Color(0.3, 0.9, 0.3)
const COLOR_STAT_DOWN = Color(0.9, 0.3, 0.3)

var selected_character: String = "archer"
var selected_item: ItemData = null
var popup_item: ItemData = null
var pixel_font: Font = null

@onready var header: PanelContainer = $Header
@onready var back_button: Button = $BackButton
@onready var character_tabs: HBoxContainer = $Panel/VBoxContainer/CharacterTabs
@onready var equipment_panel: PanelContainer = $Panel/VBoxContainer/MainRow/LeftColumn/EquipmentPanel
@onready var equipment_container: GridContainer = $Panel/VBoxContainer/MainRow/LeftColumn/EquipmentPanel/EquipmentContainer
@onready var stats_panel: PanelContainer = $Panel/VBoxContainer/MainRow/LeftColumn/StatsPanel
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/MainRow/LeftColumn/StatsPanel/StatsContainer
@onready var inventory_panel: PanelContainer = $Panel/VBoxContainer/MainRow/InventoryPanel
@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/MainRow/InventoryPanel/InventorySection/ScrollContainer/CenterContainer/InventoryGrid
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var comparison_panel: PanelContainer = $ComparisonPanel

func _ready() -> void:
	pixel_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	back_button.pressed.connect(_on_back_pressed)

	# Use selected character from CharacterManager if available
	if CharacterManager:
		selected_character = CharacterManager.selected_character_id

	_setup_ui_style()
	_setup_character_tabs()
	_refresh_display()

func _setup_ui_style() -> void:
	# Style header and back button
	_style_header()
	_style_back_button()
	_style_panels()

func _style_panels() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.06, 0.055, 0.09, 0.9)
	panel_style.border_width_left = 2
	panel_style.border_width_right = 2
	panel_style.border_width_top = 2
	panel_style.border_width_bottom = 2
	panel_style.border_color = Color(0.15, 0.14, 0.2, 1)
	panel_style.corner_radius_top_left = 8
	panel_style.corner_radius_top_right = 8
	panel_style.corner_radius_bottom_left = 8
	panel_style.corner_radius_bottom_right = 8
	panel_style.content_margin_left = 12
	panel_style.content_margin_right = 12
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12

	equipment_panel.add_theme_stylebox_override("panel", panel_style)
	stats_panel.add_theme_stylebox_override("panel", panel_style.duplicate())
	inventory_panel.add_theme_stylebox_override("panel", panel_style.duplicate())

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 1)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	header.add_theme_stylebox_override("panel", style)

func _style_back_button() -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.25, 0.25, 0.3, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.15, 0.15, 0.2, 1)
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.35, 0.4, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.2, 0.2, 0.25, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	back_button.add_theme_stylebox_override("normal", style_normal)
	back_button.add_theme_stylebox_override("hover", style_hover)
	back_button.add_theme_stylebox_override("pressed", style_normal)
	back_button.add_theme_stylebox_override("focus", style_normal)

func _style_button(button: Button, base_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.border_color = base_color.darkened(0.4)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	var style_hover = style.duplicate()
	style_hover.bg_color = base_color.lightened(0.15)

	var style_pressed = style.duplicate()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 2

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", COLOR_TEXT)

func _setup_character_tabs() -> void:
	# Clear existing tabs
	for child in character_tabs.get_children():
		child.queue_free()

	# Create tabs for each character
	for char_id in ["archer", "knight"]:
		var tab = Button.new()
		tab.text = char_id.to_upper()
		tab.custom_minimum_size = Vector2(140, 36)
		tab.toggle_mode = true
		tab.button_pressed = (char_id == selected_character)
		tab.pressed.connect(_on_character_tab_pressed.bind(char_id))
		character_tabs.add_child(tab)

		_style_character_tab(tab, char_id == selected_character)

		if pixel_font:
			tab.add_theme_font_override("font", pixel_font)
		tab.add_theme_font_size_override("font_size", 24)

func _style_character_tab(button: Button, is_selected: bool) -> void:
	var style = StyleBoxFlat.new()
	if is_selected:
		style.bg_color = Color(0.25, 0.22, 0.35, 1.0)
		style.border_color = Color(0.6, 0.5, 0.3, 1.0)
		style.border_width_bottom = 4
	else:
		style.bg_color = Color(0.12, 0.10, 0.15, 1.0)
		style.border_color = Color(0.3, 0.25, 0.2, 1.0)
		style.border_width_bottom = 2

	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_color_override("font_color", COLOR_TEXT if is_selected else COLOR_TEXT_DIM)

func _on_character_tab_pressed(char_id: String) -> void:
	selected_character = char_id
	selected_item = null
	_hide_popups()

	# Update tab visuals
	var idx = 0
	for child in character_tabs.get_children():
		if child is Button:
			var is_selected = (idx == 0 and char_id == "archer") or (idx == 1 and char_id == "knight")
			child.button_pressed = is_selected
			_style_character_tab(child, is_selected)
			idx += 1

	_refresh_display()

func _refresh_display() -> void:
	_refresh_equipment_slots()
	_refresh_stats()
	_refresh_inventory()

func _refresh_equipment_slots() -> void:
	# Clear existing slots
	for child in equipment_container.get_children():
		child.queue_free()

	# Create slot buttons in a row
	for slot in SLOT_ORDER:
		var slot_button = _create_equipment_slot(slot)
		equipment_container.add_child(slot_button)

func _create_equipment_slot(slot: ItemData.Slot) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	# Slot label
	var slot_label = Label.new()
	slot_label.text = SLOT_NAMES[slot]
	if pixel_font:
		slot_label.add_theme_font_override("font", pixel_font)
	slot_label.add_theme_font_size_override("font_size", 16)
	slot_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	slot_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	container.add_child(slot_label)

	# Slot button
	var button = Button.new()
	button.custom_minimum_size = Vector2(70, 70)
	button.pressed.connect(_on_equipment_slot_pressed.bind(slot))

	# Get equipped item
	var equipped = EquipmentManager.get_equipped_item(selected_character, slot) if EquipmentManager else null

	# Style the slot
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	if equipped:
		style.border_color = equipped.get_rarity_color()
	else:
		style.border_color = Color(0.25, 0.22, 0.18, 1.0)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style.duplicate())
	button.add_theme_stylebox_override("pressed", style)

	# Add icon or empty indicator
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	if equipped and equipped.icon_path != "" and ResourceLoader.exists(equipped.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(equipped.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(56, 56)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		center.add_child(icon)
	else:
		var empty = Label.new()
		empty.text = "-"
		if pixel_font:
			empty.add_theme_font_override("font", pixel_font)
		empty.add_theme_font_size_override("font_size", 40)
		empty.add_theme_color_override("font_color", Color(0.3, 0.28, 0.25, 1.0))
		center.add_child(empty)

	button.add_child(center)
	container.add_child(button)

	# Item name below (truncated)
	var name_label = Label.new()
	if equipped:
		var display_name = equipped.get_full_name()
		if display_name.length() > 10:
			display_name = display_name.substr(0, 9) + ".."
		name_label.text = display_name
		name_label.add_theme_color_override("font_color", equipped.get_rarity_color())
	else:
		name_label.text = "Empty"
		name_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(70, 0)
	container.add_child(name_label)

	return container

func _on_equipment_slot_pressed(slot: ItemData.Slot) -> void:
	var equipped = EquipmentManager.get_equipped_item(selected_character, slot) if EquipmentManager else null
	if equipped:
		_show_equipped_popup(equipped)
	selected_item = null
	_hide_comparison()

func _refresh_stats() -> void:
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()

	# Header
	var header = Label.new()
	header.text = "- STATS -"
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	header.add_theme_font_size_override("font_size", 18)
	header.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(header)

	# Get total equipment stats
	var stats = {}
	if EquipmentManager:
		stats = EquipmentManager.get_equipment_stats(selected_character)

	# Display stats
	var stat_names = {
		"damage": "Damage",
		"max_hp": "Health",
		"attack_speed": "Attack Speed",
		"move_speed": "Move Speed",
		"crit_chance": "Crit Chance",
		"dodge_chance": "Dodge Chance",
		"damage_reduction": "Defense",
		"xp_gain": "XP Gain",
		"luck": "Luck"
	}

	for stat_key in stat_names:
		var value = stats.get(stat_key, 0.0)
		if abs(value) < 0.001:
			continue

		var row = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = stat_names[stat_key] + ":"
		if pixel_font:
			name_label.add_theme_font_override("font", pixel_font)
		name_label.add_theme_font_size_override("font_size", 14)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var value_label = Label.new()
		var value_str = ""
		if stat_key in ["crit_chance", "dodge_chance", "damage_reduction", "attack_speed", "move_speed", "damage", "max_hp", "xp_gain", "luck"]:
			value_str = "%+d%%" % int(value * 100)
		else:
			value_str = "%+d" % int(value)
		value_label.text = value_str
		if pixel_font:
			value_label.add_theme_font_override("font", pixel_font)
		value_label.add_theme_font_size_override("font_size", 14)
		value_label.add_theme_color_override("font_color", COLOR_STAT_UP if value > 0 else COLOR_STAT_DOWN)
		row.add_child(value_label)

		stats_container.add_child(row)

	if stats.size() == 0:
		var empty = Label.new()
		empty.text = "No bonuses"
		if pixel_font:
			empty.add_theme_font_override("font", pixel_font)
		empty.add_theme_font_size_override("font_size", 14)
		empty.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(empty)

func _refresh_inventory() -> void:
	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()

	if not EquipmentManager:
		return

	# Get all inventory items
	var items = EquipmentManager.inventory

	# Create 48 slots (12 columns x 4 rows for landscape)
	var total_slots = 48

	for i in range(total_slots):
		if i < items.size():
			# Create item card
			var card = _create_inventory_card(items[i])
			inventory_grid.add_child(card)
		else:
			# Create empty slot
			var empty_slot = _create_empty_slot()
			inventory_grid.add_child(empty_slot)

func _create_empty_slot() -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(60, 60)
	button.disabled = true

	# Style - dark empty slot
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.05, 0.08, 1.0)
	style.border_color = Color(0.2, 0.18, 0.15, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("disabled", style)

	return button

func _create_inventory_card(item: ItemData) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(60, 60)
	button.pressed.connect(_on_inventory_item_pressed.bind(item))

	# Style
	var style = StyleBoxFlat.new()

	# Check if item is equipped
	var is_equipped = item.equipped_by != ""

	if is_equipped:
		# Yellow highlight for equipped items
		style.bg_color = COLOR_EQUIPPED_HIGHLIGHT
	else:
		style.bg_color = Color(0.08, 0.07, 0.1, 1.0)

	style.border_color = item.get_rarity_color()
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	var style_hover = style.duplicate()
	style_hover.border_color = COLOR_SELECTED

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

	# Icon
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(48, 48)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		center.add_child(icon)
	else:
		var placeholder = ColorRect.new()
		placeholder.color = item.get_rarity_color()
		placeholder.custom_minimum_size = Vector2(36, 36)
		center.add_child(placeholder)

	button.add_child(center)

	# Equipped indicator in corner
	if is_equipped:
		var indicator = Label.new()
		indicator.text = item.equipped_by.substr(0, 1).to_upper()
		if pixel_font:
			indicator.add_theme_font_override("font", pixel_font)
		indicator.add_theme_font_size_override("font_size", 16)
		indicator.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		indicator.position = Vector2(2, 1)
		button.add_child(indicator)

	return button

func _on_inventory_item_pressed(item: ItemData) -> void:
	_hide_popups()

	if item.equipped_by != "":
		# Show equipped item popup
		popup_item = item
		_show_equipped_popup(item)
	else:
		# Show comparison with currently equipped
		selected_item = item
		_show_comparison(item)

func _show_equipped_popup(item: ItemData) -> void:
	popup_item = item
	_hide_comparison()

	# Clear popup
	for child in popup_panel.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)

	# Item name
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Equipped by
	var equipped_label = Label.new()
	equipped_label.text = "Equipped by: %s" % item.equipped_by.capitalize()
	if pixel_font:
		equipped_label.add_theme_font_override("font", pixel_font)
	equipped_label.add_theme_font_size_override("font_size", 20)
	equipped_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	equipped_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(equipped_label)

	# Item stats
	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)

	var stat_display_names = {
		"damage": "Damage",
		"max_hp": "Health",
		"attack_speed": "Attack Speed",
		"move_speed": "Move Speed",
		"crit_chance": "Crit Chance",
		"dodge_chance": "Dodge Chance",
		"damage_reduction": "Defense",
		"xp_gain": "XP Gain",
		"luck": "Luck"
	}

	for stat_key in item.stats:
		var value = item.stats[stat_key]
		if abs(value) < 0.001:
			continue

		var stat_row = HBoxContainer.new()

		var stat_name = Label.new()
		stat_name.text = stat_display_names.get(stat_key, stat_key) + ":"
		if pixel_font:
			stat_name.add_theme_font_override("font", pixel_font)
		stat_name.add_theme_font_size_override("font_size", 16)
		stat_name.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		stat_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_row.add_child(stat_name)

		var stat_value = Label.new()
		stat_value.text = "%+d%%" % int(value * 100)
		if pixel_font:
			stat_value.add_theme_font_override("font", pixel_font)
		stat_value.add_theme_font_size_override("font_size", 16)
		stat_value.add_theme_color_override("font_color", COLOR_STAT_UP if value > 0 else COLOR_STAT_DOWN)
		stat_row.add_child(stat_value)

		stats_vbox.add_child(stat_row)

	vbox.add_child(stats_vbox)

	# Buttons
	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 16)

	var unequip_btn = Button.new()
	unequip_btn.text = "UNEQUIP"
	unequip_btn.custom_minimum_size = Vector2(180, 50)
	_style_button(unequip_btn, Color(0.5, 0.3, 0.2))
	if pixel_font:
		unequip_btn.add_theme_font_override("font", pixel_font)
	unequip_btn.add_theme_font_size_override("font_size", 18)
	unequip_btn.pressed.connect(_on_unequip_popup_pressed)
	button_row.add_child(unequip_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(180, 50)
	_style_button(cancel_btn, Color(0.3, 0.3, 0.35))
	if pixel_font:
		cancel_btn.add_theme_font_override("font", pixel_font)
	cancel_btn.add_theme_font_size_override("font_size", 18)
	cancel_btn.pressed.connect(_hide_popups)
	button_row.add_child(cancel_btn)

	vbox.add_child(button_row)

	# Style popup
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.15, 0.12, 0.18, 0.98)
	popup_style.border_color = item.get_rarity_color()
	popup_style.set_border_width_all(3)
	popup_style.corner_radius_top_left = 4
	popup_style.corner_radius_top_right = 4
	popup_style.corner_radius_bottom_left = 4
	popup_style.corner_radius_bottom_right = 4
	popup_style.content_margin_left = 12
	popup_style.content_margin_right = 12
	popup_style.content_margin_top = 8
	popup_style.content_margin_bottom = 8
	popup_panel.add_theme_stylebox_override("panel", popup_style)

	popup_panel.add_child(vbox)
	popup_panel.visible = true

	# Position popup in center of screen
	popup_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - popup_panel.size.x) / 2,
		(get_viewport().get_visible_rect().size.y - popup_panel.size.y) / 2 - 50
	)

func _show_comparison(item: ItemData) -> void:
	_hide_popups()
	popup_panel.visible = false

	# Get currently equipped item in same slot
	var equipped = EquipmentManager.get_equipped_item(selected_character, item.slot) if EquipmentManager else null
	var comparison = EquipmentManager.compare_items(item, equipped) if EquipmentManager else {}

	# Clear comparison panel
	for child in comparison_panel.get_children():
		child.queue_free()

	var main_hbox = HBoxContainer.new()
	main_hbox.add_theme_constant_override("separation", 16)

	# New item card
	var new_card = _create_comparison_card(item, true, comparison)
	main_hbox.add_child(new_card)

	# VS separator
	var vs_label = Label.new()
	vs_label.text = "VS"
	if pixel_font:
		vs_label.add_theme_font_override("font", pixel_font)
	vs_label.add_theme_font_size_override("font_size", 20)
	vs_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	main_hbox.add_child(vs_label)

	# Equipped card
	if equipped:
		var equipped_card = _create_comparison_card(equipped, false, {})
		main_hbox.add_child(equipped_card)
	else:
		var empty_card = VBoxContainer.new()
		var empty_label = Label.new()
		empty_label.text = "Empty Slot"
		if pixel_font:
			empty_label.add_theme_font_override("font", pixel_font)
		empty_label.add_theme_font_size_override("font_size", 18)
		empty_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		empty_card.add_child(empty_label)
		main_hbox.add_child(empty_card)

	# Buttons at bottom
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.add_child(main_hbox)

	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)

	# Check if can equip
	var can_equip = item.can_be_equipped_by(selected_character)

	var equip_btn = Button.new()
	equip_btn.text = "EQUIP" if can_equip else "WRONG CLASS"
	equip_btn.custom_minimum_size = Vector2(140, 45)
	equip_btn.disabled = not can_equip
	_style_button(equip_btn, Color(0.2, 0.5, 0.3) if can_equip else Color(0.3, 0.3, 0.3))
	if pixel_font:
		equip_btn.add_theme_font_override("font", pixel_font)
	equip_btn.add_theme_font_size_override("font_size", 16)
	equip_btn.pressed.connect(_on_equip_comparison_pressed)
	button_row.add_child(equip_btn)

	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(140, 45)
	_style_button(cancel_btn, Color(0.4, 0.3, 0.25))
	if pixel_font:
		cancel_btn.add_theme_font_override("font", pixel_font)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_hide_comparison)
	button_row.add_child(cancel_btn)

	vbox.add_child(button_row)

	# Style comparison panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.12, 0.98)
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(4)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 12
	comparison_panel.add_theme_stylebox_override("panel", panel_style)

	comparison_panel.add_child(vbox)
	comparison_panel.visible = true

	# Position in center
	await get_tree().process_frame
	comparison_panel.position = Vector2(
		(get_viewport().get_visible_rect().size.x - comparison_panel.size.x) / 2,
		(get_viewport().get_visible_rect().size.y - comparison_panel.size.y) / 2
	)

func _create_comparison_card(item: ItemData, show_arrows: bool, comparison: Dictionary) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	# Compact width for landscape
	card.custom_minimum_size = Vector2(200, 0)

	# Header
	var header = Label.new()
	header.text = "* NEW *" if show_arrows else "- EQUIPPED -"
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(header)

	# Icon
	var icon_center = CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(40, 40)
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(36, 36)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_center.add_child(icon)
	card.add_child(icon_center)

	# Name
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(name_label)

	# Rarity
	var rarity_label = Label.new()
	rarity_label.text = "%s %s" % [item.get_rarity_name(), item.get_slot_name()]
	if pixel_font:
		rarity_label.add_theme_font_override("font", pixel_font)
	rarity_label.add_theme_font_size_override("font_size", 12)
	rarity_label.add_theme_color_override("font_color", item.get_rarity_color().darkened(0.2))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(rarity_label)

	# Separator
	var sep = ColorRect.new()
	sep.color = item.get_rarity_color()
	sep.custom_minimum_size = Vector2(0, 2)
	card.add_child(sep)

	# Stats with arrows
	var stats_text = item.get_stat_description()
	var stat_lines = stats_text.split("\n")

	for line in stat_lines:
		if line.strip_edges() == "":
			continue

		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_CENTER

		var stat_label = Label.new()
		stat_label.text = line
		if pixel_font:
			stat_label.add_theme_font_override("font", pixel_font)
		stat_label.add_theme_font_size_override("font_size", 12)
		stat_label.add_theme_color_override("font_color", COLOR_TEXT)
		row.add_child(stat_label)

		# Add arrow if showing comparison
		if show_arrows and comparison.size() > 0:
			for stat_key in comparison:
				var stat_display = stat_key.replace("_", " ").to_lower()
				if line.to_lower().contains(stat_display) or line.to_lower().contains(stat_key.to_lower()):
					var diff = comparison[stat_key].diff
					if abs(diff) > 0.001:
						var arrow = Label.new()
						arrow.text = " ^" if diff > 0 else " v"
						if pixel_font:
							arrow.add_theme_font_override("font", pixel_font)
						arrow.add_theme_font_size_override("font_size", 12)
						arrow.add_theme_color_override("font_color", COLOR_STAT_UP if diff > 0 else COLOR_STAT_DOWN)
						row.add_child(arrow)
					break

		card.add_child(row)

	# Description
	if item.description != "":
		var desc = Label.new()
		desc.text = "\"%s\"" % item.description
		if pixel_font:
			desc.add_theme_font_override("font", pixel_font)
		desc.add_theme_font_size_override("font_size", 11)
		desc.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc)

	return card

func _on_unequip_popup_pressed() -> void:
	if popup_item and EquipmentManager:
		EquipmentManager.unequip_item_from_character(popup_item.equipped_by, popup_item.slot)
		_hide_popups()
		_refresh_display()

func _on_equip_comparison_pressed() -> void:
	if selected_item and EquipmentManager:
		EquipmentManager.equip_item(selected_item.id, selected_character, selected_item.slot)
		if SoundManager:
			SoundManager.play_buff()
		_hide_comparison()
		selected_item = null
		_refresh_display()

func _hide_popups() -> void:
	popup_panel.visible = false
	popup_item = null

func _hide_comparison() -> void:
	comparison_panel.visible = false
	selected_item = null

func _on_back_pressed() -> void:
	emit_signal("back_pressed")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if popup_panel.visible or comparison_panel.visible:
				_hide_popups()
				_hide_comparison()
			else:
				_on_back_pressed()
