extends CanvasLayer

# Font
var pixel_font = preload("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

# Node references
@onready var back_button: Button = $BackButton
@onready var coin_amount: Label = $MainContainer/Header/CoinsContainer/CoinAmount
@onready var grid_container: GridContainer = $MainContainer/ScrollContainer/MarginContainer/ContentVBox/CenterContainer/GridContainer
@onready var scroll_container: ScrollContainer = $MainContainer/ScrollContainer
@onready var floating_tooltip: PanelContainer = $MainContainer/ScrollContainer/FloatingTooltip
@onready var upgrade_name_label: Label = $MainContainer/ScrollContainer/FloatingTooltip/TooltipContent/UpgradeName
@onready var category_label: Label = $MainContainer/ScrollContainer/FloatingTooltip/TooltipContent/CategoryLabel
@onready var description_label: Label = $MainContainer/ScrollContainer/FloatingTooltip/TooltipContent/Description
@onready var current_label: Label = $MainContainer/ScrollContainer/FloatingTooltip/TooltipContent/CurrentLabel
@onready var tooltip_rank_container: HBoxContainer = $MainContainer/ScrollContainer/FloatingTooltip/TooltipContent/RankContainer
@onready var upgrade_button: Button = $MainContainer/ScrollContainer/FloatingTooltip/TooltipContent/UpgradeButton
@onready var refund_button: Button = $MainContainer/ScrollContainer/MarginContainer/ContentVBox/RefundButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

# State
var selected_upgrade_id: String = ""
var upgrade_tiles: Dictionary = {}  # Maps upgrade_id to tile button

# Category colors - muted and subtle
const CATEGORY_COLORS = {
	0: Color(0.65, 0.35, 0.35, 1),   # Combat - Muted Red
	1: Color(0.35, 0.55, 0.4, 1),    # Survival - Muted Green
	2: Color(0.4, 0.5, 0.65, 1),     # Utility - Muted Blue
	3: Color(0.7, 0.6, 0.35, 1),     # Progression - Muted Gold
	4: Color(0.55, 0.4, 0.65, 1),    # Special - Muted Purple
}


@onready var header: PanelContainer = $MainContainer/Header

func _ready() -> void:
	# Style buttons
	_style_back_button()
	_style_header()
	_style_floating_tooltip()
	_style_refund_button()

	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	refund_button.pressed.connect(_on_refund_pressed)
	confirm_dialog.confirmed.connect(_on_refund_confirmed)
	scroll_container.get_v_scroll_bar().value_changed.connect(_on_scroll_changed)

	if PermanentUpgrades:
		PermanentUpgrades.upgrade_purchased.connect(_on_upgrade_purchased)
		PermanentUpgrades.upgrades_refunded.connect(_on_upgrades_refunded)

	# Populate grid with ALL upgrades
	_populate_all_upgrades()

	# Update coin display
	_update_coin_display()

	# Hide tooltip initially
	floating_tooltip.visible = false

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

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 1)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	header.add_theme_stylebox_override("panel", style)

func _style_refund_button() -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.7, 0.2, 0.2, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 3
	style_normal.border_color = Color(0.4, 0.1, 0.1, 1)
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	style_normal.content_margin_left = 12
	style_normal.content_margin_right = 12
	style_normal.content_margin_top = 8
	style_normal.content_margin_bottom = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.8, 0.25, 0.25, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 3
	style_hover.border_color = Color(0.5, 0.15, 0.15, 1)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	style_hover.content_margin_left = 12
	style_hover.content_margin_right = 12
	style_hover.content_margin_top = 8
	style_hover.content_margin_bottom = 8

	refund_button.add_theme_stylebox_override("normal", style_normal)
	refund_button.add_theme_stylebox_override("hover", style_hover)
	refund_button.add_theme_stylebox_override("pressed", style_normal)
	refund_button.add_theme_stylebox_override("focus", style_normal)
	refund_button.add_theme_color_override("font_color", Color(1, 1, 1, 1))

