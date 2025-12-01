extends CanvasLayer

@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var points_label: Label = $Panel/VBoxContainer/StatsContainer/PointsLabel
@onready var time_label: Label = $Panel/VBoxContainer/StatsContainer/TimeLabel
@onready var best_time_label: Label = $Panel/VBoxContainer/StatsContainer/BestTimeLabel
@onready var kills_label: Label = $Panel/VBoxContainer/StatsContainer/KillsLabel
@onready var best_kills_label: Label = $Panel/VBoxContainer/StatsContainer/BestKillsLabel
@onready var coins_label: Label = $Panel/VBoxContainer/StatsContainer/CoinsLabel
@onready var play_again_button: Button = $Panel/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var loot_container: HBoxContainer = $Panel/VBoxContainer/LootContainer

var final_level: int = 1
var final_time: float = 0.0
var final_kills: int = 0
var final_coins: int = 0
var final_points: int = 0
var player_gave_up: bool = false

# Settings dropdown
var settings_dropdown: PanelContainer = null
var settings_visible: bool = false

# Font
var pixel_font: Font = null

func _ready() -> void:
	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_again_button.pressed.connect(_on_play_again_pressed)

	# Set title based on whether player gave up (set before _ready via set_gave_up)
	if player_gave_up and title_label:
		title_label.text = "YOU COWARD"

	# Show difficulty info for challenge mode deaths
	_show_difficulty_info()

	# Play game over music (5. Aurora)
	if SoundManager:
		SoundManager.play_game_over_music()

	# Style the buttons
	_style_play_again_button()

	# Create home button (top left)
	_create_home_button()

	# Create settings button (top right)
	_create_settings_button()

	# Polish: Animated stats reveal (#24)
	_setup_animated_reveal()

	# Get stats from StatsManager
	if StatsManager:
		var run = StatsManager.get_run_stats()
		final_level = run.level
		final_time = run.time
		final_kills = run.kills
		final_coins = run.coins
		final_points = run.points

		# End the run (updates lifetime stats and saves)
		StatsManager.end_run()

		# Get updated lifetime stats
		var lifetime = StatsManager.get_lifetime_stats()

		# Calculate coins earned with bonus
		var coin_bonus = 1.0
		if PermanentUpgrades:
			coin_bonus += PermanentUpgrades.get_all_bonuses().get("coin_gain", 0.0)
		var coins_earned = int(final_coins * coin_bonus)

		# Update best labels
		best_time_label.text = "Best: %s" % format_time(lifetime.best_time)
		best_kills_label.text = "Best: %s" % format_number(lifetime.best_kills)

	# Format the run stats with commas
	points_label.text = "Points: %s" % format_number(final_points)
	time_label.text = "Time: %s" % format_time(final_time)
	kills_label.text = "Kills: %s" % format_number(final_kills)
	coins_label.text = "+%s Coins" % format_number(final_coins)

	# Show and commit loot
	_display_loot()

func set_stats(level: int, time: float, kills: int) -> void:
	final_level = level
	final_time = time
	final_kills = kills

func set_gave_up(gave_up: bool) -> void:
	player_gave_up = gave_up
	if player_gave_up and title_label:
		title_label.text = "YOU COWARD"

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

func format_number(num: int) -> String:
	var str_num = str(num)
	var result = ""
	var count = 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result

