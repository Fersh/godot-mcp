extends CanvasLayer

signal resumed
signal gave_up

var pixel_font: Font = null

# RPG Colors
const COLOR_BG = Color(0.08, 0.06, 0.1, 0.95)
const COLOR_PANEL = Color(0.12, 0.10, 0.15, 1.0)
const COLOR_BORDER = Color(0.35, 0.28, 0.18, 1.0)
const COLOR_TEXT = Color(0.9, 0.85, 0.75, 1.0)
const COLOR_TEXT_DIM = Color(0.55, 0.50, 0.42, 1.0)

# Stat colors
const COLOR_STAT_BASE = Color(0.9, 0.9, 0.9, 1.0)  # White - unchanged
const COLOR_STAT_MODIFIED = Color(0.4, 0.9, 0.4, 1.0)  # Green - modified by gear/upgrades/abilities
const COLOR_STAT_CURSED = Color(1.0, 0.5, 0.7, 1.0)  # Pink - affected by curse

# Tab button colors
const COLOR_TAB_ACTIVE = Color(0.35, 0.30, 0.45, 1.0)
const COLOR_TAB_INACTIVE = Color(0.12, 0.10, 0.14, 1.0)
const COLOR_TAB_ACTIVE_TEXT = Color(1.0, 0.95, 0.85, 1.0)
const COLOR_TAB_INACTIVE_TEXT = Color(0.5, 0.45, 0.40, 1.0)

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel

# Tab buttons
@onready var powerups_tab: Button = $Panel/VBoxContainer/TabContainer/PowerupsTab
@onready var stats_tab: Button = $Panel/VBoxContainer/TabContainer/StatsTab
@onready var options_tab: Button = $Panel/VBoxContainer/TabContainer/OptionsTab

# Content containers
@onready var powerups_content: VBoxContainer = $Panel/VBoxContainer/ContentContainer/PowerupsContent
@onready var stats_content: VBoxContainer = $Panel/VBoxContainer/ContentContainer/StatsContent
@onready var options_content: VBoxContainer = $Panel/VBoxContainer/ContentContainer/OptionsContent
@onready var powerups_container: VBoxContainer = $Panel/VBoxContainer/ContentContainer/PowerupsContent/PowerupsScroll/PowerupsMargin/PowerupsContainer
@onready var stats_container: VBoxContainer = $Panel/VBoxContainer/ContentContainer/StatsContent/StatsScroll/StatsMargin/StatsContainer
@onready var options_container: VBoxContainer = $Panel/VBoxContainer/ContentContainer/OptionsContent/OptionsScroll/OptionsMargin/OptionsContainer

# Action buttons
@onready var resume_button: Button = $Panel/VBoxContainer/ButtonContainer/ResumeButton
@onready var give_up_button: Button = $Panel/VBoxContainer/ButtonContainer/GiveUpButton

var difficulty_label: Label = null
var current_tab: int = 0  # 0 = powerups, 1 = stats, 2 = options

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("pause_menu")

	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	resume_button.pressed.connect(_on_resume_pressed)
	give_up_button.pressed.connect(_on_give_up_pressed)
	powerups_tab.pressed.connect(_on_powerups_tab_pressed)
	stats_tab.pressed.connect(_on_stats_tab_pressed)
	options_tab.pressed.connect(_on_options_tab_pressed)

	_setup_style()
	_setup_difficulty_label()
	_update_tab_visuals()

func _setup_style() -> void:
	# Style the main panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 6
	panel_style.border_color = COLOR_BORDER
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style title
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", 30)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)

	# Style tab buttons
	_style_tab_button(powerups_tab)
	_style_tab_button(stats_tab)
	_style_tab_button(options_tab)

	# Style action buttons
	_style_button(resume_button, Color(0.2, 0.5, 0.3))
	_style_button(give_up_button, Color(0.5, 0.2, 0.2))