func _style_floating_tooltip() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.12, 1.0)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.4, 0.35, 0.5, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12

	floating_tooltip.add_theme_stylebox_override("panel", style)

	# Style upgrade button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.5, 0.25, 1)
	btn_style.border_width_left = 2
	btn_style.border_width_right = 2
	btn_style.border_width_top = 2
	btn_style.border_width_bottom = 3
	btn_style.border_color = Color(0.2, 0.35, 0.15, 1)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.35, 0.55, 0.3, 1)
	btn_hover.border_width_left = 2
	btn_hover.border_width_right = 2
	btn_hover.border_width_top = 2
	btn_hover.border_width_bottom = 3
	btn_hover.border_color = Color(0.25, 0.4, 0.2, 1)
	btn_hover.corner_radius_top_left = 4
	btn_hover.corner_radius_top_right = 4
	btn_hover.corner_radius_bottom_left = 4
	btn_hover.corner_radius_bottom_right = 4

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.2, 0.18, 0.15, 0.8)
	btn_disabled.border_width_left = 2
	btn_disabled.border_width_right = 2
	btn_disabled.border_width_top = 2
	btn_disabled.border_width_bottom = 3
	btn_disabled.border_color = Color(0.3, 0.28, 0.25, 1)
	btn_disabled.corner_radius_top_left = 4
	btn_disabled.corner_radius_top_right = 4
	btn_disabled.corner_radius_bottom_left = 4
	btn_disabled.corner_radius_bottom_right = 4

	upgrade_button.add_theme_stylebox_override("normal", btn_style)
	upgrade_button.add_theme_stylebox_override("hover", btn_hover)
	upgrade_button.add_theme_stylebox_override("pressed", btn_style)
	upgrade_button.add_theme_stylebox_override("disabled", btn_disabled)
	upgrade_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.45, 0.4, 1))

func _populate_all_upgrades() -> void:
	# Clear existing tiles
	for child in grid_container.get_children():
		child.queue_free()
	upgrade_tiles.clear()

	if not PermanentUpgrades:
		return

	# Get all upgrades and add them all to the grid
	var all_upgrades = PermanentUpgrades.get_all_upgrades()

	# Sort by category first, then by sort_order within each category
	all_upgrades.sort_custom(func(a, b):
		if a.category != b.category:
			return a.category < b.category
		return a.sort_order < b.sort_order
	)

	for upgrade in all_upgrades:
		var tile = _create_upgrade_tile(upgrade)
		grid_container.add_child(tile)
		upgrade_tiles[upgrade.id] = tile

func _create_upgrade_tile(upgrade) -> Button:
	var tile = Button.new()
	tile.custom_minimum_size = Vector2(200, 95)

	# Margin container to add internal padding - must set anchors AND offsets explicitly
	var margin = MarginContainer.new()
	margin.name = "MarginContainer"
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.set_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 8)
	margin.add_theme_constant_override("margin_right", 8)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create container for tile content
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 14)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Name label - centered via horizontal alignment
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = upgrade.name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# Rank squares - HBox with center alignment, full width
	var rank = PermanentUpgrades.get_rank(upgrade.id)
	var rank_container = HBoxContainer.new()
	rank_container.name = "RankContainer"
	rank_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	rank_container.add_theme_constant_override("separation", 5)
	rank_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Create squares for each rank
	var category_color = CATEGORY_COLORS.get(upgrade.category, Color.WHITE)
	for i in range(upgrade.max_rank):
		var square = ColorRect.new()
		square.name = "Square%d" % i
		square.custom_minimum_size = Vector2(10, 10)
		square.mouse_filter = Control.MOUSE_FILTER_IGNORE

		if i < rank:
			# Filled square
			square.color = category_color
		else:
			# Empty square (outline effect via darker color)
			square.color = Color(0.25, 0.22, 0.18, 1)

		rank_container.add_child(square)

	vbox.add_child(rank_container)

	margin.add_child(vbox)
	tile.add_child(margin)

	# Style tile based on affordability
	var cost = PermanentUpgrades.get_upgrade_cost(upgrade.id)
	var is_maxed = rank >= upgrade.max_rank
	var can_afford = StatsManager.spendable_coins >= cost
	_style_upgrade_tile(tile, upgrade, is_maxed, can_afford)

	# Connect signal
	tile.pressed.connect(_on_tile_pressed.bind(upgrade.id))

	return tile

