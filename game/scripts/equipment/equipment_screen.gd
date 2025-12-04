extends CanvasLayer

signal back_pressed

# Equipment slots (in order for display)
const SLOT_ORDER = [
	ItemData.Slot.WEAPON,
	ItemData.Slot.HELMET,
	ItemData.Slot.CHEST,
	ItemData.Slot.BELT,
	ItemData.Slot.LEGS,
	ItemData.Slot.RING
]

const SLOT_NAMES = {
	ItemData.Slot.WEAPON: "Weapon",
	ItemData.Slot.HELMET: "Helm",
	ItemData.Slot.CHEST: "Chest",
	ItemData.Slot.BELT: "Belt",
	ItemData.Slot.LEGS: "Legs",
	ItemData.Slot.RING: "Ring"
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
var item_name_font: Font = null
var current_sort: int = EquipmentManager.SortBy.RARITY
var combine_mode: bool = false
var combine_selection: Array[ItemData] = []
var pending_sell_item: ItemData = null
var confirm_dialog: ConfirmationDialog = null

@onready var header: PanelContainer = $Header
@onready var back_button: Button = $BackButton
@onready var main_panel: PanelContainer = $Panel
@onready var character_tabs: HBoxContainer = $Panel/VBoxContainer/CharacterTabs
@onready var equipment_panel: PanelContainer = $Panel/VBoxContainer/MainRow/LeftColumn/EquipmentPanel
@onready var equipment_container: GridContainer = $Panel/VBoxContainer/MainRow/LeftColumn/EquipmentPanel/EquipmentContainer
@onready var stats_panel: PanelContainer = $Panel/VBoxContainer/MainRow/LeftColumn/StatsPanel
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/MainRow/LeftColumn/StatsPanel/StatsContainer
@onready var inventory_panel: PanelContainer = $Panel/VBoxContainer/MainRow/InventoryPanel
@onready var inventory_scroll: ScrollContainer = $Panel/VBoxContainer/MainRow/InventoryPanel/InventorySection/ScrollContainer
@onready var inventory_grid: GridContainer = $Panel/VBoxContainer/MainRow/InventoryPanel/InventorySection/ScrollContainer/InventoryGrid
@onready var popup_panel: PanelContainer = $PopupPanel
@onready var comparison_panel: PanelContainer = $ComparisonPanel

func _ready() -> void:
	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	item_name_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	back_button.pressed.connect(_on_back_pressed)

	# Use selected character from CharacterManager if available
	if CharacterManager:
		selected_character = CharacterManager.selected_character_id

	_setup_confirmation_dialog()
	_setup_ui_style()
	_setup_top_coins_display()
	_setup_character_row()
	_refresh_display()

func _setup_confirmation_dialog() -> void:
	confirm_dialog = ConfirmationDialog.new()
	confirm_dialog.title = "Confirm"
	confirm_dialog.ok_button_text = "Yes"
	confirm_dialog.cancel_button_text = "No"
	add_child(confirm_dialog)

	# Style the dialog
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.07, 0.1, 0.98)
	style.border_color = Color(0.4, 0.35, 0.3, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	confirm_dialog.add_theme_stylebox_override("panel", style)

	if pixel_font:
		confirm_dialog.add_theme_font_override("font", pixel_font)
	confirm_dialog.add_theme_font_size_override("font_size", 16)

func _setup_ui_style() -> void:
	# Style header and back button
	_style_header()
	_style_back_button()
	_style_main_panel()
	_style_panels()

	# Limit inventory scroll height to force scrolling
	if inventory_scroll:
		inventory_scroll.custom_minimum_size = Vector2(520, 412)
		inventory_scroll.set_deferred("size", Vector2(520, 412))

func _style_main_panel() -> void:
	# Make the main panel transparent so background image shows through
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	main_panel.add_theme_stylebox_override("panel", style)

func _style_panels() -> void:
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.02, 0.02, 0.03, 0.95)
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
	style.bg_color = Color(0.06, 0.055, 0.09, 0.0)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 0.0)
	style.content_margin_left = 60
	style.content_margin_right = 60
	header.add_theme_stylebox_override("panel", style)

	# Darken title label shadow
	var title_label = header.find_child("TitleLabel", true, false)
	if title_label:
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		title_label.add_theme_constant_override("shadow_offset_x", 3)
		title_label.add_theme_constant_override("shadow_offset_y", 3)

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
	style_normal.content_margin_left = 16
	style_normal.content_margin_right = 16

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
	style_hover.content_margin_left = 16
	style_hover.content_margin_right = 16

	back_button.add_theme_stylebox_override("normal", style_normal)
	back_button.add_theme_stylebox_override("hover", style_hover)
	back_button.add_theme_stylebox_override("pressed", style_normal)
	back_button.add_theme_stylebox_override("focus", style_normal)

	# Add darker text shadow
	back_button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	back_button.add_theme_constant_override("shadow_offset_x", 2)
	back_button.add_theme_constant_override("shadow_offset_y", 2)

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

const CHARACTER_IDS = ["archer", "knight", "monk", "mage", "beast", "assassin", "barbarian"]
const CHARACTER_NAMES = {
	"archer": "RANGER",
	"knight": "KNIGHT",
	"monk": "MONK",
	"mage": "WIZARD",
	"beast": "BEAST",
	"assassin": "ASSASSIN",
	"barbarian": "BARBARIAN"
}

var character_dropdown: OptionButton = null
var header_sort_button: OptionButton = null
var top_coins_label: Label = null

