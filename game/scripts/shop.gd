extends CanvasLayer

# Font
var pixel_font = preload("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

# Node references
@onready var back_button: Button = $MainContainer/Header/BackButton
@onready var coin_amount: Label = $MainContainer/Header/CoinsContainer/CoinAmount
@onready var grid_container: GridContainer = $MainContainer/ScrollContainer/MarginContainer/CenterContainer/GridContainer
@onready var footer_tooltip: PanelContainer = $MainContainer/FooterTooltip
@onready var upgrade_name_label: Label = $MainContainer/FooterTooltip/TooltipContent/TopRow/UpgradeName
@onready var rank_label: Label = $MainContainer/FooterTooltip/TooltipContent/TopRow/RankLabel
@onready var description_label: Label = $MainContainer/FooterTooltip/TooltipContent/Description
@onready var benefit_label: Label = $MainContainer/FooterTooltip/TooltipContent/BenefitLabel
@onready var cost_label: Label = $MainContainer/FooterTooltip/TooltipContent/BottomRow/CostLabel
@onready var upgrade_button: Button = $MainContainer/FooterTooltip/TooltipContent/BottomRow/UpgradeButton
@onready var refund_button: Button = $MainContainer/RefundButton
@onready var confirm_dialog: ConfirmationDialog = $ConfirmDialog

# State
var selected_upgrade_id: String = ""
var upgrade_tiles: Dictionary = {}  # Maps upgrade_id to tile button

# Category colors - more muted/medieval
const CATEGORY_COLORS = {
	0: Color(0.7, 0.3, 0.3, 1),      # Combat - Dark Red
	1: Color(0.3, 0.6, 0.4, 1),      # Survival - Forest Green
	2: Color(0.4, 0.5, 0.7, 1),      # Utility - Steel Blue
	3: Color(0.7, 0.6, 0.3, 1),      # Progression - Gold
	4: Color(0.6, 0.4, 0.7, 1),      # Special - Purple
}

func _ready() -> void:
	# Style buttons
	_style_back_button()
	_style_footer_tooltip()
	_style_refund_button()

	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	refund_button.pressed.connect(_on_refund_pressed)
	confirm_dialog.confirmed.connect(_on_refund_confirmed)

	if PermanentUpgrades:
		PermanentUpgrades.upgrade_purchased.connect(_on_upgrade_purchased)
		PermanentUpgrades.upgrades_refunded.connect(_on_upgrades_refunded)

	# Populate grid with ALL upgrades
	_populate_all_upgrades()

	# Update coin display
	_update_coin_display()

	# Hide tooltip initially
	footer_tooltip.visible = false

func _style_back_button() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.06, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 3
	style.border_color = Color(0.5, 0.4, 0.3, 1)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.15, 0.12, 0.08, 0.95)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 3
	style_hover.border_color = Color(0.7, 0.6, 0.4, 1)
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4

	back_button.add_theme_stylebox_override("normal", style)
	back_button.add_theme_stylebox_override("hover", style_hover)
	back_button.add_theme_stylebox_override("pressed", style)
	back_button.add_theme_stylebox_override("focus", style)

func _style_refund_button() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.08, 0.06, 0.8)
	style.border_width_top = 1
	style.border_color = Color(0.4, 0.25, 0.2, 1)

	refund_button.add_theme_stylebox_override("normal", style)
	refund_button.add_theme_stylebox_override("hover", style)
	refund_button.add_theme_stylebox_override("pressed", style)
	refund_button.add_theme_stylebox_override("focus", style)

func _style_footer_tooltip() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.04, 0.98)
	style.border_width_top = 3
	style.border_color = Color(0.6, 0.5, 0.3, 1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15

	footer_tooltip.add_theme_stylebox_override("panel", style)

	# Style upgrade button - medieval
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0.3, 0.5, 0.25, 1)
	btn_style.border_width_left = 3
	btn_style.border_width_right = 3
	btn_style.border_width_top = 3
	btn_style.border_width_bottom = 4
	btn_style.border_color = Color(0.2, 0.35, 0.15, 1)
	btn_style.corner_radius_top_left = 4
	btn_style.corner_radius_top_right = 4
	btn_style.corner_radius_bottom_left = 4
	btn_style.corner_radius_bottom_right = 4

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0.35, 0.55, 0.3, 1)
	btn_hover.border_width_left = 3
	btn_hover.border_width_right = 3
	btn_hover.border_width_top = 3
	btn_hover.border_width_bottom = 4
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

	# Sort by category for visual grouping
	all_upgrades.sort_custom(func(a, b): return a.category < b.category)

	for upgrade in all_upgrades:
		var tile = _create_upgrade_tile(upgrade)
		grid_container.add_child(tile)
		upgrade_tiles[upgrade.id] = tile