func _on_play_again_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# Reset run stats and abilities, then restart game
	if StatsManager:
		StatsManager.reset_run()
	if AbilityManager:
		AbilityManager.reset()

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_main_menu_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# Unpause and go to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _display_loot() -> void:
	if not EquipmentManager:
		return

	var pending = EquipmentManager.pending_items
	if pending.size() == 0:
		# No loot to display
		if loot_container:
			var no_loot_container = VBoxContainer.new()
			no_loot_container.alignment = BoxContainer.ALIGNMENT_CENTER

			var no_loot = Label.new()
			no_loot.text = "LOOT:"
			no_loot.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			no_loot.add_theme_font_size_override("font_size", 12)
			no_loot.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			if pixel_font:
				no_loot.add_theme_font_override("font", pixel_font)
			no_loot_container.add_child(no_loot)

			var do_better = Label.new()
			do_better.text = "None this run. Do better."
			do_better.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			do_better.add_theme_font_size_override("font_size", 10)
			do_better.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
			if pixel_font:
				do_better.add_theme_font_override("font", pixel_font)
			no_loot_container.add_child(do_better)

			loot_container.add_child(no_loot_container)
		return

	# Display each item BEFORE committing (commit clears the array)
	if loot_container:
		var loot_label = Label.new()
		loot_label.text = "LOOT: "
		loot_label.add_theme_font_size_override("font_size", 12)
		loot_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		if pixel_font:
			loot_label.add_theme_font_override("font", pixel_font)
		loot_container.add_child(loot_label)

		for item in pending:
			var item_card = _create_loot_card(item)
			loot_container.add_child(item_card)

	# Commit the pending items to permanent inventory (after displaying)
	EquipmentManager.commit_pending_items()

var active_tooltip: PanelContainer = null

func _create_loot_card(item: ItemData) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(50, 50)  # Smaller cards

	# Center container for icon and name
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 2)

	# Icon - smaller and centered
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(24, 24)  # Smaller icon
		var icon_center = CenterContainer.new()
		icon_center.add_child(icon)
		vbox.add_child(icon_center)

	# Name (truncated) - smaller font, centered
	var name_label = Label.new()
	var display_name = item.get_full_name()
	if display_name.length() > 6:
		display_name = display_name.substr(0, 5) + ".."
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 6)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	center.add_child(vbox)

	# Style based on rarity
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	style.border_color = item.get_rarity_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	card.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
	card.add_theme_stylebox_override("hover", hover_style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 3)
	margin.add_theme_constant_override("margin_right", 3)
	margin.add_theme_constant_override("margin_top", 3)
	margin.add_theme_constant_override("margin_bottom", 3)
	margin.add_child(center)
	card.add_child(margin)

	# Connect press to show tooltip
	card.pressed.connect(_show_item_tooltip.bind(item, card))

	return card

func _show_item_tooltip(item: ItemData, card: Button) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# Remove existing tooltip
	if active_tooltip:
		active_tooltip.queue_free()
		active_tooltip = null

	# Create tooltip panel
	active_tooltip = PanelContainer.new()

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.08, 0.08, 0.1, 0.95)
	panel_style.border_color = item.get_rarity_color()
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(6)
	active_tooltip.add_theme_stylebox_override("panel", panel_style)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 10)
	margin.add_theme_constant_override("margin_right", 10)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	# Item name
	var name_label = Label.new()
	name_label.text = item.get_full_name()
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Rarity and slot
	var type_label = Label.new()
	type_label.text = "%s %s" % [item.get_rarity_name(), item.get_slot_name()]
	type_label.add_theme_font_size_override("font_size", 9)
	type_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		type_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(type_label)

	# Stats
	var stats_label = Label.new()
	stats_label.text = item.get_stat_description()
	stats_label.add_theme_font_size_override("font_size", 10)
	stats_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	stats_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	stats_label.custom_minimum_size = Vector2(150, 0)
	if pixel_font:
		stats_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(stats_label)

	margin.add_child(vbox)
	active_tooltip.add_child(margin)

	# Position above the card
	add_child(active_tooltip)
	await get_tree().process_frame  # Wait for size calculation

	var card_global = card.global_position
	var tooltip_size = active_tooltip.size
	active_tooltip.global_position = Vector2(
		card_global.x + (card.size.x / 2) - (tooltip_size.x / 2),
		card_global.y - tooltip_size.y - 10
	)

func _style_play_again_button() -> void:
	# Golden/green prominent button for Play Again
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.75, 0.3, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.1, 0.4, 0.15, 1)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.85, 0.4, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.15, 0.5, 0.2, 1)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.15, 0.6, 0.25, 1)
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 5
	style_pressed.border_width_bottom = 4
	style_pressed.border_color = Color(0.08, 0.35, 0.12, 1)
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8

	play_again_button.add_theme_stylebox_override("normal", style_normal)
	play_again_button.add_theme_stylebox_override("hover", style_hover)
	play_again_button.add_theme_stylebox_override("pressed", style_pressed)
	play_again_button.add_theme_stylebox_override("focus", style_normal)