func _setup_character_row() -> void:
	# Clear existing tabs container and repurpose it as a row
	for child in character_tabs.get_children():
		child.queue_free()

	# Set up the container as a full-width row
	character_tabs.alignment = BoxContainer.ALIGNMENT_BEGIN
	character_tabs.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_tabs.add_theme_constant_override("separation", 10)

	# Left side: Character dropdown + Combine button (no label)
	var left_container = HBoxContainer.new()
	left_container.add_theme_constant_override("separation", 10)

	character_dropdown = OptionButton.new()
	for i in range(CHARACTER_IDS.size()):
		var char_id = CHARACTER_IDS[i]
		character_dropdown.add_item(CHARACTER_NAMES[char_id], i)
	character_dropdown.custom_minimum_size = Vector2(150, 36)
	if pixel_font:
		character_dropdown.add_theme_font_override("font", pixel_font)
	character_dropdown.add_theme_font_size_override("font_size", 16)
	_style_dropdown(character_dropdown)

	# Set current selection
	for i in range(CHARACTER_IDS.size()):
		if CHARACTER_IDS[i] == selected_character:
			character_dropdown.select(i)
			break

	character_dropdown.item_selected.connect(_on_character_selected)
	left_container.add_child(character_dropdown)

	# Combine button next to character select
	combine_button = Button.new()
	combine_button.custom_minimum_size = Vector2(100, 36)
	if pixel_font:
		combine_button.add_theme_font_override("font", pixel_font)
	combine_button.add_theme_font_size_override("font_size", 14)
	_update_combine_button()
	combine_button.pressed.connect(_on_combine_button_pressed)
	left_container.add_child(combine_button)

	character_tabs.add_child(left_container)

	# Spacer to push sort to the right
	var spacer = Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	character_tabs.add_child(spacer)

	# Right side: Sort dropdown with "Sort by " prefix in items
	header_sort_button = OptionButton.new()
	header_sort_button.add_item("Sort by Rarity", EquipmentManager.SortBy.RARITY)
	header_sort_button.add_item("Sort by Category", EquipmentManager.SortBy.CATEGORY)
	header_sort_button.add_item("Sort by Equipped", EquipmentManager.SortBy.EQUIPPED)
	header_sort_button.add_item("Sort by Name", EquipmentManager.SortBy.NAME)
	header_sort_button.add_item("Sort by Level", EquipmentManager.SortBy.ITEM_LEVEL)
	header_sort_button.custom_minimum_size = Vector2(170, 36)
	if pixel_font:
		header_sort_button.add_theme_font_override("font", pixel_font)
	header_sort_button.add_theme_font_size_override("font_size", 16)
	_style_dropdown(header_sort_button)

	# Set current sort selection
	for i in range(header_sort_button.item_count):
		if header_sort_button.get_item_id(i) == current_sort:
			header_sort_button.select(i)
			break

	header_sort_button.item_selected.connect(_on_header_sort_changed)
	character_tabs.add_child(header_sort_button)

	# Align with panels after layout
	_align_character_row.call_deferred()

func _align_character_row() -> void:
	# Wait for layout to complete
	await get_tree().process_frame
	await get_tree().process_frame

	# Get the positions of equipment panel and inventory panel
	var equip_rect = equipment_panel.get_global_rect()
	var inv_rect = inventory_panel.get_global_rect()
	var tabs_rect = character_tabs.get_global_rect()

	# Calculate margins to align character dropdown with equipment panel left edge
	# and sort dropdown with inventory panel right edge
	var left_margin = equip_rect.position.x - tabs_rect.position.x
	var right_margin = tabs_rect.end.x - inv_rect.end.x

	# Create margin container wrapper if needed
	if left_margin > 0 or right_margin > 0:
		# Add padding to the character tabs
		var left_spacer = Control.new()
		left_spacer.custom_minimum_size.x = max(0, left_margin)
		character_tabs.add_child(left_spacer)
		character_tabs.move_child(left_spacer, 0)

		# Adjust the right side by adding margin to the sort button container
		if right_margin > 0:
			var right_spacer = Control.new()
			right_spacer.custom_minimum_size.x = max(0, right_margin)
			character_tabs.add_child(right_spacer)

func _setup_top_coins_display() -> void:
	# Create coins display in top right (matching main menu style)
	var coins_container = HBoxContainer.new()
	coins_container.name = "TopCoinsDisplay"
	coins_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	coins_container.anchor_left = 1.0
	coins_container.anchor_right = 1.0
	coins_container.offset_left = -170
	coins_container.offset_top = 30
	coins_container.offset_right = -70
	coins_container.offset_bottom = 65
	coins_container.grow_horizontal = Control.GROW_DIRECTION_BEGIN
	coins_container.alignment = BoxContainer.ALIGNMENT_END
	coins_container.add_theme_constant_override("separation", 6)

	var coin_icon = Label.new()
	coin_icon.text = "●"
	if pixel_font:
		coin_icon.add_theme_font_override("font", pixel_font)
	coin_icon.add_theme_font_size_override("font_size", 22)
	coin_icon.add_theme_color_override("font_color", Color(1, 0.84, 0))
	coin_icon.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	coin_icon.add_theme_constant_override("shadow_offset_x", 2)
	coin_icon.add_theme_constant_override("shadow_offset_y", 2)
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins_container.add_child(coin_icon)

	top_coins_label = Label.new()
	top_coins_label.text = "%d" % (StatsManager.spendable_coins if StatsManager else 0)
	if pixel_font:
		top_coins_label.add_theme_font_override("font", pixel_font)
	top_coins_label.add_theme_font_size_override("font_size", 18)
	top_coins_label.add_theme_color_override("font_color", Color(1, 1, 1))
	top_coins_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	top_coins_label.add_theme_constant_override("shadow_offset_x", 2)
	top_coins_label.add_theme_constant_override("shadow_offset_y", 2)
	top_coins_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coins_container.add_child(top_coins_label)

	add_child(coins_container)

