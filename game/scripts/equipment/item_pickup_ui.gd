extends CanvasLayer

signal item_equipped(item: ItemData)
signal item_picked_up(item: ItemData)

var current_dropped_item: DroppedItem = null
var current_item: ItemData = null
var pixel_font: Font = null

# RPG color palette
const COLOR_BG_DARK = Color(0.08, 0.06, 0.12, 0.95)
const COLOR_BG_PANEL = Color(0.12, 0.10, 0.18, 1.0)
const COLOR_BORDER = Color(0.35, 0.25, 0.15, 1.0)
const COLOR_BORDER_LIGHT = Color(0.55, 0.45, 0.25, 1.0)
const COLOR_TEXT = Color(0.9, 0.85, 0.75, 1.0)
const COLOR_TEXT_DIM = Color(0.6, 0.55, 0.45, 1.0)
const COLOR_STAT_UP = Color(0.3, 0.9, 0.3)
const COLOR_STAT_DOWN = Color(0.9, 0.3, 0.3)

@onready var panel: PanelContainer = $Panel
@onready var item_display: VBoxContainer = $Panel/MainVBox/HBoxContainer/ItemDisplay
@onready var comparison_display: VBoxContainer = $Panel/MainVBox/HBoxContainer/ComparisonDisplay
@onready var equip_button: Button = $Panel/MainVBox/ButtonContainer/EquipButton
@onready var pickup_button: Button = $Panel/MainVBox/ButtonContainer/PickupButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Load pixel font
	pixel_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	equip_button.pressed.connect(_on_equip_pressed)
	pickup_button.pressed.connect(_on_pickup_pressed)

	# Style the UI
	_setup_rpg_style()

func _setup_rpg_style() -> void:
	# Style the main panel with RPG look
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_BG_PANEL
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 6
	panel_style.border_color = COLOR_BORDER
	panel_style.corner_radius_top_left = 2
	panel_style.corner_radius_top_right = 2
	panel_style.corner_radius_bottom_left = 2
	panel_style.corner_radius_bottom_right = 2
	panel_style.shadow_color = Color(0, 0, 0, 0.5)
	panel_style.shadow_size = 8
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style buttons with RPG golden look
	_style_rpg_button(equip_button, Color(0.2, 0.6, 0.3))
	_style_rpg_button(pickup_button, Color(0.5, 0.4, 0.2))

func _style_rpg_button(button: Button, base_color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = base_color
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = base_color.darkened(0.4)
	style_normal.corner_radius_top_left = 2
	style_normal.corner_radius_top_right = 2
	style_normal.corner_radius_bottom_left = 2
	style_normal.corner_radius_bottom_right = 2

	var style_hover = style_normal.duplicate()
	style_hover.bg_color = base_color.lightened(0.15)

	var style_pressed = style_normal.duplicate()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 2

	var style_disabled = style_normal.duplicate()
	style_disabled.bg_color = Color(0.3, 0.3, 0.3)
	style_disabled.border_color = Color(0.2, 0.2, 0.2)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_stylebox_override("focus", style_normal)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 32)
	button.add_theme_color_override("font_color", COLOR_TEXT)
	button.add_theme_color_override("font_hover_color", Color(1, 1, 0.9))
	button.add_theme_color_override("font_pressed_color", COLOR_TEXT)
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5))

func show_item(dropped_item: DroppedItem, show_comparison: bool = true) -> void:
	current_dropped_item = dropped_item
	current_item = dropped_item.get_item_data()

	if current_item == null:
		return

	# Get equipped item for comparison
	var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"
	var equipped = EquipmentManager.get_equipped_item(character_id, current_item.slot) if EquipmentManager else null

	# Calculate comparison data
	var comparison = {}
	if equipped:
		comparison = EquipmentManager.compare_items(current_item, equipped)

	# Count stats for height matching
	var new_stat_count = current_item.get_stat_description().count("\n") + 1
	var equipped_stat_count = equipped.get_stat_description().count("\n") + 1 if equipped else 0
	var max_stats = max(new_stat_count, equipped_stat_count)

	# Build the display with comparison arrows on new item
	_build_item_display(comparison, max_stats)

	# Only show comparison if there's something equipped in that slot
	if show_comparison and equipped:
		_build_comparison_display(equipped, max_stats)
		comparison_display.visible = true
		$Panel/MainVBox/HBoxContainer/VSeparator.visible = true
	else:
		# Clear and hide comparison
		for child in comparison_display.get_children():
			child.queue_free()
		comparison_display.visible = false
		$Panel/MainVBox/HBoxContainer/VSeparator.visible = false

	# Update button states
	_update_buttons()

	# Show and pause
	visible = true
	get_tree().paused = true