func _style_upgrade_tile(tile: Button, upgrade, is_maxed: bool, can_afford: bool = true) -> void:
	var category_color = CATEGORY_COLORS.get(upgrade.category, Color.WHITE)

	# Unified background color for all available tiles
	var base_bg = Color(0.1, 0.1, 0.12, 1)

	var style = StyleBoxFlat.new()
	if is_maxed:
		# Maxed - golden glow effect
		style.bg_color = base_bg.lightened(0.15)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.border_color = Color(1.0, 0.85, 0.3, 0.9)
	elif can_afford:
		# Affordable - unified background with category-colored border
		style.bg_color = base_bg
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.border_color = category_color.darkened(0.3)
	else:
		# Can't afford - dimmed gray
		style.bg_color = Color(0.06, 0.06, 0.08, 0.9)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.border_color = Color(0.2, 0.2, 0.25, 0.7)

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = base_bg.lightened(0.1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 3
	style_hover.border_color = category_color
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = base_bg.lightened(0.2)
	style_selected.border_width_left = 3
	style_selected.border_width_right = 3
	style_selected.border_width_top = 3
	style_selected.border_width_bottom = 4
	style_selected.border_color = category_color.lightened(0.2)
	style_selected.corner_radius_top_left = 8
	style_selected.corner_radius_top_right = 8
	style_selected.corner_radius_bottom_left = 8
	style_selected.corner_radius_bottom_right = 8

	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_stylebox_override("hover", style_hover)
	tile.add_theme_stylebox_override("pressed", style_selected)
	tile.add_theme_stylebox_override("focus", style)

	# Dim the tile content if can't afford
	tile.modulate = Color(1, 1, 1, 1) if (can_afford or is_maxed) else Color(0.5, 0.5, 0.55, 1)

func _on_tile_pressed(upgrade_id: String) -> void:
	# Deselect previous tile
	if selected_upgrade_id != "" and upgrade_tiles.has(selected_upgrade_id):
		var prev_tile = upgrade_tiles[selected_upgrade_id]
		var prev_upgrade = PermanentUpgrades.get_upgrade(selected_upgrade_id)
		var prev_rank = PermanentUpgrades.get_rank(selected_upgrade_id)
		var prev_cost = PermanentUpgrades.get_upgrade_cost(selected_upgrade_id)
		var prev_is_maxed = prev_rank >= prev_upgrade.max_rank
		var prev_can_afford = StatsManager.spendable_coins >= prev_cost
		_style_upgrade_tile(prev_tile, prev_upgrade, prev_is_maxed, prev_can_afford)

	if selected_upgrade_id == upgrade_id:
		# Clicking same tile again hides tooltip
		selected_upgrade_id = ""
		floating_tooltip.visible = false
		return

	selected_upgrade_id = upgrade_id

	# Apply selected style to current tile
	if upgrade_tiles.has(upgrade_id):
		var tile = upgrade_tiles[upgrade_id]
		var upgrade = PermanentUpgrades.get_upgrade(upgrade_id)
		_apply_selected_style(tile, upgrade)

	_update_tooltip(upgrade_id)

	# Position tooltip near the tile (this will also make it visible after positioning)
	_position_tooltip(upgrade_id)

func _position_tooltip(upgrade_id: String) -> void:
	if not upgrade_tiles.has(upgrade_id):
		return

	var tile = upgrade_tiles[upgrade_id]

	# Move tooltip offscreen first, then make visible so it can layout
	floating_tooltip.position = Vector2(-1000, -1000)
	floating_tooltip.visible = true

	# Wait two frames for tooltip to fully layout and get its actual size
	await get_tree().process_frame
	await get_tree().process_frame

	# If selection changed during the await, abort
	if selected_upgrade_id != upgrade_id:
		return

	# Make sure tooltip has a valid size, otherwise use a default
	var tooltip_size = floating_tooltip.size
	if tooltip_size.x <= 0 or tooltip_size.y <= 0:
		tooltip_size = Vector2(280, 200)  # Fallback size

	# Get the tile's global position and convert to position relative to scroll content
	var tile_rect = tile.get_global_rect()
	var scroll_rect = scroll_container.get_global_rect()

	# Position in scroll container's local coordinates
	var tile_in_scroll_x = tile_rect.position.x - scroll_rect.position.x
	var tile_in_scroll_y = tile_rect.position.y - scroll_rect.position.y

	# Add scroll offset to get position in scroll content space
	var scroll_offset = scroll_container.scroll_vertical
	var content_y = tile_in_scroll_y + scroll_offset

	# Center tooltip horizontally on the tile
	var tooltip_x = tile_in_scroll_x + (tile_rect.size.x / 2) - (tooltip_size.x / 2)

	# Position below tile by default
	var tooltip_y = content_y + tile_rect.size.y + 10

	# Check if tooltip would go below visible area
	var visible_bottom = scroll_offset + scroll_container.size.y
	if tooltip_y + tooltip_size.y > visible_bottom - 20:
		# Position above the tile instead
		tooltip_y = content_y - tooltip_size.y - 10

	# Clamp X position to stay within scroll container bounds
	var max_x = scroll_container.size.x - tooltip_size.x - 20
	tooltip_x = clamp(tooltip_x, 20, max_x)

	# Ensure Y is not above the visible scroll area
	tooltip_y = max(tooltip_y, scroll_offset + 10)

	floating_tooltip.position = Vector2(tooltip_x, tooltip_y)

func _apply_selected_style(tile: Button, upgrade) -> void:
	var category_color = CATEGORY_COLORS.get(upgrade.category, Color.WHITE)
	var base_bg = Color(0.1, 0.1, 0.12, 1)

	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = base_bg.lightened(0.2)
	style_selected.border_width_left = 3
	style_selected.border_width_right = 3
	style_selected.border_width_top = 3
	style_selected.border_width_bottom = 4
	style_selected.border_color = category_color.lightened(0.2)
	style_selected.corner_radius_top_left = 8
	style_selected.corner_radius_top_right = 8
	style_selected.corner_radius_bottom_left = 8
	style_selected.corner_radius_bottom_right = 8

	tile.add_theme_stylebox_override("normal", style_selected)
	tile.add_theme_stylebox_override("hover", style_selected)
	tile.add_theme_stylebox_override("pressed", style_selected)
	tile.add_theme_stylebox_override("focus", style_selected)

func _update_tooltip(upgrade_id: String) -> void:
	if not PermanentUpgrades:
		return

	var upgrade = PermanentUpgrades.get_upgrade(upgrade_id)
	if upgrade == null:
		return

	var rank = PermanentUpgrades.get_rank(upgrade_id)
	var cost = PermanentUpgrades.get_upgrade_cost(upgrade_id)
	var is_maxed = rank >= upgrade.max_rank
	var can_afford = StatsManager.spendable_coins >= cost

	# Update labels
	upgrade_name_label.text = upgrade.name

	var category_name = PermanentUpgrades.get_category_name(upgrade.category)
	category_label.text = category_name.to_upper()

	description_label.text = upgrade.description

	# Update rank squares in tooltip
	for child in tooltip_rank_container.get_children():
		child.queue_free()

	var category_color = CATEGORY_COLORS.get(upgrade.category, Color.WHITE)
	for i in range(upgrade.max_rank):
		var square = ColorRect.new()
		square.custom_minimum_size = Vector2(12, 12)
		if i < rank:
			square.color = category_color
		else:
			square.color = Color(0.25, 0.22, 0.18, 1)
		tooltip_rank_container.add_child(square)

	# Current benefit display
	if is_maxed:
		current_label.text = "MAXED: " + PermanentUpgrades.get_benefit_string(upgrade_id)
		current_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	else:
		var current_benefit = upgrade.benefit_per_rank * rank
		if "%d%%" in upgrade.benefit_format:
			current_label.text = "Current: +%d%%" % int(current_benefit * 100)
		else:
			current_label.text = "Current: +%d" % int(current_benefit)
		current_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.4, 1))

	# Button state with cost (● is the gold icon)
	upgrade_button.disabled = is_maxed or not can_afford
	if is_maxed:
		upgrade_button.text = "MAXED"
	else:
		upgrade_button.text = "UPGRADE  ● %d" % cost