func _create_home_button() -> void:
	var home_btn = Button.new()
	home_btn.custom_minimum_size = Vector2(50, 50)
	home_btn.pressed.connect(_on_main_menu_pressed)

	# Create icon from StonePixel spritesheet (5 cols x 4 rows, 32x32 per icon)
	# Home icon is at row 1, column 2 (0-indexed) - 2nd row, 3rd icon
	var icons_texture = load("res://assets/sprites/effects/ui/StonePixel/Icons/32x32.png")
	if icons_texture:
		var atlas = AtlasTexture.new()
		atlas.atlas = icons_texture
		atlas.region = Rect2(2 * 32, 1 * 32, 32, 32)  # col 2, row 1

		var icon_rect = TextureRect.new()
		icon_rect.texture = atlas
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.add_child(icon_rect)
		home_btn.add_child(center)

	# Style the button - light brown/beige background
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.76, 0.60, 0.42, 0.95)
	style.set_corner_radius_all(8)
	home_btn.add_theme_stylebox_override("normal", style)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.82, 0.68, 0.50, 0.95)
	style_hover.set_corner_radius_all(8)
	home_btn.add_theme_stylebox_override("hover", style_hover)

	# Position in top left
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 60)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_child(home_btn)
	add_child(margin)

func _create_settings_button() -> void:
	var settings_btn = Button.new()
	settings_btn.text = "⚙️"
	settings_btn.custom_minimum_size = Vector2(50, 50)
	settings_btn.add_theme_font_size_override("font_size", 24)
	settings_btn.pressed.connect(_toggle_settings_dropdown)

	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.set_corner_radius_all(8)
	settings_btn.add_theme_stylebox_override("normal", style)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.35, 0.9)
	style_hover.set_corner_radius_all(8)
	settings_btn.add_theme_stylebox_override("hover", style_hover)

	# Position in top right
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	margin.add_theme_constant_override("margin_right", 20)
	margin.add_theme_constant_override("margin_top", 60)
	margin.add_child(settings_btn)
	add_child(margin)

	# Create the dropdown (hidden initially)
	_create_settings_dropdown()

func _create_settings_dropdown() -> void:
	settings_dropdown = PanelContainer.new()
	settings_dropdown.visible = false

	# Style the panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.12, 0.12, 0.15, 0.95)
	panel_style.border_color = Color(0.3, 0.3, 0.35, 1)
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	settings_dropdown.add_theme_stylebox_override("panel", panel_style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)

	# Title
	var title = Label.new()
	title.text = "Settings"
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	vbox.add_child(title)

	# Music checkbox
	var music_check = CheckBox.new()
	music_check.text = "Music"
	music_check.button_pressed = GameSettings.music_enabled if GameSettings else true
	music_check.toggled.connect(func(pressed): GameSettings.set_music_enabled(pressed))
	vbox.add_child(music_check)

	# SFX checkbox
	var sfx_check = CheckBox.new()
	sfx_check.text = "Sound Effects"
	sfx_check.button_pressed = GameSettings.sfx_enabled if GameSettings else true
	sfx_check.toggled.connect(func(pressed): GameSettings.set_sfx_enabled(pressed))
	vbox.add_child(sfx_check)

	# Screen Shake checkbox
	var shake_check = CheckBox.new()
	shake_check.text = "Screen Shake"
	shake_check.button_pressed = GameSettings.screen_shake_enabled if GameSettings else true
	shake_check.toggled.connect(func(pressed): GameSettings.set_screen_shake_enabled(pressed))
	vbox.add_child(shake_check)

	# Haptics checkbox
	var haptics_check = CheckBox.new()
	haptics_check.text = "Haptics"
	haptics_check.button_pressed = GameSettings.haptics_enabled if GameSettings else true
	haptics_check.toggled.connect(func(pressed): GameSettings.set_haptics_enabled(pressed))
	vbox.add_child(haptics_check)

	# Volume section
	var vol_label = Label.new()
	vol_label.text = "Volume"
	vol_label.add_theme_font_size_override("font_size", 12)
	vol_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	if pixel_font:
		vol_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(vol_label)

	var vol_hbox = HBoxContainer.new()
	vol_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var vol_down = Button.new()
	vol_down.text = "-"
	vol_down.custom_minimum_size = Vector2(40, 40)
	vol_down.pressed.connect(func():
		if SoundManager:
			SoundManager.play_click()
		if HapticManager:
			HapticManager.light()
		GameSettings.decrease_volume())
	vol_hbox.add_child(vol_down)

	var vol_up = Button.new()
	vol_up.text = "+"
	vol_up.custom_minimum_size = Vector2(40, 40)
	vol_up.pressed.connect(func():
		if SoundManager:
			SoundManager.play_click()
		if HapticManager:
			HapticManager.light()
		GameSettings.increase_volume())
	vol_hbox.add_child(vol_up)

	vbox.add_child(vol_hbox)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 8)
	margin.add_theme_constant_override("margin_bottom", 8)
	margin.add_child(vbox)
	settings_dropdown.add_child(margin)

	# Position dropdown below settings button
	settings_dropdown.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	settings_dropdown.position = Vector2(-200, 120)
	add_child(settings_dropdown)