func _style_dropdown(dropdown: OptionButton) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.13, 0.18, 1)
	style.border_color = Color(0.4, 0.35, 0.3, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 10
	style.content_margin_right = 10
	style.content_margin_top = 4
	style.content_margin_bottom = 4

	var style_hover = style.duplicate()
	style_hover.border_color = Color(0.6, 0.5, 0.4, 1)

	dropdown.add_theme_stylebox_override("normal", style)
	dropdown.add_theme_stylebox_override("hover", style_hover)
	dropdown.add_theme_stylebox_override("pressed", style)
	dropdown.add_theme_stylebox_override("focus", style)
	dropdown.add_theme_color_override("font_color", COLOR_TEXT)

	# Style the popup menu (dropdown items)
	var popup = dropdown.get_popup()
	if popup:
		# Remove radio/check icons by setting them to empty
		popup.hide_on_checkable_item_selection = true
		popup.hide_on_item_selection = true

		# Apply pixel font to popup
		if pixel_font:
			popup.add_theme_font_override("font", pixel_font)
		popup.add_theme_font_size_override("font_size", 16)

		# Style the popup panel
		var popup_style = StyleBoxFlat.new()
		popup_style.bg_color = Color(0.12, 0.10, 0.14, 0.98)
		popup_style.border_color = Color(0.4, 0.35, 0.3, 1)
		popup_style.set_border_width_all(2)
		popup_style.set_corner_radius_all(4)
		popup_style.content_margin_left = 8
		popup_style.content_margin_right = 8
		popup_style.content_margin_top = 8
		popup_style.content_margin_bottom = 8
		popup.add_theme_stylebox_override("panel", popup_style)

		# Style for hover state on items
		var hover_style = StyleBoxFlat.new()
		hover_style.bg_color = Color(0.3, 0.25, 0.35, 1)
		hover_style.set_corner_radius_all(3)
		hover_style.content_margin_left = 14
		hover_style.content_margin_right = 14
		hover_style.content_margin_top = 12
		hover_style.content_margin_bottom = 12
		popup.add_theme_stylebox_override("hover", hover_style)

		# Normal item style (larger padding)
		var normal_style = StyleBoxFlat.new()
		normal_style.bg_color = Color(0, 0, 0, 0)
		normal_style.content_margin_left = 14
		normal_style.content_margin_right = 14
		normal_style.content_margin_top = 12
		normal_style.content_margin_bottom = 12
		popup.add_theme_stylebox_override("normal", normal_style)

		# Increase vertical separation between items
		popup.add_theme_constant_override("v_separation", 12)

		# Set font colors
		popup.add_theme_color_override("font_color", COLOR_TEXT)
		popup.add_theme_color_override("font_hover_color", Color(1, 1, 1))

		# Hide the checkmark/radio icons by making them transparent
		popup.add_theme_constant_override("check_v_offset", 0)
		popup.add_theme_color_override("font_accelerator_color", Color(0, 0, 0, 0))

		# Remove icons from all items (no checkmarks)
		for i in range(popup.item_count):
			popup.set_item_icon(i, null)
			popup.set_item_as_checkable(i, false)

func _on_character_selected(index: int) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	selected_character = CHARACTER_IDS[index]
	selected_item = null
	_hide_popups()
	_hide_comparison()
	if combine_mode:
		_exit_combine_mode()
	_refresh_display()

func _on_header_sort_changed(index: int) -> void:
	if SoundManager:
		SoundManager.play_click()
	current_sort = header_sort_button.get_item_id(index)
	_refresh_inventory()

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
	container.add_theme_constant_override("separation", 8)
	# Set consistent width for all slots (matches width with equipped item) - widened by ~17px
	container.custom_minimum_size = Vector2(107, 0)

	# Slot label
	var slot_label = Label.new()
	slot_label.text = SLOT_NAMES[slot]
	if pixel_font:
		slot_label.add_theme_font_override("font", pixel_font)
	slot_label.add_theme_font_size_override("font_size", 18)
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
		icon.custom_minimum_size = Vector2(45, 45)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		center.add_child(icon)
	else:
		var empty = Label.new()
		empty.text = "-"
		if pixel_font:
			empty.add_theme_font_override("font", pixel_font)
		empty.add_theme_font_size_override("font_size", 42)
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
		# Show "Banned" for Beast's weapon slot (Beast fights unarmed)
		if slot == ItemData.Slot.WEAPON and selected_character == "beast":
			name_label.text = "Banned"
			name_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3))
		else:
			name_label.text = "Empty"
			name_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	if item_name_font:
		name_label.add_theme_font_override("font", item_name_font)
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.custom_minimum_size = Vector2(70, 0)
	container.add_child(name_label)

	return container

func _on_equipment_slot_pressed(slot: ItemData.Slot) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	var equipped = EquipmentManager.get_equipped_item(selected_character, slot) if EquipmentManager else null
	if equipped:
		# Show equipped item popup with full details
		_show_equipped_popup(equipped)
	selected_item = null
	_hide_comparison()

