extends CanvasLayer

# Node references
@onready var back_button: Button = $MainContainer/Header/BackButton
@onready var coin_amount: Label = $MainContainer/Header/CoinsContainer/CoinAmount
@onready var category_tabs: HBoxContainer = $MainContainer/CategoryTabs
@onready var grid_container: GridContainer = $MainContainer/ScrollContainer/GridContainer
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
var current_category: int = PermanentUpgrades.Category.COMBAT
var selected_upgrade_id: String = ""
var upgrade_tiles: Dictionary = {}  # Maps upgrade_id to tile button

# Category colors
const CATEGORY_COLORS = {
	0: Color(1, 0.3, 0.3, 1),      # Combat - Red
	1: Color(0.3, 1, 0.5, 1),      # Survival - Green
	2: Color(0.3, 0.7, 1, 1),      # Utility - Blue
	3: Color(1, 0.84, 0, 1),       # Progression - Gold
	4: Color(0.8, 0.3, 1, 1),      # Special - Purple
}

func _ready() -> void:
	# Style back button
	_style_back_button()

	# Style footer tooltip
	_style_footer_tooltip()

	# Connect signals
	back_button.pressed.connect(_on_back_pressed)
	upgrade_button.pressed.connect(_on_upgrade_pressed)
	refund_button.pressed.connect(_on_refund_pressed)
	confirm_dialog.confirmed.connect(_on_refund_confirmed)

	if PermanentUpgrades:
		PermanentUpgrades.upgrade_purchased.connect(_on_upgrade_purchased)
		PermanentUpgrades.upgrades_refunded.connect(_on_upgrades_refunded)

	# Create category tabs
	_create_category_tabs()

	# Populate grid with current category
	_populate_grid(current_category)

	# Update coin display
	_update_coin_display()

	# Hide tooltip initially
	footer_tooltip.visible = false

func _style_back_button() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.35, 1)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	back_button.add_theme_stylebox_override("normal", style)
	back_button.add_theme_stylebox_override("hover", style_hover)
	back_button.add_theme_stylebox_override("pressed", style)
	back_button.add_theme_stylebox_override("focus", style)

func _style_footer_tooltip() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.98)
	style.border_width_top = 3
	style.border_color = Color(0, 1, 0.8, 1)
	style.content_margin_left = 20
	style.content_margin_right = 20
	style.content_margin_top = 15
	style.content_margin_bottom = 15

	footer_tooltip.add_theme_stylebox_override("panel", style)

	# Style upgrade button
	var btn_style = StyleBoxFlat.new()
	btn_style.bg_color = Color(0, 1, 0.8, 1)
	btn_style.corner_radius_top_left = 8
	btn_style.corner_radius_top_right = 8
	btn_style.corner_radius_bottom_left = 8
	btn_style.corner_radius_bottom_right = 8

	var btn_hover = StyleBoxFlat.new()
	btn_hover.bg_color = Color(0, 0.85, 0.68, 1)
	btn_hover.corner_radius_top_left = 8
	btn_hover.corner_radius_top_right = 8
	btn_hover.corner_radius_bottom_left = 8
	btn_hover.corner_radius_bottom_right = 8

	var btn_disabled = StyleBoxFlat.new()
	btn_disabled.bg_color = Color(0.3, 0.3, 0.35, 1)
	btn_disabled.corner_radius_top_left = 8
	btn_disabled.corner_radius_top_right = 8
	btn_disabled.corner_radius_bottom_left = 8
	btn_disabled.corner_radius_bottom_right = 8

	upgrade_button.add_theme_stylebox_override("normal", btn_style)
	upgrade_button.add_theme_stylebox_override("hover", btn_hover)
	upgrade_button.add_theme_stylebox_override("pressed", btn_style)
	upgrade_button.add_theme_stylebox_override("disabled", btn_disabled)
	upgrade_button.add_theme_color_override("font_color", Color(0.05, 0.05, 0.08, 1))
	upgrade_button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.55, 1))

func _create_category_tabs() -> void:
	# Clear existing tabs
	for child in category_tabs.get_children():
		child.queue_free()

	var categories = [
		PermanentUpgrades.Category.COMBAT,
		PermanentUpgrades.Category.SURVIVAL,
		PermanentUpgrades.Category.UTILITY,
		PermanentUpgrades.Category.PROGRESSION,
		PermanentUpgrades.Category.SPECIAL,
	]

	for category in categories:
		var tab = Button.new()
		tab.text = PermanentUpgrades.get_category_name(category)
		tab.custom_minimum_size = Vector2(0, 40)
		tab.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tab.add_theme_font_size_override("font_size", 16)

		_style_category_tab(tab, category, category == current_category)

		tab.pressed.connect(_on_category_selected.bind(category))
		category_tabs.add_child(tab)