func _toggle_settings_dropdown() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	settings_visible = not settings_visible
	settings_dropdown.visible = settings_visible

func _input(event: InputEvent) -> void:
	# Allow play again with spacebar or enter
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_play_again_pressed()

	# Close settings dropdown when clicking outside
	if settings_visible and event is InputEventMouseButton and event.pressed:
		if settings_dropdown and not settings_dropdown.get_global_rect().has_point(event.position):
			# Check if clicking the settings button itself
			var settings_btn_rect = Rect2(Vector2(get_viewport().size.x - 70, 60), Vector2(50, 50))
			if not settings_btn_rect.has_point(event.position):
				settings_visible = false
				settings_dropdown.visible = false

	# Close item tooltip when clicking outside of it
	if active_tooltip and event is InputEventMouseButton and event.pressed:
		if not active_tooltip.get_global_rect().has_point(event.position):
			# Check if clicking on a loot card (don't close if clicking another card)
			var clicked_on_loot = false
			if loot_container:
				for child in loot_container.get_children():
					if child is Button and child.get_global_rect().has_point(event.position):
						clicked_on_loot = true
						break
			if not clicked_on_loot:
				active_tooltip.queue_free()
				active_tooltip = null

# ============================================
# POLISHED DEATH SCREEN ANIMATIONS (#24)
# ============================================

var reveal_delay: float = 0.0
var stats_to_animate: Array = []

func _setup_animated_reveal() -> void:
	"""Setup the staggered animation for stats reveal."""
	# Hide all stat labels initially
	stats_to_animate = [points_label, time_label, best_time_label, kills_label, best_kills_label, coins_label]

	for stat in stats_to_animate:
		if stat:
			stat.modulate.a = 0.0
			# Store original position and offset using custom position property
			stat.set_meta("original_pos", stat.position)

	# Also animate the title
	if title_label:
		title_label.modulate.a = 0.0
		title_label.scale = Vector2(0.5, 0.5)
		title_label.pivot_offset = title_label.size / 2

	# Start the reveal sequence
	_animate_title_reveal()