func _refresh_stats() -> void:
	# Clear existing stats
	for child in stats_container.get_children():
		child.queue_free()

	# Header
	var header = Label.new()
	header.text = "Stats"
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	header.add_theme_font_size_override("font_size", 20)
	header.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(header)

	# Get equipment stats
	var equipment_stats = {}
	if EquipmentManager:
		equipment_stats = EquipmentManager.get_equipment_stats(selected_character)

	# Get permanent upgrade bonuses
	var upgrade_bonuses = {}
	if PermanentUpgrades:
		upgrade_bonuses = PermanentUpgrades.get_all_bonuses()

	# Check for curse effects on equipment
	var equipment_mult = 1.0
	var has_equipment_curse = false
	if CurseEffects:
		equipment_mult = CurseEffects.get_equipment_bonus_multiplier()
		has_equipment_curse = equipment_mult < 1.0

	# Combine stats: equipment (with curse multiplier) + permanent upgrades
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
		var equip_value = equipment_stats.get(stat_key, 0.0)
		var upgrade_value = upgrade_bonuses.get(stat_key, 0.0)

		# Apply curse multiplier to equipment stats only
		var cursed_equip_value = equip_value * equipment_mult
		var total_value = cursed_equip_value + upgrade_value

		if abs(total_value) < 0.001:
			continue

		var row = HBoxContainer.new()

		var name_label = Label.new()
		name_label.text = stat_names[stat_key] + ":"
		if pixel_font:
			name_label.add_theme_font_override("font", pixel_font)
		name_label.add_theme_font_size_override("font_size", 16)
		name_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(name_label)

		var value_label = Label.new()
		var value_str = ""
		if stat_key in ["crit_chance", "dodge_chance", "damage_reduction", "attack_speed", "move_speed", "damage", "max_hp", "xp_gain", "luck"]:
			value_str = "%+d%%" % int(total_value * 100)
		else:
			value_str = "%+d" % int(total_value)
		value_label.text = value_str
		if pixel_font:
			value_label.add_theme_font_override("font", pixel_font)
		value_label.add_theme_font_size_override("font_size", 16)

		# Color: pink if cursed equipment stat, otherwise green/red based on value
		var is_stat_cursed = has_equipment_curse and equip_value > 0.001
		if is_stat_cursed:
			value_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.7))  # Pink for cursed
		else:
			value_label.add_theme_color_override("font_color", COLOR_STAT_UP if total_value > 0 else COLOR_STAT_DOWN)
		row.add_child(value_label)

		stats_container.add_child(row)

	# Check if any stats were added (stats_container has header + stats)
	if stats_container.get_child_count() <= 1:
		var empty = Label.new()
		empty.text = "No bonuses"
		if pixel_font:
			empty.add_theme_font_override("font", pixel_font)
		empty.add_theme_font_size_override("font_size", 16)
		empty.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		empty.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		stats_container.add_child(empty)

func _refresh_inventory() -> void:
	# Clear existing items
	for child in inventory_grid.get_children():
		child.queue_free()

	if not EquipmentManager:
		return

	# Get sorted inventory items
	var items = EquipmentManager.get_sorted_inventory(current_sort as EquipmentManager.SortBy)

	# Create 72 slots (6 columns x 12 rows) - scrollable
	var total_slots = 72

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
	button.custom_minimum_size = Vector2(80, 80)
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
	button.custom_minimum_size = Vector2(80, 80)
	button.pressed.connect(_on_inventory_item_pressed.bind(item))

	# Style
	var style = StyleBoxFlat.new()

	# Check if item is equipped
	var is_equipped = item.equipped_by != ""

	# Check combine mode states
	var is_selected_for_combine = combine_mode and item in combine_selection
	var is_combinable = combine_mode and EquipmentManager.can_combine_item(item)
	var is_same_group = false
	if combine_mode and combine_selection.size() > 0:
		var first = combine_selection[0]
		is_same_group = item.slot == first.slot and item.rarity == first.rarity and not is_equipped
		# For weapons, also require same weapon_type
		if is_same_group and item.slot == ItemData.Slot.WEAPON:
			is_same_group = item.weapon_type == first.weapon_type

	if is_selected_for_combine:
		# Purple highlight for selected combine items
		style.bg_color = Color(0.4, 0.2, 0.5, 0.8)
		style.border_color = Color(0.8, 0.5, 1.0)
	elif combine_mode and is_same_group:
		# Subtle highlight for items that can be added to selection
		style.bg_color = Color(0.2, 0.15, 0.25, 0.6)
		style.border_color = item.get_rarity_color()
	elif combine_mode and not is_combinable:
		# Dim non-combinable items
		style.bg_color = Color(0.05, 0.05, 0.07, 0.7)
		style.border_color = item.get_rarity_color().darkened(0.5)
	elif is_equipped:
		# Yellow highlight for equipped items
		style.bg_color = COLOR_EQUIPPED_HIGHLIGHT
		style.border_color = item.get_rarity_color()
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
	if not (combine_mode and not is_combinable and not is_same_group):
		style_hover.border_color = COLOR_SELECTED

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)

	# Dim button in combine mode if not combinable
	if combine_mode and not is_combinable and not is_same_group and not is_selected_for_combine:
		button.modulate = Color(0.5, 0.5, 0.5, 0.8)

	# Icon
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(50, 50)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		center.add_child(icon)
	else:
		var placeholder = ColorRect.new()
		placeholder.color = item.get_rarity_color()
		placeholder.custom_minimum_size = Vector2(48, 48)
		center.add_child(placeholder)

	button.add_child(center)

	# Equipped indicator in corner (top-left)
	if is_equipped:
		var indicator = Label.new()
		indicator.text = "E"  # E for Equipped
		if pixel_font:
			indicator.add_theme_font_override("font", pixel_font)
		indicator.add_theme_font_size_override("font_size", 18)
		indicator.add_theme_color_override("font_color", Color(1, 0.9, 0.3))
		indicator.position = Vector2(2, 1)
		button.add_child(indicator)

	# Combine mode indicators
	if combine_mode:
		var has_selection = combine_selection.size() > 0

		# Show checkmark if: selected OR (has selection and is same group as selected)
		if is_selected_for_combine or (has_selection and is_same_group):
			var check = Label.new()
			check.text = "✓"
			if pixel_font:
				check.add_theme_font_override("font", pixel_font)
			check.add_theme_font_size_override("font_size", 20)
			check.add_theme_color_override("font_color", Color(0.5, 1.0, 0.5))
			check.position = Vector2(56, 54)
			button.add_child(check)
		# Only show count numbers when NO item is selected yet
		elif not has_selection and is_combinable:
			var count = EquipmentManager.get_combinable_count(item)
			if count >= 3:
				var count_label = Label.new()
				count_label.text = "%d" % count
				if pixel_font:
					count_label.add_theme_font_override("font", pixel_font)
				count_label.add_theme_font_size_override("font_size", 14)
				count_label.add_theme_color_override("font_color", Color(0.7, 0.5, 1.0))
				count_label.position = Vector2(60, 2)
				button.add_child(count_label)

	return button