func _style_tab_button(button: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = COLOR_TAB_INACTIVE
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = COLOR_BORDER.darkened(0.3)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4

	var style_hover = style.duplicate()
	style_hover.bg_color = COLOR_TAB_INACTIVE.lightened(0.15)

	var style_pressed = style.duplicate()
	style_pressed.bg_color = COLOR_TAB_ACTIVE

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", COLOR_TAB_INACTIVE_TEXT)

func _setup_difficulty_label() -> void:
	# Create difficulty label at top middle of screen
	difficulty_label = Label.new()
	difficulty_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	difficulty_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Position at top middle
	difficulty_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	difficulty_label.offset_top = 60
	difficulty_label.offset_bottom = 100
	difficulty_label.offset_left = -200
	difficulty_label.offset_right = 200

	# Style
	if pixel_font:
		difficulty_label.add_theme_font_override("font", pixel_font)
	difficulty_label.add_theme_font_size_override("font_size", 18)
	difficulty_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	difficulty_label.add_theme_constant_override("shadow_offset_x", 2)
	difficulty_label.add_theme_constant_override("shadow_offset_y", 2)

	add_child(difficulty_label)

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

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 22)
	button.add_theme_color_override("font_color", COLOR_TEXT)

func _on_powerups_tab_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	current_tab = 0
	_update_tab_visuals()

func _on_stats_tab_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	current_tab = 1
	_update_tab_visuals()
	_populate_stats()

func _on_options_tab_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	current_tab = 2
	_update_tab_visuals()
	_populate_options()

func _update_tab_visuals() -> void:
	# Update content visibility
	powerups_content.visible = current_tab == 0
	stats_content.visible = current_tab == 1
	options_content.visible = current_tab == 2

	# Update tab button styles
	_update_tab_style(powerups_tab, current_tab == 0)
	_update_tab_style(stats_tab, current_tab == 1)
	_update_tab_style(options_tab, current_tab == 2)

func _update_tab_style(button: Button, is_active: bool) -> void:
	var style = button.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
	if is_active:
		style.bg_color = COLOR_TAB_ACTIVE
		style.border_color = Color(1.0, 1.0, 1.0, 0.8)
		button.add_theme_color_override("font_color", COLOR_TAB_ACTIVE_TEXT)
	else:
		style.bg_color = COLOR_TAB_INACTIVE
		style.border_color = COLOR_BORDER.darkened(0.3)
		button.add_theme_color_override("font_color", COLOR_TAB_INACTIVE_TEXT)

	var style_hover = style.duplicate()
	style_hover.bg_color = style.bg_color.lightened(0.1)

	var style_pressed = style.duplicate()
	style_pressed.bg_color = style.bg_color.darkened(0.1)

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style)

func show_menu() -> void:
	_update_tab_visuals()
	if current_tab == 0:
		_populate_powerups()
	else:
		_populate_stats()
	_update_difficulty_label()
	visible = true
	get_tree().paused = true

func _update_difficulty_label() -> void:
	if not difficulty_label:
		return

	if DifficultyManager:
		if DifficultyManager.is_challenge_mode():
			var diff_name = DifficultyManager.get_difficulty_name()
			var diff_color = DifficultyManager.get_difficulty_color()
			difficulty_label.text = diff_name
			difficulty_label.add_theme_color_override("font_color", diff_color)
		else:
			difficulty_label.text = "Endless"
			difficulty_label.add_theme_color_override("font_color", Color(0.3, 0.6, 0.9))
	else:
		difficulty_label.text = ""

func hide_menu() -> void:
	visible = false
	_safe_unpause()

func _safe_unpause() -> void:
	"""Only unpause if no modal UI is open."""
	# Check if player is dead - never unpause after death
	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_dead:
		return

	# Check if game over UI is visible
	var game_over_ui = get_tree().get_first_node_in_group("game_over_ui")
	if game_over_ui:
		return

	# Check if continue screen is visible
	var continue_ui = get_tree().get_first_node_in_group("continue_screen_ui")
	if continue_ui:
		return

	# Check if ability selection UI is visible
	var ability_ui = get_tree().get_first_node_in_group("ability_selection_ui")
	if ability_ui and ability_ui.visible:
		return

	# Check if active ability selection UI is visible
	var active_ability_ui = get_tree().get_first_node_in_group("active_ability_selection_ui")
	if active_ability_ui and active_ability_ui.visible:
		return

	# Check if ultimate selection UI is visible
	var ultimate_ui = get_tree().get_first_node_in_group("ultimate_selection_ui")
	if ultimate_ui and ultimate_ui.visible:
		return

	# Check if item pickup UI is visible
	var pickup_ui = get_tree().get_first_node_in_group("item_pickup_ui")
	if pickup_ui and pickup_ui.visible:
		return

	get_tree().paused = false