func _animate_title_reveal() -> void:
	"""Animate the title slamming in."""
	if not title_label:
		_animate_stats_reveal()
		return

	var tween = create_tween()
	tween.tween_property(title_label, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_callback(func():
		# Screen shake on title reveal
		if JuiceManager:
			JuiceManager.shake_medium()
		if HapticManager:
			HapticManager.medium()
		_animate_stats_reveal()
	)

func _animate_stats_reveal() -> void:
	"""Animate stats flying in one by one with center alignment preserved."""
	var delay = 0.0
	var delay_increment = 0.15

	for i in range(stats_to_animate.size()):
		var stat = stats_to_animate[i]
		if stat == null:
			continue

		# Use scale animation instead of position to maintain center alignment
		stat.pivot_offset = stat.size / 2
		stat.scale = Vector2(0.0, 1.0)  # Start squished horizontally

		var tween = create_tween()
		tween.tween_interval(delay)
		tween.tween_property(stat, "modulate:a", 1.0, 0.2)
		tween.parallel().tween_property(stat, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

		# Check for personal best on this stat
		var is_best = _check_if_personal_best(i)
		if is_best:
			tween.tween_callback(func():
				_flash_personal_best(stat)
			)

		delay += delay_increment

	# Animate loot container after stats
	if loot_container:
		loot_container.modulate.a = 0.0
		var loot_tween = create_tween()
		loot_tween.tween_interval(delay + 0.2)
		loot_tween.tween_property(loot_container, "modulate:a", 1.0, 0.3)

	# Animate play again button
	if play_again_button:
		play_again_button.modulate.a = 0.0
		play_again_button.scale = Vector2(0.8, 0.8)
		play_again_button.pivot_offset = play_again_button.size / 2
		var btn_tween = create_tween()
		btn_tween.tween_interval(delay + 0.5)
		btn_tween.tween_property(play_again_button, "modulate:a", 1.0, 0.2)
		btn_tween.parallel().tween_property(play_again_button, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

func _check_if_personal_best(stat_index: int) -> bool:
	"""Check if this stat is a personal best."""
	if not StatsManager:
		return false

	var lifetime = StatsManager.get_lifetime_stats()

	match stat_index:
		1:  # Time
			return final_time >= lifetime.best_time and final_time > 0
		3:  # Kills
			return final_kills >= lifetime.best_kills and final_kills > 0
		_:
			return false

func _flash_personal_best(stat_label: Label) -> void:
	"""Flash effect for personal best stats."""
	if stat_label == null:
		return

	# Create "NEW BEST!" label next to it
	var best_label = Label.new()
	best_label.text = "NEW BEST!"
	best_label.add_theme_font_size_override("font_size", 10)
	best_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))
	if pixel_font:
		best_label.add_theme_font_override("font", pixel_font)
	best_label.position = Vector2(stat_label.size.x + 10, 0)
	best_label.modulate.a = 0.0
	stat_label.add_child(best_label)

	# Animate the label
	var tween = create_tween()
	tween.tween_property(best_label, "modulate:a", 1.0, 0.2)
	tween.tween_property(best_label, "scale", Vector2(1.2, 1.2), 0.1)
	tween.tween_property(best_label, "scale", Vector2(1.0, 1.0), 0.1)

	# Flash the stat itself gold
	var original_color = stat_label.get_theme_color("font_color")
	stat_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1))

	var color_tween = create_tween()
	color_tween.tween_interval(0.5)
	color_tween.tween_callback(func():
		stat_label.add_theme_color_override("font_color", original_color)
	)

	# Haptic feedback
	if HapticManager:
		HapticManager.light()

func _show_difficulty_info() -> void:
	"""Show difficulty/mode info below the title for challenge mode runs."""
	if not DifficultyManager:
		return

	# Only show for challenge mode
	if not DifficultyManager.is_challenge_mode():
		return

	# Create difficulty info label below the title
	var diff_info = Label.new()
	var diff_name = DifficultyManager.get_difficulty_name()
	diff_info.text = "Challenge Mode: %s" % diff_name
	diff_info.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	if pixel_font:
		diff_info.add_theme_font_override("font", pixel_font)
	diff_info.add_theme_font_size_override("font_size", 12)
	diff_info.add_theme_color_override("font_color", DifficultyManager.get_difficulty_color())
	diff_info.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	diff_info.add_theme_constant_override("shadow_offset_x", 2)
	diff_info.add_theme_constant_override("shadow_offset_y", 2)

	# Position below title
	if title_label:
		var parent = title_label.get_parent()
		if parent:
			var title_idx = title_label.get_index()
			parent.add_child(diff_info)
			parent.move_child(diff_info, title_idx + 1)