func _on_upgrade_pressed() -> void:
	if selected_upgrade_id.is_empty():
		return

	if PermanentUpgrades and PermanentUpgrades.purchase_upgrade(selected_upgrade_id):
		_update_tooltip(selected_upgrade_id)
		_update_coin_display()
		_update_all_tiles_affordability()

func _update_tile(upgrade_id: String) -> void:
	if not upgrade_tiles.has(upgrade_id):
		return

	var tile = upgrade_tiles[upgrade_id]
	var upgrade = PermanentUpgrades.get_upgrade(upgrade_id)
	var rank = PermanentUpgrades.get_rank(upgrade_id)
	var cost = PermanentUpgrades.get_upgrade_cost(upgrade_id)
	var is_maxed = rank >= upgrade.max_rank
	var can_afford = StatsManager.spendable_coins >= cost

	# Update rank squares (find recursively since it's nested in CenterContainer)
	var rank_container = tile.find_child("RankContainer", true, false)
	if rank_container:
		var category_color = CATEGORY_COLORS.get(upgrade.category, Color.WHITE)
		for i in range(upgrade.max_rank):
			var square = rank_container.get_node("Square%d" % i)
			if square:
				if i < rank:
					square.color = category_color
				else:
					square.color = Color(0.25, 0.22, 0.18, 1)

	# Re-style tile
	_style_upgrade_tile(tile, upgrade, is_maxed, can_afford)