func _on_inventory_item_pressed(item: ItemData) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	# Handle combine mode
	if combine_mode:
		_handle_combine_selection(item)
		return

	_hide_popups()

	if item.equipped_by != "":
		# Show equipped item popup
		popup_item = item
		_show_equipped_popup(item)
	else:
		# Show comparison with currently equipped
		selected_item = item
		_show_comparison(item)

func _handle_combine_selection(item: ItemData) -> void:
	# Can't combine equipped items
	if item.equipped_by != "":
		return

	# Can't combine legendary items
	if item.rarity == ItemData.Rarity.LEGENDARY:
		return

	# If already selected, deselect
	if item in combine_selection:
		combine_selection.erase(item)
		_refresh_inventory()
		return

	# If this is the first selection, just add it
	if combine_selection.size() == 0:
		if EquipmentManager.can_combine_item(item):
			combine_selection.append(item)
			_refresh_inventory()
		return

	# Check if item matches the current selection (same slot + rarity + weapon_type for weapons)
	var first = combine_selection[0]
	var slot_matches = item.slot == first.slot
	var rarity_matches = item.rarity == first.rarity
	var weapon_type_matches = item.slot != ItemData.Slot.WEAPON or item.weapon_type == first.weapon_type

	if not (slot_matches and rarity_matches and weapon_type_matches):
		# Different group - start new selection
		if EquipmentManager.can_combine_item(item):
			combine_selection.clear()
			combine_selection.append(item)
			_refresh_inventory()
		return

	# Add to selection
	combine_selection.append(item)

	# If we have 3, perform the combine!
	if combine_selection.size() >= 3:
		_perform_combine()
	else:
		_refresh_inventory()

func _perform_combine() -> void:
	if combine_selection.size() < 3:
		return

	# Get info for confirmation
	var first_item = combine_selection[0]
	var current_rarity = first_item.get_rarity_name()
	var next_rarity_idx = first_item.rarity + 1
	var next_rarity = ItemData.RARITY_NAMES.get(next_rarity_idx, "Unknown")
	var slot_name = first_item.get_slot_name()

	# Show confirmation dialog
	confirm_dialog.dialog_text = "Combine 3 %s %ss into 1 %s %s?\n\nThis cannot be undone." % [current_rarity, slot_name, next_rarity, slot_name]

	# Disconnect any previous connections and connect fresh
	if confirm_dialog.confirmed.is_connected(_on_sell_confirmed):
		confirm_dialog.confirmed.disconnect(_on_sell_confirmed)
	if confirm_dialog.confirmed.is_connected(_on_combine_confirmed):
		confirm_dialog.confirmed.disconnect(_on_combine_confirmed)

	confirm_dialog.confirmed.connect(_on_combine_confirmed)
	confirm_dialog.popup_centered()

func _on_combine_confirmed() -> void:
	if combine_selection.size() < 3:
		return

	var item_ids: Array = []
	for item in combine_selection:
		item_ids.append(item.id)

	var result = EquipmentManager.combine_items(item_ids)
	if result:
		if SoundManager:
			SoundManager.play_buff()
		if HapticManager:
			HapticManager.medium()
		# Show the result
		_exit_combine_mode()
		_update_coins_display()
		selected_item = result
		_show_comparison(result)
	else:
		# Failed - just refresh
		combine_selection.clear()
		_refresh_inventory()