func hide_ui() -> void:
	visible = false
	get_tree().paused = false
	current_dropped_item = null
	current_item = null

func _build_item_display(comparison: Dictionary, max_stats: int) -> void:
	# Clear existing content
	for child in item_display.get_children():
		child.queue_free()

	# Wait for nodes to be freed
	await get_tree().process_frame

	# Create new content with comparison arrows
	var content = _create_item_card(current_item, true, comparison, max_stats)
	item_display.add_child(content)

func _build_comparison_display(equipped: ItemData, max_stats: int) -> void:
	# Clear existing content
	for child in comparison_display.get_children():
		child.queue_free()

	# Show equipped item (no comparison arrows - they're on the new item)
	var equipped_card = _create_item_card(equipped, false, {}, max_stats)
	comparison_display.add_child(equipped_card)

func _create_item_card(item: ItemData, is_new: bool, comparison: Dictionary, max_stats: int) -> Control:
	var card = VBoxContainer.new()
	card.add_theme_constant_override("separation", 4)
	card.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	# Header with "NEW!" or "EQUIPPED" - pixel style
	var header_label = Label.new()
	header_label.text = "* NEW ITEM *" if is_new else "- EQUIPPED -"
	if pixel_font:
		header_label.add_theme_font_override("font", pixel_font)
	header_label.add_theme_font_size_override("font_size", 22)
	header_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	header_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(header_label)

	# Item icon container - smaller, pixel-perfect
	var icon_container = CenterContainer.new()
	icon_container.custom_minimum_size = Vector2(48, 48)

	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(32, 32)
		icon.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_container.add_child(icon)
	else:
		# Placeholder colored square
		var placeholder = ColorRect.new()
		placeholder.color = item.get_rarity_color()
		placeholder.custom_minimum_size = Vector2(32, 32)
		icon_container.add_child(placeholder)

	card.add_child(icon_container)

	# Rarity and slot - above title
	var info_label = Label.new()
	info_label.text = "%s %s" % [item.get_rarity_name(), item.get_slot_name()]
	if pixel_font:
		info_label.add_theme_font_override("font", pixel_font)
	info_label.add_theme_font_size_override("font_size", 18)
	info_label.add_theme_color_override("font_color", item.get_rarity_color().darkened(0.2))
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	card.add_child(info_label)

	# Item name with rarity color - pixel font
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 24)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	card.add_child(name_label)

	# Pixel separator
	var separator = ColorRect.new()
	separator.color = item.get_rarity_color()
	separator.custom_minimum_size = Vector2(0, 2)
	card.add_child(separator)

	# Stats container with comparison arrows
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 2)

	# Parse stats and show with arrows if this is the new item
	var stats_text = item.get_stat_description()
	var stat_lines = stats_text.split("\n")

	for line in stat_lines:
		if line.strip_edges() == "":
			continue
		var stat_row = _create_stat_row(line, is_new, comparison)
		stats_container.add_child(stat_row)

	# Pad to max_stats for consistent height
	var current_count = stat_lines.size()
	for i in range(current_count, max_stats):
		var spacer = Control.new()
		spacer.custom_minimum_size = Vector2(0, 16)
		stats_container.add_child(spacer)

	card.add_child(stats_container)

	# Description (if any)
	if item.description != "":
		var desc_label = Label.new()
		desc_label.text = "\"%s\"" % item.description
		if pixel_font:
			desc_label.add_theme_font_override("font", pixel_font)
		desc_label.add_theme_font_size_override("font_size", 20)
		desc_label.add_theme_color_override("font_color", Color(0.8, 0.75, 0.5))
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		card.add_child(desc_label)

	return card