func _update_all_tiles_affordability() -> void:
	# Update all tiles when coins change
	for upgrade_id in upgrade_tiles.keys():
		_update_tile(upgrade_id)

func _update_coin_display() -> void:
	if StatsManager:
		coin_amount.text = " %d" % StatsManager.spendable_coins

func _on_upgrade_purchased(_upgrade_id: String, _new_rank: int) -> void:
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_scroll_changed(_value: float) -> void:
	# Close tooltip when user scrolls
	if floating_tooltip.visible:
		_close_tooltip()

func _close_tooltip() -> void:
	# Deselect the current tile
	if selected_upgrade_id != "" and upgrade_tiles.has(selected_upgrade_id):
		var tile = upgrade_tiles[selected_upgrade_id]
		var upgrade = PermanentUpgrades.get_upgrade(selected_upgrade_id)
		var rank = PermanentUpgrades.get_rank(selected_upgrade_id)
		var cost = PermanentUpgrades.get_upgrade_cost(selected_upgrade_id)
		var is_maxed = rank >= upgrade.max_rank
		var can_afford = StatsManager.spendable_coins >= cost
		_style_upgrade_tile(tile, upgrade, is_maxed, can_afford)

	selected_upgrade_id = ""
	floating_tooltip.visible = false

func _on_refund_pressed() -> void:
	if PermanentUpgrades and PermanentUpgrades.total_coins_spent > 0:
		confirm_dialog.dialog_text = "Are you sure you want to refund all upgrades?\nYou will get back %d gold." % PermanentUpgrades.total_coins_spent
		confirm_dialog.popup_centered()

func _on_refund_confirmed() -> void:
	if PermanentUpgrades:
		PermanentUpgrades.refund_all()

func _on_upgrades_refunded(_coins_returned: int) -> void:
	# Refresh the entire grid
	_populate_all_upgrades()
	_update_coin_display()

	# Hide tooltip
	selected_upgrade_id = ""
	floating_tooltip.visible = false