func _show_equipped_popup(item: ItemData) -> void:
	popup_item = item
	_hide_comparison()

	# Clear popup
	for child in popup_panel.get_children():
		child.queue_free()

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.custom_minimum_size = Vector2(0, 0)

	# Scrollable content area - match comparison view size
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(350, 300)

	var content_vbox = VBoxContainer.new()
	content_vbox.add_theme_constant_override("separation", 4)
	content_vbox.custom_minimum_size = Vector2(350, 0)
	content_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Header - "EQUIPPED BY {CHARACTER}"
	var equipped_name = CHARACTER_NAMES.get(item.equipped_by, item.equipped_by.capitalize())
	var header = Label.new()
	header.text = "- EQUIPPED BY %s -" % equipped_name.to_upper()
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	content_vbox.add_child(header)

	# Icon with margin
	var icon_margin = MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_top", 10)
	icon_margin.add_theme_constant_override("margin_bottom", 10)

	var icon_center = CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(40, 40)
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(29, 29)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_center.add_child(icon)
	icon_margin.add_child(icon_center)
	content_vbox.add_child(icon_margin)

	# Name
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	if item_name_font:
		name_label.add_theme_font_override("font", item_name_font)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(name_label)

	# Rarity
	var rarity_label = Label.new()
	var type_text = item.get_slot_name()
	if item.slot == ItemData.Slot.WEAPON:
		type_text = "%s %s" % [item.get_weapon_type_name(), item.get_slot_name()]
	rarity_label.text = "%s %s" % [item.get_rarity_name(), type_text]
	if pixel_font:
		rarity_label.add_theme_font_override("font", pixel_font)
	rarity_label.add_theme_font_size_override("font_size", 14)
	rarity_label.add_theme_color_override("font_color", item.get_rarity_color().darkened(0.2))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	content_vbox.add_child(rarity_label)

	# Separator with margin
	var sep_container = MarginContainer.new()
	sep_container.add_theme_constant_override("margin_top", 8)
	sep_container.add_theme_constant_override("margin_bottom", 8)
	var sep = ColorRect.new()
	var sep_color = item.get_rarity_color()
	sep_color.a = 0.5
	sep.color = sep_color
	sep.custom_minimum_size = Vector2(0, 2)
	sep_container.add_child(sep)
	content_vbox.add_child(sep_container)

	# Stats using get_stat_description() - same as comparison card
	var stats_margin = MarginContainer.new()
	stats_margin.add_theme_constant_override("margin_left", 20)
	stats_margin.add_theme_constant_override("margin_right", 20)

	var stats_vbox = VBoxContainer.new()
	stats_vbox.add_theme_constant_override("separation", 4)

	var stats_text = item.get_stat_description()
	var stat_lines = stats_text.split("\n")

	for line in stat_lines:
		if line.strip_edges() == "":
			continue

		var is_special = line.to_lower().begins_with("special:")

		# Add margin above special text
		if is_special:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 20)
			stats_vbox.add_child(spacer)

		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN if is_special else BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var stat_label = Label.new()
		stat_label.text = line
		if pixel_font:
			stat_label.add_theme_font_override("font", pixel_font)
		stat_label.add_theme_font_size_override("font_size", 14)
		stat_label.add_theme_color_override("font_color", COLOR_TEXT)
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_special:
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(stat_label)

		stats_vbox.add_child(row)

	stats_margin.add_child(stats_vbox)
	content_vbox.add_child(stats_margin)

	# Description
	if item.description != "":
		var desc_spacer = Control.new()
		desc_spacer.custom_minimum_size = Vector2(0, 20)
		content_vbox.add_child(desc_spacer)

		var desc = Label.new()
		desc.text = "\"%s\"" % item.description
		if pixel_font:
			desc.add_theme_font_override("font", pixel_font)
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		content_vbox.add_child(desc)

	scroll.add_child(content_vbox)
	vbox.add_child(scroll)

	# Buttons fixed at bottom - match comparison view styling
	var button_margin = MarginContainer.new()
	button_margin.add_theme_constant_override("margin_top", 16)
	button_margin.add_theme_constant_override("margin_bottom", 12)

	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)

	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(110, 45)
	_style_button(cancel_btn, Color(0.4, 0.3, 0.25))
	if pixel_font:
		cancel_btn.add_theme_font_override("font", pixel_font)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_hide_popups)
	button_row.add_child(cancel_btn)

	var unequip_btn = Button.new()
	unequip_btn.text = "UNEQUIP"
	unequip_btn.custom_minimum_size = Vector2(110, 45)
	_style_button(unequip_btn, Color(0.5, 0.3, 0.2))
	if pixel_font:
		unequip_btn.add_theme_font_override("font", pixel_font)
	unequip_btn.add_theme_font_size_override("font_size", 16)
	unequip_btn.pressed.connect(_on_unequip_popup_pressed)
	button_row.add_child(unequip_btn)

	button_margin.add_child(button_row)
	vbox.add_child(button_margin)

	# Style popup - match comparison view styling
	var popup_style = StyleBoxFlat.new()
	popup_style.bg_color = Color(0.1, 0.08, 0.12, 1.0)
	popup_style.border_color = COLOR_BORDER
	popup_style.set_border_width_all(4)
	popup_style.corner_radius_top_left = 4
	popup_style.corner_radius_top_right = 4
	popup_style.corner_radius_bottom_left = 4
	popup_style.corner_radius_bottom_right = 4
	popup_style.content_margin_left = 16
	popup_style.content_margin_right = 16
	popup_style.content_margin_top = 12
	popup_style.content_margin_bottom = 0
	popup_panel.add_theme_stylebox_override("panel", popup_style)

	popup_panel.add_child(vbox)
	popup_panel.visible = true

	# Position in center like comparison view
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	var max_height = min(popup_panel.size.y, viewport_size.y * 0.7)
	scroll.custom_minimum_size.y = min(scroll.custom_minimum_size.y, max_height - 80)
	popup_panel.size.y = min(popup_panel.size.y, max_height)

	popup_panel.position = Vector2(
		(viewport_size.x - popup_panel.size.x) / 2,
		(viewport_size.y - popup_panel.size.y) / 2
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

	# Main container with max height
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)
	vbox.custom_minimum_size = Vector2(0, 0)

	# Scrollable content area with fixed width and max height
	var scroll = ScrollContainer.new()
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	scroll.custom_minimum_size = Vector2(750, 300)

	# Fixed width container for consistent modal size
	var main_hbox = HBoxContainer.new()
	main_hbox.custom_minimum_size = Vector2(750, 0)
	main_hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	main_hbox.add_theme_constant_override("separation", 16)

	# New item card - takes exactly half
	var new_card = _create_comparison_card(item, true, comparison)
	new_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	new_card.size_flags_stretch_ratio = 1.0
	main_hbox.add_child(new_card)

	# VS separator - fixed width, doesn't expand
	var vs_label = Label.new()
	vs_label.text = "VS"
	if pixel_font:
		vs_label.add_theme_font_override("font", pixel_font)
	vs_label.add_theme_font_size_override("font_size", 22)
	vs_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	vs_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	vs_label.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	main_hbox.add_child(vs_label)

	# Equipped card - takes exactly half
	var equipped_card: Control
	if equipped:
		equipped_card = _create_comparison_card(equipped, false, {})
	else:
		equipped_card = VBoxContainer.new()
		var empty_label = Label.new()
		empty_label.text = "Empty Slot"
		if pixel_font:
			empty_label.add_theme_font_override("font", pixel_font)
		empty_label.add_theme_font_size_override("font_size", 20)
		empty_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
		empty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		equipped_card.add_child(empty_label)
	equipped_card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	equipped_card.size_flags_stretch_ratio = 1.0
	main_hbox.add_child(equipped_card)

	scroll.add_child(main_hbox)
	vbox.add_child(scroll)

	# Buttons fixed at bottom (not in scroll)
	var button_margin = MarginContainer.new()
	button_margin.add_theme_constant_override("margin_top", 16)
	button_margin.add_theme_constant_override("margin_bottom", 12)

	var button_row = HBoxContainer.new()
	button_row.alignment = BoxContainer.ALIGNMENT_CENTER
	button_row.add_theme_constant_override("separation", 12)

	# Check if can equip
	var can_equip = item.can_be_equipped_by(selected_character)

	var cancel_btn = Button.new()
	cancel_btn.text = "CANCEL"
	cancel_btn.custom_minimum_size = Vector2(110, 45)
	_style_button(cancel_btn, Color(0.4, 0.3, 0.25))
	if pixel_font:
		cancel_btn.add_theme_font_override("font", pixel_font)
	cancel_btn.add_theme_font_size_override("font_size", 16)
	cancel_btn.pressed.connect(_hide_comparison)
	button_row.add_child(cancel_btn)

	# Sell button - only for unequipped items
	if item.equipped_by == "":
		var sell_price = EquipmentManager.get_sell_price(item) if EquipmentManager else 0
		var sell_btn = Button.new()
		sell_btn.text = "SELL ●%d" % sell_price
		sell_btn.custom_minimum_size = Vector2(110, 45)
		_style_button(sell_btn, Color(0.6, 0.4, 0.2))
		if pixel_font:
			sell_btn.add_theme_font_override("font", pixel_font)
		sell_btn.add_theme_font_size_override("font_size", 16)
		sell_btn.pressed.connect(_on_sell_pressed.bind(item))
		button_row.add_child(sell_btn)

	var equip_btn = Button.new()
	equip_btn.text = "EQUIP" if can_equip else "WRONG CLASS"
	equip_btn.custom_minimum_size = Vector2(110, 45)
	equip_btn.disabled = not can_equip
	_style_button(equip_btn, Color(0.2, 0.5, 0.3) if can_equip else Color(0.3, 0.3, 0.3))
	if pixel_font:
		equip_btn.add_theme_font_override("font", pixel_font)
	equip_btn.add_theme_font_size_override("font_size", 16)
	equip_btn.pressed.connect(_on_equip_comparison_pressed)
	button_row.add_child(equip_btn)

	button_margin.add_child(button_row)
	vbox.add_child(button_margin)

	# Style comparison panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.1, 0.08, 0.12, 1.0)
	panel_style.border_color = COLOR_BORDER
	panel_style.set_border_width_all(4)
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.content_margin_left = 16
	panel_style.content_margin_right = 16
	panel_style.content_margin_top = 12
	panel_style.content_margin_bottom = 0
	comparison_panel.add_theme_stylebox_override("panel", panel_style)

	comparison_panel.add_child(vbox)
	comparison_panel.visible = true

	# Position in center and constrain size
	await get_tree().process_frame
	var viewport_size = get_viewport().get_visible_rect().size
	var max_height = min(comparison_panel.size.y, viewport_size.y * 0.7)
	scroll.custom_minimum_size.y = min(scroll.custom_minimum_size.y, max_height - 80)
	comparison_panel.size.y = min(comparison_panel.size.y, max_height)

	comparison_panel.position = Vector2(
		(viewport_size.x - comparison_panel.size.x) / 2,
		(viewport_size.y - comparison_panel.size.y) / 2
	)