func _create_stat_row(stat_line: String, show_arrows: bool, comparison: Dictionary) -> Control:
	var row = HBoxContainer.new()
	row.alignment = BoxContainer.ALIGNMENT_CENTER

	# Try to find what stat this line represents
	var arrow_text = ""
	var arrow_color = COLOR_TEXT

	if show_arrows and comparison.size() > 0:
		# Match stat name from the line to comparison data
		for stat_key in comparison:
			var stat_display = stat_key.replace("_", " ").to_lower()
			if stat_line.to_lower().contains(stat_display) or stat_line.to_lower().contains(stat_key.to_lower()):
				var diff = comparison[stat_key].diff
				if abs(diff) > 0.001:
					if diff > 0:
						arrow_text = " ^"
						arrow_color = COLOR_STAT_UP
					else:
						arrow_text = " v"
						arrow_color = COLOR_STAT_DOWN
				break

	var stat_label = Label.new()
	stat_label.text = stat_line
	if pixel_font:
		stat_label.add_theme_font_override("font", pixel_font)
	stat_label.add_theme_font_size_override("font_size", 24)
	stat_label.add_theme_color_override("font_color", COLOR_TEXT)
	row.add_child(stat_label)

	if arrow_text != "":
		var arrow_label = Label.new()
		arrow_label.text = arrow_text
		if pixel_font:
			arrow_label.add_theme_font_override("font", pixel_font)
		arrow_label.add_theme_font_size_override("font_size", 24)
		arrow_label.add_theme_color_override("font_color", arrow_color)
		row.add_child(arrow_label)

	return row

func _update_buttons() -> void:
	if current_item == null:
		return

	# Check if item can be equipped by current character
	var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"
	var can_equip = current_item.can_be_equipped_by(character_id)

	equip_button.disabled = not can_equip

	if not can_equip:
		equip_button.text = "WRONG CLASS"
		equip_button.tooltip_text = "This item cannot be used by your current character"
	else:
		equip_button.text = "EQUIP [E]"
		equip_button.tooltip_text = ""

func _on_equip_pressed() -> void:
	if current_dropped_item == null or current_item == null:
		return

	var character_id = CharacterManager.selected_character_id if CharacterManager else "archer"

	# Add to pending and equip
	EquipmentManager.add_pending_item(current_item)
	EquipmentManager.equip_item(current_item.id, character_id, current_item.slot)

	# Award points for item pickup
	var stats_display = get_tree().get_first_node_in_group("stats_display")
	if stats_display == null:
		stats_display = get_node_or_null("/root/Main/StatsDisplay")
	if stats_display and stats_display.has_method("add_item_points"):
		stats_display.add_item_points()

	# Play sound
	if SoundManager:
		SoundManager.play_buff()

	# Remove the world item
	current_dropped_item.queue_free()

	emit_signal("item_equipped", current_item)
	hide_ui()

func _on_pickup_pressed() -> void:
	if current_dropped_item == null or current_item == null:
		return

	# Just add to pending inventory
	EquipmentManager.add_pending_item(current_item)

	# Award points for item pickup
	var stats_display = get_tree().get_first_node_in_group("stats_display")
	if stats_display == null:
		stats_display = get_node_or_null("/root/Main/StatsDisplay")
	if stats_display and stats_display.has_method("add_item_points"):
		stats_display.add_item_points()

	# Play sound
	if SoundManager:
		SoundManager.play_xp()

	# Remove the world item
	current_dropped_item.queue_free()

	emit_signal("item_picked_up", current_item)
	hide_ui()

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# ESC to close without picking up
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			hide_ui()
		elif event.keycode == KEY_E:
			if not equip_button.disabled:
				_on_equip_pressed()
		elif event.keycode == KEY_P or event.keycode == KEY_SPACE:
			_on_pickup_pressed()