func _create_upgrade_tile(upgrade) -> Button:
	var tile = Button.new()
	tile.custom_minimum_size = Vector2(180, 100)

	# Create container for tile content
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.alignment = BoxContainer.ALIGNMENT_BEGIN
	vbox.add_theme_constant_override("separation", 6)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Top spacer
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 8)
	top_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_spacer)

	# Name container for centering
	var name_container = CenterContainer.new()
	name_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_container.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = upgrade.name
	name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", Color(1, 0.95, 0.85, 1))
	name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	name_label.add_theme_constant_override("shadow_offset_x", 1)
	name_label.add_theme_constant_override("shadow_offset_y", 1)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_container.add_child(name_label)
	vbox.add_child(name_container)

	# Expanding spacer to push squares to bottom
	var middle_spacer = Control.new()
	middle_spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	middle_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(middle_spacer)

	# Rank squares in a centered container
	var rank = PermanentUpgrades.get_rank(upgrade.id)
	var squares_center = CenterContainer.new()
	squares_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	squares_center.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var rank_container = HBoxContainer.new()
	rank_container.name = "RankContainer"
	rank_container.alignment = BoxContainer.ALIGNMENT_CENTER
	rank_container.add_theme_constant_override("separation", 4)
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

	squares_center.add_child(rank_container)
	vbox.add_child(squares_center)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	bottom_spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(bottom_spacer)

	tile.add_child(vbox)

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

	var style = StyleBoxFlat.new()
	if is_maxed:
		# Maxed - golden glow effect
		style.bg_color = Color(0.12, 0.1, 0.06, 0.95)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.border_color = Color(0.6, 0.5, 0.2, 0.8)
	elif can_afford:
		# Affordable - brighter, inviting
		style.bg_color = Color(0.12, 0.1, 0.07, 0.95)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.border_color = Color(0.5, 0.45, 0.3, 1)
	else:
		# Can't afford - dimmed
		style.bg_color = Color(0.08, 0.07, 0.05, 0.9)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 3
		style.border_color = Color(0.25, 0.22, 0.18, 0.7)

	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.16, 0.13, 0.09, 0.98)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 3
	style_hover.border_color = category_color.lightened(0.1)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0.14, 0.11, 0.07, 0.98)
	style_selected.border_width_left = 3
	style_selected.border_width_right = 3
	style_selected.border_width_top = 3
	style_selected.border_width_bottom = 4
	style_selected.border_color = category_color
	style_selected.corner_radius_top_left = 8
	style_selected.corner_radius_top_right = 8
	style_selected.corner_radius_bottom_left = 8
	style_selected.corner_radius_bottom_right = 8

	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_stylebox_override("hover", style_hover)
	tile.add_theme_stylebox_override("pressed", style_selected)
	tile.add_theme_stylebox_override("focus", style)

	# Dim the tile content if can't afford
	tile.modulate = Color(1, 1, 1, 1) if (can_afford or is_maxed) else Color(0.7, 0.65, 0.6, 1)

func _on_tile_pressed(upgrade_id: String) -> void:
	if selected_upgrade_id == upgrade_id:
		# Clicking same tile again hides tooltip
		selected_upgrade_id = ""
		footer_tooltip.visible = false
		return

	selected_upgrade_id = upgrade_id
	_update_tooltip(upgrade_id)
	footer_tooltip.visible = true

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
	rank_label.text = "Rank %d/%d" % [rank, upgrade.max_rank]
	var category_name = PermanentUpgrades.get_category_name(upgrade.category)
	description_label.text = "[%s] %s" % [category_name.to_upper(), upgrade.description]

	# Benefit display
	if is_maxed:
		benefit_label.text = "MAXED: " + PermanentUpgrades.get_benefit_string(upgrade_id)
		benefit_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
	else:
		var current_benefit = upgrade.benefit_per_rank * rank
		var next_benefit = upgrade.benefit_per_rank * (rank + 1)

		# Format based on percentage or flat
		if "%d%%" in upgrade.benefit_format:
			benefit_label.text = "Current: +%d%% | Next: +%d%%" % [int(current_benefit * 100), int(next_benefit * 100)]
		else:
			benefit_label.text = "Current: +%d | Next: +%d" % [int(current_benefit), int(next_benefit)]
		benefit_label.add_theme_color_override("font_color", Color(0.5, 0.9, 0.4, 1))

	# Cost display
	if is_maxed:
		cost_label.text = "MAXED"
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.45, 0.4, 1))
	else:
		cost_label.text = "Cost: %d" % cost
		if can_afford:
			cost_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
		else:
			cost_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.3, 1))

	# Button state
	upgrade_button.disabled = is_maxed or not can_afford
	if is_maxed:
		upgrade_button.text = "MAXED"
	elif not can_afford:
		upgrade_button.text = "NEED GOLD"
	else:
		upgrade_button.text = "UPGRADE"

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
	footer_tooltip.visible = false