func _create_comparison_card(item: ItemData, show_arrows: bool, comparison: Dictionary) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Header
	var header = Label.new()
	header.text = "* NEW *" if show_arrows else "- EQUIPPED -"
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	header.add_theme_font_size_override("font_size", 16)
	header.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(header)

	# Icon with margin
	var icon_margin = MarginContainer.new()
	icon_margin.add_theme_constant_override("margin_top", 10)
	icon_margin.add_theme_constant_override("margin_bottom", 10)

	var icon_center = CenterContainer.new()
	icon_center.custom_minimum_size = Vector2(40, 40)
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(29, 29)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_center.add_child(icon)
	icon_margin.add_child(icon_center)
	card.add_child(icon_margin)

	# Name
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	if item_name_font:
		name_label.add_theme_font_override("font", item_name_font)
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(name_label)

	# Rarity
	var rarity_label = Label.new()
	var type_text = item.get_slot_name()
	if item.slot == ItemData.Slot.WEAPON:
		type_text = "%s %s" % [item.get_weapon_type_name(), item.get_slot_name()]
	rarity_label.text = "%s %s" % [item.get_rarity_name(), type_text]
	if pixel_font:
		rarity_label.add_theme_font_override("font", pixel_font)
	rarity_label.add_theme_font_size_override("font_size", 14)
	rarity_label.add_theme_color_override("font_color", item.get_rarity_color().darkened(0.2))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rarity_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(rarity_label)

	# Separator with margin
	var sep_container = MarginContainer.new()
	sep_container.add_theme_constant_override("margin_top", 8)
	sep_container.add_theme_constant_override("margin_bottom", 8)
	var sep = ColorRect.new()
	var sep_color = item.get_rarity_color()
	sep_color.a = 0.5  # 50% transparent
	sep.color = sep_color
	sep.custom_minimum_size = Vector2(0, 2)
	sep_container.add_child(sep)
	card.add_child(sep_container)

	# Stats with arrows
	var stats_text = item.get_stat_description()
	var stat_lines = stats_text.split("\n")

	for line in stat_lines:
		if line.strip_edges() == "":
			continue

		var is_special = line.to_lower().begins_with("special:")

		# Add margin above special text
		if is_special:
			var spacer = Control.new()
			spacer.custom_minimum_size = Vector2(0, 20)
			card.add_child(spacer)

		var row = HBoxContainer.new()
		row.alignment = BoxContainer.ALIGNMENT_BEGIN if is_special else BoxContainer.ALIGNMENT_CENTER
		row.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		var stat_label = Label.new()
		stat_label.text = line
		if pixel_font:
			stat_label.add_theme_font_override("font", pixel_font)
		stat_label.add_theme_font_size_override("font_size", 14)
		stat_label.add_theme_color_override("font_color", COLOR_TEXT)
		stat_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		stat_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if is_special:
			stat_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		row.add_child(stat_label)

		# Add arrow if showing comparison
		if show_arrows and comparison.size() > 0:
			for stat_key in comparison:
				var stat_display = stat_key.replace("_", " ").to_lower()
				if line.to_lower().contains(stat_display) or line.to_lower().contains(stat_key.to_lower()):
					var diff = comparison[stat_key].diff
					if abs(diff) > 0.001:
						var arrow = Label.new()
						arrow.text = " ▲" if diff > 0 else " ▼"
						if pixel_font:
							arrow.add_theme_font_override("font", pixel_font)
						arrow.add_theme_font_size_override("font_size", 14)
						arrow.add_theme_color_override("font_color", COLOR_STAT_UP if diff > 0 else COLOR_STAT_DOWN)
						arrow.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
						row.add_child(arrow)
					break

		card.add_child(row)

	# Description
	if item.description != "":
		var desc_spacer = Control.new()
		desc_spacer.custom_minimum_size = Vector2(0, 20)
		card.add_child(desc_spacer)

		var desc = Label.new()
		desc.text = "\"%s\"" % item.description
		if pixel_font:
			desc.add_theme_font_override("font", pixel_font)
		desc.add_theme_font_size_override("font_size", 13)
		desc.add_theme_color_override("font_color", Color(0.7, 0.65, 0.5))
		desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc)

	return card