func _style_category_tab(tab: Button, category: int, is_selected: bool) -> void:
	var color = CATEGORY_COLORS.get(category, Color.WHITE)

	var style = StyleBoxFlat.new()
	if is_selected:
		style.bg_color = color.darkened(0.3)
		style.border_width_bottom = 3
		style.border_color = color
	else:
		style.bg_color = Color(0.15, 0.15, 0.18, 1)

	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = color.darkened(0.5)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6

	tab.add_theme_stylebox_override("normal", style)
	tab.add_theme_stylebox_override("hover", style_hover)
	tab.add_theme_stylebox_override("pressed", style)
	tab.add_theme_stylebox_override("focus", style)

	if is_selected:
		tab.add_theme_color_override("font_color", color)
	else:
		tab.add_theme_color_override("font_color", Color(0.6, 0.6, 0.65, 1))

func _populate_grid(category: int) -> void:
	# Clear existing tiles
	for child in grid_container.get_children():
		child.queue_free()
	upgrade_tiles.clear()

	if not PermanentUpgrades:
		return

	var upgrades = PermanentUpgrades.get_upgrades_by_category(category)

	for upgrade in upgrades:
		var tile = _create_upgrade_tile(upgrade)
		grid_container.add_child(tile)
		upgrade_tiles[upgrade.id] = tile

func _create_upgrade_tile(upgrade) -> Button:
	var tile = Button.new()
	tile.custom_minimum_size = Vector2(240, 240)  # Square tiles

	# Create container for tile content
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.anchors_preset = Control.PRESET_FULL_RECT
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 8)
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Icon/symbol (using emoji or text for now)
	var icon_label = Label.new()
	icon_label.text = _get_upgrade_icon(upgrade.id)
	icon_label.add_theme_font_size_override("font_size", 48)
	icon_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	icon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(icon_label)

	# Name
	var name_label = Label.new()
	name_label.text = upgrade.name
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(name_label)

	# Rank display
	var rank = PermanentUpgrades.get_rank(upgrade.id)
	var rank_display = Label.new()
	rank_display.name = "RankDisplay"
	rank_display.text = "%d/%d" % [rank, upgrade.max_rank]
	rank_display.add_theme_font_size_override("font_size", 14)
	rank_display.add_theme_color_override("font_color", Color(0.7, 0.7, 0.75, 1))
	rank_display.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rank_display.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(rank_display)

	# Progress bar
	var progress = ProgressBar.new()
	progress.name = "ProgressBar"
	progress.custom_minimum_size = Vector2(0, 8)
	progress.max_value = upgrade.max_rank
	progress.value = rank
	progress.show_percentage = false
	progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_style_progress_bar(progress, upgrade.category)
	vbox.add_child(progress)

	tile.add_child(vbox)

	# Style tile
	_style_upgrade_tile(tile, upgrade, rank >= upgrade.max_rank)

	# Connect signal
	tile.pressed.connect(_on_tile_pressed.bind(upgrade.id))

	return tile

func _style_upgrade_tile(tile: Button, upgrade, is_maxed: bool) -> void:
	var category_color = CATEGORY_COLORS.get(upgrade.category, Color.WHITE)

	var style = StyleBoxFlat.new()
	if is_maxed:
		style.bg_color = category_color.darkened(0.6)
		style.border_width_left = 3
		style.border_width_right = 3
		style.border_width_top = 3
		style.border_width_bottom = 3
		style.border_color = category_color.darkened(0.2)
	else:
		style.bg_color = Color(0.12, 0.12, 0.15, 1)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_color = Color(0.25, 0.25, 0.3, 1)

	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.18, 0.18, 0.22, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 2
	style_hover.border_color = category_color.darkened(0.3)
	style_hover.corner_radius_top_left = 12
	style_hover.corner_radius_top_right = 12
	style_hover.corner_radius_bottom_left = 12
	style_hover.corner_radius_bottom_right = 12

	var style_selected = StyleBoxFlat.new()
	style_selected.bg_color = Color(0.15, 0.15, 0.2, 1)
	style_selected.border_width_left = 3
	style_selected.border_width_right = 3
	style_selected.border_width_top = 3
	style_selected.border_width_bottom = 3
	style_selected.border_color = category_color
	style_selected.corner_radius_top_left = 12
	style_selected.corner_radius_top_right = 12
	style_selected.corner_radius_bottom_left = 12
	style_selected.corner_radius_bottom_right = 12

	tile.add_theme_stylebox_override("normal", style)
	tile.add_theme_stylebox_override("hover", style_hover)
	tile.add_theme_stylebox_override("pressed", style_selected)
	tile.add_theme_stylebox_override("focus", style)