func _populate_powerups() -> void:
	# Clear existing
	for child in powerups_container.get_children():
		child.queue_free()

	# Get acquired abilities from AbilityManager
	if not AbilityManager:
		_add_no_powerups_label()
		return

	var abilities = AbilityManager.acquired_abilities
	if abilities.size() == 0:
		_add_no_powerups_label()
		return

	# Count abilities (for stacking display)
	var ability_counts: Dictionary = {}
	for ability in abilities:
		if ability_counts.has(ability.id):
			ability_counts[ability.id].count += 1
		else:
			ability_counts[ability.id] = {"ability": ability, "count": 1}

	# Create rows for each unique ability
	for ability_id in ability_counts:
		var data = ability_counts[ability_id]
		var row = _create_powerup_row(data.ability, data.count)
		powerups_container.add_child(row)

func _add_no_powerups_label() -> void:
	# Add spacer above
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	powerups_container.add_child(spacer)

	var label = Label.new()
	label.text = "No abilities yet!"
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.4, 0.38, 0.35, 1.0))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	powerups_container.add_child(label)

func _create_powerup_row(ability: AbilityData, count: int) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 7)  # 5px margin below ability name

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Get rarity color (static method requires rarity parameter)
	var rarity_color = AbilityData.get_rarity_color(ability.rarity)

	# Icon placeholder (colored square based on rarity)
	var icon_bg = ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(12, 12)
	icon_bg.color = rarity_color
	row.add_child(icon_bg)

	# Name with count if stacked
	var name_label = Label.new()
	if count > 1:
		name_label.text = "%s x%d" % [ability.name, count]
	else:
		name_label.text = ability.name
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", rarity_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	container.add_child(row)

	# Description below the name
	var desc_label = Label.new()
	desc_label.text = ability.description
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)

	return container

# ============================================
# STATS TAB
# ============================================

func _populate_stats() -> void:
	# Clear existing
	for child in stats_container.get_children():
		child.queue_free()

	var player = get_tree().get_first_node_in_group("player")
	if not player:
		_add_no_stats_label()
		return

	# Get curse count
	var curse_count = 0
	if CurseEffects:
		curse_count = CurseEffects.get_active_curse_count()

	# Gather all stats with their modification status
	var stats = _gather_player_stats(player)

	# Add stat rows
	for stat in stats:
		_add_stat_row(stat.name, stat.value, stat.format, stat.color)

	# Add princess problems section at the bottom if any curses active
	if curse_count > 0:
		_add_princess_problems_section(curse_count)

func _add_no_stats_label() -> void:
	var label = Label.new()
	label.text = "No stats available"
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_container.add_child(label)

func _add_stat_row(stat_name: String, value: String, format: String, color: Color) -> void:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 6)

	# Stat name
	var name_label = Label.new()
	name_label.text = stat_name
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	# Stat value
	var value_label = Label.new()
	value_label.text = value
	if pixel_font:
		value_label.add_theme_font_override("font", pixel_font)
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", color)
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	row.add_child(value_label)

	stats_container.add_child(row)

func _add_princess_problems_section(curse_count: int) -> void:
	"""Add the Princess Problems section with separator line and curse list."""
	# Add spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 12)
	stats_container.add_child(spacer)

	# Add separator line
	var separator = HSeparator.new()
	separator.add_theme_stylebox_override("separator", StyleBoxLine.new())
	var sep_style = separator.get_theme_stylebox("separator") as StyleBoxLine
	if sep_style:
		sep_style.color = Color(0.7, 0.3, 0.5, 0.5)
		sep_style.thickness = 1
	stats_container.add_child(separator)

	# Add another spacer
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 8)
	stats_container.add_child(spacer2)

	# Add "Princess Problems" header (left-aligned)
	var header = Label.new()
	header.text = "Princess Problems"
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	header.add_theme_font_size_override("font_size", 14)
	header.add_theme_color_override("font_color", COLOR_STAT_CURSED)
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	stats_container.add_child(header)

	# Add spacer before curse list
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 6)
	stats_container.add_child(spacer3)

	# Add curse list container (vertical layout)
	var curse_container = VBoxContainer.new()
	curse_container.add_theme_constant_override("separation", 10)
	stats_container.add_child(curse_container)

	# Get active curses and create entries
	if PrincessManager:
		var enabled_curses = PrincessManager.enabled_curses
		for curse_id in enabled_curses:
			var princess = PrincessManager.get_princess(curse_id)
			if princess == null:
				continue

			# Create curse entry (vertical: name then description)
			var curse_entry = VBoxContainer.new()
			curse_entry.add_theme_constant_override("separation", 2)

			# Curse name (bold/highlighted)
			var name_label = Label.new()
			name_label.text = princess.curse_name
			name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			if pixel_font:
				name_label.add_theme_font_override("font", pixel_font)
			name_label.add_theme_font_size_override("font_size", 12)
			name_label.add_theme_color_override("font_color", Color(0.9, 0.6, 0.8))
			name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
			name_label.add_theme_constant_override("shadow_offset_x", 1)
			name_label.add_theme_constant_override("shadow_offset_y", 1)
			curse_entry.add_child(name_label)

			# Curse description (smaller, dimmer)
			var desc_label = Label.new()
			desc_label.text = princess.curse_description if princess.curse_description else "No description"
			desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
			desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			desc_label.custom_minimum_size = Vector2(200, 0)  # Allow wrapping
			if pixel_font:
				desc_label.add_theme_font_override("font", pixel_font)
			desc_label.add_theme_font_size_override("font_size", 10)
			desc_label.add_theme_color_override("font_color", Color(0.6, 0.5, 0.55))
			curse_entry.add_child(desc_label)

			curse_container.add_child(curse_entry)