func _on_unequip_popup_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	if popup_item and EquipmentManager:
		EquipmentManager.unequip_item_from_character(popup_item.equipped_by, popup_item.slot)
		_hide_popups()
		_refresh_display()

func _on_equip_comparison_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	if selected_item and EquipmentManager:
		EquipmentManager.equip_item(selected_item.id, selected_character, selected_item.slot)
		if SoundManager:
			SoundManager.play_buff()
		_hide_comparison()
		selected_item = null
		_refresh_display()

func _on_sell_pressed(item: ItemData) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if item and EquipmentManager:
		var sell_price = EquipmentManager.get_sell_price(item)
		pending_sell_item = item

		# Show confirmation dialog
		confirm_dialog.dialog_text = "Sell %s for %d coins?\n\nThis cannot be undone." % [item.get_full_name(), sell_price]

		# Disconnect any previous connections and connect fresh
		if confirm_dialog.confirmed.is_connected(_on_sell_confirmed):
			confirm_dialog.confirmed.disconnect(_on_sell_confirmed)
		if confirm_dialog.confirmed.is_connected(_on_combine_confirmed):
			confirm_dialog.confirmed.disconnect(_on_combine_confirmed)

		confirm_dialog.confirmed.connect(_on_sell_confirmed)
		confirm_dialog.popup_centered()

func _on_sell_confirmed() -> void:
	if pending_sell_item and EquipmentManager:
		var coins = EquipmentManager.sell_item(pending_sell_item.id)
		if coins > 0:
			if SoundManager:
				SoundManager.play_xp()
			if HapticManager:
				HapticManager.medium()
			_hide_comparison()
			selected_item = null
			_update_coins_display()
			_refresh_display()
	pending_sell_item = null

func _hide_popups() -> void:
	popup_panel.visible = false
	popup_item = null

func _hide_comparison() -> void:
	comparison_panel.visible = false
	selected_item = null

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	emit_signal("back_pressed")
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			if combine_mode:
				_exit_combine_mode()
			elif popup_panel.visible or comparison_panel.visible:
				_hide_popups()
				_hide_comparison()
			else:
				_on_back_pressed()

# ============= INVENTORY HEADER WITH SORT & ACTIONS =============

var combine_button: Button = null

func _style_option_button(button: OptionButton) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.13, 0.18, 1)
	style.border_color = Color(0.3, 0.28, 0.35, 1)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 8
	style.content_margin_right = 8

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style)
	button.add_theme_stylebox_override("pressed", style)
	button.add_theme_stylebox_override("focus", style)
	button.add_theme_color_override("font_color", COLOR_TEXT)

func _update_combine_button() -> void:
	if not combine_button:
		return

	var combinable_groups = EquipmentManager.get_combinable_groups() if EquipmentManager else {}
	var has_combinable = combinable_groups.size() > 0

	combine_button.disabled = false  # Reset first

	if combine_mode:
		combine_button.text = "CANCEL"
		_style_button(combine_button, Color(0.5, 0.3, 0.2))
	elif has_combinable:
		combine_button.text = "COMBINE"
		_style_button(combine_button, Color(0.4, 0.3, 0.6))
	else:
		combine_button.text = "COMBINE"
		_style_button(combine_button, Color(0.25, 0.25, 0.3))
		combine_button.disabled = true

func _on_combine_button_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if combine_mode:
		_exit_combine_mode()
	else:
		_enter_combine_mode()

func _enter_combine_mode() -> void:
	combine_mode = true
	combine_selection.clear()
	_hide_popups()
	_hide_comparison()
	_update_combine_button()
	_refresh_inventory()

func _exit_combine_mode() -> void:
	combine_mode = false
	combine_selection.clear()
	_update_combine_button()
	_refresh_inventory()

func _update_coins_display() -> void:
	if top_coins_label and StatsManager:
		top_coins_label.text = "%d" % StatsManager.spendable_coins