func _style_progress_bar(progress: ProgressBar, category: int) -> void:
	var category_color = CATEGORY_COLORS.get(category, Color.WHITE)

	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.2, 0.2, 0.25, 1)
	bg_style.corner_radius_top_left = 4
	bg_style.corner_radius_top_right = 4
	bg_style.corner_radius_bottom_left = 4
	bg_style.corner_radius_bottom_right = 4

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = category_color
	fill_style.corner_radius_top_left = 4
	fill_style.corner_radius_top_right = 4
	fill_style.corner_radius_bottom_left = 4
	fill_style.corner_radius_bottom_right = 4

	progress.add_theme_stylebox_override("background", bg_style)
	progress.add_theme_stylebox_override("fill", fill_style)

func _get_upgrade_icon(upgrade_id: String) -> String:
	# Text-based icons for each upgrade
	match upgrade_id:
		"neon_power": return "PWR"
		"hard_light_shield": return "DEF"
		"overclocked_emitter": return "SPD"
		"volatile_plasma": return "AOE"
		"magnetic_accelerator": return "VEL"
		"split_chamber": return "x2"
		"viral_payload": return "VIR"
		"precision_core": return "CRT"
		"core_integrity": return "HP"
		"auto_repair": return "REG"
		"thruster_boost": return "MOV"
		"evasion_matrix": return "EVD"
		"stable_fields": return "DUR"
		"attractor_beam": return "MAG"
		"quantum_flux": return "LCK"
		"cooldown_matrix": return "CDR"
		"data_mining": return "XP"
		"score_multiplier": return "PTS"
		"coin_magnet": return "coins"
		"daredevil_protocol": return "!!!"
		"emergency_reboot": return "1UP"
		"starting_arsenal": return "+"
		_: return "?"

func _on_category_selected(category: int) -> void:
	if category == current_category:
		return

	current_category = category

	# Update tab styles
	var i = 0
	for tab in category_tabs.get_children():
		_style_category_tab(tab, i, i == category)
		i += 1

	# Repopulate grid
	_populate_grid(category)

	# Hide tooltip when changing categories
	selected_upgrade_id = ""
	footer_tooltip.visible = false

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
	description_label.text = upgrade.description

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
		benefit_label.add_theme_color_override("font_color", Color(0.5, 1, 0.5, 1))

	# Cost display
	if is_maxed:
		cost_label.text = "MAXED"
		cost_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 1))
	else:
		cost_label.text = "Cost: %d" % cost
		if can_afford:
			cost_label.add_theme_color_override("font_color", Color(1, 0.84, 0, 1))
		else:
			cost_label.add_theme_color_override("font_color", Color(1, 0.4, 0.4, 1))

	# Button state
	upgrade_button.disabled = is_maxed or not can_afford
	if is_maxed:
		upgrade_button.text = "MAXED"
	elif not can_afford:
		upgrade_button.text = "NOT ENOUGH"
	else:
		upgrade_button.text = "UPGRADE"

func _on_upgrade_pressed() -> void:
	if selected_upgrade_id.is_empty():
		return

	if PermanentUpgrades and PermanentUpgrades.purchase_upgrade(selected_upgrade_id):
		_update_tooltip(selected_upgrade_id)
		_update_tile(selected_upgrade_id)
		_update_coin_display()

func _update_tile(upgrade_id: String) -> void:
	if not upgrade_tiles.has(upgrade_id):
		return

	var tile = upgrade_tiles[upgrade_id]
	var upgrade = PermanentUpgrades.get_upgrade(upgrade_id)
	var rank = PermanentUpgrades.get_rank(upgrade_id)

	# Update rank display
	var rank_display = tile.get_node("VBoxContainer/RankDisplay")
	if rank_display:
		rank_display.text = "%d/%d" % [rank, upgrade.max_rank]

	# Update progress bar
	var progress = tile.get_node("VBoxContainer/ProgressBar")
	if progress:
		progress.value = rank

	# Re-style tile if maxed
	_style_upgrade_tile(tile, upgrade, rank >= upgrade.max_rank)

func _update_coin_display() -> void:
	if StatsManager:
		coin_amount.text = " %d" % StatsManager.spendable_coins

func _on_upgrade_purchased(upgrade_id: String, new_rank: int) -> void:
	# Could add visual feedback here (particles, sounds, etc.)
	pass

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_refund_pressed() -> void:
	if PermanentUpgrades and PermanentUpgrades.total_coins_spent > 0:
		confirm_dialog.dialog_text = "Are you sure you want to refund all upgrades?\nYou will get back %d coins." % PermanentUpgrades.total_coins_spent
		confirm_dialog.popup_centered()

func _on_refund_confirmed() -> void:
	if PermanentUpgrades:
		PermanentUpgrades.refund_all()

func _on_upgrades_refunded(coins_returned: int) -> void:
	# Refresh the entire grid
	_populate_grid(current_category)
	_update_coin_display()

	# Hide tooltip
	selected_upgrade_id = ""
	footer_tooltip.visible = false