func _gather_player_stats(player: Node) -> Array:
	var stats: Array = []
	var bonuses = {}
	if PermanentUpgrades:
		bonuses = PermanentUpgrades.get_all_bonuses()

	# Determine curse effects
	var has_curse_speed = false
	var has_curse_hp = false
	var has_curse_damage_taken = false
	var has_curse_healing = false
	var has_curse_luck = false

	if CurseEffects:
		has_curse_speed = CurseEffects.get_player_speed_multiplier() < 1.0
		has_curse_hp = CurseEffects.get_max_hp_reduction() > 0 or CurseEffects.get_starting_hp_multiplier() < 1.0
		has_curse_damage_taken = CurseEffects.get_damage_taken_multiplier() > 1.0
		has_curse_healing = CurseEffects.get_healing_multiplier() < 1.0
		has_curse_luck = CurseEffects.get_luck_multiplier() < 1.0

	# Health
	var hp_modified = bonuses.get("max_hp", 0.0) > 0 or (AbilityManager and AbilityManager.get_equipment_max_hp_bonus() > 0)
	var hp_color = COLOR_STAT_CURSED if has_curse_hp else (COLOR_STAT_MODIFIED if hp_modified else COLOR_STAT_BASE)
	stats.append({
		"name": "Max Health",
		"value": "%d" % int(player.max_health),
		"format": "%d",
		"color": hp_color
	})

	stats.append({
		"name": "Current Health",
		"value": "%d / %d" % [int(player.current_health), int(player.max_health)],
		"format": "%d",
		"color": COLOR_STAT_BASE
	})

	# Speed
	var speed_modified = bonuses.get("move_speed", 0.0) > 0 or (AbilityManager and AbilityManager.get_move_speed_multiplier() > 1.0)
	var speed_color = COLOR_STAT_CURSED if has_curse_speed else (COLOR_STAT_MODIFIED if speed_modified else COLOR_STAT_BASE)
	stats.append({
		"name": "Move Speed",
		"value": "%.1f" % player.speed,
		"format": "%.1f",
		"color": speed_color
	})

	# Attack Speed (inverted from cooldown)
	var atk_speed_modified = bonuses.get("attack_speed", 0.0) > 0 or (AbilityManager and AbilityManager.get_attack_speed_multiplier() > 1.0)
	var attacks_per_sec = 1.0 / player.attack_cooldown if player.attack_cooldown > 0 else 0.0
	stats.append({
		"name": "Attack Speed",
		"value": "%.2f/s" % attacks_per_sec,
		"format": "%.2f",
		"color": COLOR_STAT_MODIFIED if atk_speed_modified else COLOR_STAT_BASE
	})

	# Damage
	var damage_mult = 1.0
	if AbilityManager:
		damage_mult = AbilityManager.get_damage_multiplier()
	var damage_modified = bonuses.get("damage", 0.0) > 0 or damage_mult > 1.0
	stats.append({
		"name": "Damage",
		"value": "%.0f%%" % (damage_mult * 100),
		"format": "%.0f%%",
		"color": COLOR_STAT_MODIFIED if damage_modified else COLOR_STAT_BASE
	})

	# Crit Chance
	var crit_chance = bonuses.get("crit_chance", 0.0)
	stats.append({
		"name": "Crit Chance",
		"value": "%.0f%%" % (crit_chance * 100),
		"format": "%.0f%%",
		"color": COLOR_STAT_MODIFIED if crit_chance > 0 else COLOR_STAT_BASE
	})

	# Crit Damage
	var crit_damage = 1.5 + bonuses.get("crit_damage", 0.0)
	if AbilityManager:
		crit_damage = AbilityManager.get_crit_damage_multiplier()
	var crit_dmg_modified = crit_damage > 1.5
	stats.append({
		"name": "Crit Damage",
		"value": "%.0f%%" % (crit_damage * 100),
		"format": "%.0f%%",
		"color": COLOR_STAT_MODIFIED if crit_dmg_modified else COLOR_STAT_BASE
	})

	# Damage Reduction
	var damage_reduction = bonuses.get("damage_reduction", 0.0)
	var dmg_red_color = COLOR_STAT_CURSED if has_curse_damage_taken else (COLOR_STAT_MODIFIED if damage_reduction > 0 else COLOR_STAT_BASE)
	if has_curse_damage_taken:
		var curse_mult = CurseEffects.get_damage_taken_multiplier() if CurseEffects else 1.0
		stats.append({
			"name": "Damage Taken",
			"value": "+%.0f%%" % ((curse_mult - 1.0) * 100),
			"format": "+%.0f%%",
			"color": dmg_red_color
		})
	elif damage_reduction > 0:
		stats.append({
			"name": "Damage Reduction",
			"value": "-%.0f%%" % (damage_reduction * 100),
			"format": "-%.0f%%",
			"color": dmg_red_color
		})

	# Dodge Chance
	var dodge = bonuses.get("dodge_chance", 0.0)
	if dodge > 0:
		stats.append({
			"name": "Dodge Chance",
			"value": "%.0f%%" % (dodge * 100),
			"format": "%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	# Block Chance
	var block = bonuses.get("block_chance", 0.0)
	if block > 0:
		stats.append({
			"name": "Block Chance",
			"value": "%.0f%%" % (block * 100),
			"format": "%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	# Healing
	var healing_mult = 1.0 + bonuses.get("healing_received", 0.0)
	if AbilityManager:
		healing_mult *= AbilityManager.get_healing_multiplier()
	var healing_modified = healing_mult != 1.0
	var healing_color = COLOR_STAT_CURSED if has_curse_healing else (COLOR_STAT_MODIFIED if healing_modified else COLOR_STAT_BASE)
	if has_curse_healing:
		var curse_heal = CurseEffects.get_healing_multiplier() if CurseEffects else 1.0
		stats.append({
			"name": "Healing",
			"value": "%.0f%%" % (curse_heal * healing_mult * 100),
			"format": "%.0f%%",
			"color": healing_color
		})
	elif healing_modified:
		stats.append({
			"name": "Healing",
			"value": "%.0f%%" % (healing_mult * 100),
			"format": "%.0f%%",
			"color": healing_color
		})

	# Luck
	var luck = 1.0 + bonuses.get("luck", 0.0)
	if AbilityManager:
		luck *= AbilityManager.get_luck_multiplier()
	var luck_modified = luck != 1.0
	var luck_color = COLOR_STAT_CURSED if has_curse_luck else (COLOR_STAT_MODIFIED if luck_modified else COLOR_STAT_BASE)
	if has_curse_luck:
		var curse_luck = CurseEffects.get_luck_multiplier() if CurseEffects else 1.0
		stats.append({
			"name": "Luck",
			"value": "%.0f%%" % (curse_luck * luck * 100),
			"format": "%.0f%%",
			"color": luck_color
		})
	elif luck_modified:
		stats.append({
			"name": "Luck",
			"value": "%.0f%%" % (luck * 100),
			"format": "%.0f%%",
			"color": luck_color
		})

	# Pickup Range
	var pickup = player.pickup_range_multiplier if "pickup_range_multiplier" in player else 1.0
	if pickup > 1.0:
		stats.append({
			"name": "Pickup Range",
			"value": "%.0f%%" % (pickup * 100),
			"format": "%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	# XP Gain
	var xp_mult = 1.0 + bonuses.get("xp_gain", 0.0)
	if AbilityManager:
		xp_mult *= AbilityManager.get_xp_multiplier()
	if xp_mult > 1.0:
		stats.append({
			"name": "XP Gain",
			"value": "+%.0f%%" % ((xp_mult - 1.0) * 100),
			"format": "+%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	# Coin Gain
	var coin_mult = 1.0 + bonuses.get("coin_gain", 0.0)
	if AbilityManager:
		coin_mult *= AbilityManager.get_coin_gain_multiplier()
	if coin_mult > 1.0:
		stats.append({
			"name": "Coin Gain",
			"value": "+%.0f%%" % ((coin_mult - 1.0) * 100),
			"format": "+%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	# HP Regen
	var regen = bonuses.get("hp_regen", 0.0)
	if regen > 0:
		stats.append({
			"name": "HP Regen",
			"value": "+%.1f/s" % regen,
			"format": "+%.1f/s",
			"color": COLOR_STAT_MODIFIED
		})

	# HP on Kill
	var hp_on_kill = bonuses.get("hp_on_kill", 0.0)
	if hp_on_kill > 0:
		stats.append({
			"name": "HP on Kill",
			"value": "+%d" % int(hp_on_kill),
			"format": "+%d",
			"color": COLOR_STAT_MODIFIED
		})

	# Projectile count
	var proj_count = bonuses.get("projectile_count", 0)
	if proj_count > 0:
		stats.append({
			"name": "Extra Projectiles",
			"value": "+%d" % proj_count,
			"format": "+%d",
			"color": COLOR_STAT_MODIFIED
		})

	# AoE Size
	var aoe = bonuses.get("aoe_size", 0.0)
	if aoe > 0:
		stats.append({
			"name": "AoE Size",
			"value": "+%.0f%%" % (aoe * 100),
			"format": "+%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	# Projectile Speed
	var proj_speed = 1.0
	if AbilityManager:
		proj_speed = AbilityManager.get_projectile_speed_multiplier()
	if proj_speed > 1.0:
		stats.append({
			"name": "Projectile Speed",
			"value": "+%.0f%%" % ((proj_speed - 1.0) * 100),
			"format": "+%.0f%%",
			"color": COLOR_STAT_MODIFIED
		})

	return stats

func _on_resume_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	hide_menu()
	emit_signal("resumed")

func _on_give_up_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	hide_menu()
	emit_signal("gave_up")

# ============================================
# OPTIONS TAB
# ============================================

func _populate_options() -> void:
	# Clear existing
	for child in options_container.get_children():
		child.queue_free()

	# Music toggle
	_create_option_toggle("Music", GameSettings.music_enabled, func(toggled): GameSettings.set_music_enabled(toggled))

	# SFX toggle
	_create_option_toggle("Sound Effects", GameSettings.sfx_enabled, func(toggled): GameSettings.set_sfx_enabled(toggled))

	# Haptics toggle
	_create_option_toggle("Haptics", GameSettings.haptics_enabled, func(toggled): GameSettings.set_haptics_enabled(toggled))

	# Screen shake toggle
	_create_option_toggle("Screen Shake", GameSettings.screen_shake_enabled, func(toggled): GameSettings.set_screen_shake_enabled(toggled))

	# Status text toggle (BURN, POISON, etc. over enemies)
	_create_option_toggle("Status Text", GameSettings.status_text_enabled, func(toggled): GameSettings.set_status_text_enabled(toggled))

	# Freeze frames toggle (hitstop effects)
	_create_option_toggle("Freeze Frames", GameSettings.freeze_frames_enabled, func(toggled): GameSettings.set_freeze_frames_enabled(toggled))

	# Visual effects toggle (tinting, chromatic aberration, etc.)
	_create_option_toggle("Visual Effects", GameSettings.visual_effects_enabled, func(toggled): GameSettings.set_visual_effects_enabled(toggled))

	# Track missions toggle
	_create_option_toggle("Track Missions", GameSettings.track_missions_enabled, func(toggled): GameSettings.set_track_missions_enabled(toggled))

func _create_option_toggle(label_text: String, initial_value: bool, on_toggle: Callable) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_container.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", COLOR_TEXT)
	hbox.add_child(label)

	var toggle = CheckButton.new()
	toggle.button_pressed = initial_value
	toggle.toggled.connect(on_toggle)
	hbox.add_child(toggle)

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_resume_pressed()
