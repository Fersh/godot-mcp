extends CanvasLayer

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

# Settings dropdown
var settings_dropdown: PanelContainer = null
var settings_visible: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_again_button.pressed.connect(_on_play_again_pressed)

	# Style the buttons
	_style_play_again_button()

	# Create home button (top left)
	_create_home_button()

	# Create settings button (top right)
	_create_settings_button()

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
	# Reset run stats and abilities, then restart game
	if StatsManager:
		StatsManager.reset_run()
	if AbilityManager:
		AbilityManager.reset()

	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_main_menu_pressed() -> void:
	# Unpause and go to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _display_loot() -> void:
	if not EquipmentManager:
		return

	var pending = EquipmentManager.pending_items
	if pending.size() == 0:
		# No loot to display - hide container or show "No loot found"
		if loot_container:
			var no_loot = Label.new()
			no_loot.text = "No loot found this run"
			no_loot.add_theme_font_size_override("font_size", 14)
			no_loot.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
			loot_container.add_child(no_loot)
		return

	# Commit the pending items to permanent inventory
	EquipmentManager.commit_pending_items()

	# Display each item
	if loot_container:
		var loot_label = Label.new()
		loot_label.text = "LOOT: "
		loot_label.add_theme_font_size_override("font_size", 14)
		loot_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
		loot_container.add_child(loot_label)

		for item in pending:
			var item_card = _create_loot_card(item)
			loot_container.add_child(item_card)

func _create_loot_card(item: ItemData) -> Control:
	var card = Button.new()
	card.custom_minimum_size = Vector2(80, 80)
	card.tooltip_text = "%s\n%s %s\n%s" % [
		item.get_full_name(),
		item.get_rarity_name(),
		item.get_slot_name(),
		item.get_stat_description()
	]

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)

	# Icon
	if item.icon_path != "" and ResourceLoader.exists(item.icon_path):
		var icon = TextureRect.new()
		icon.texture = load(item.icon_path)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(40, 40)
		var center = CenterContainer.new()
		center.add_child(icon)
		vbox.add_child(center)

	# Name (truncated)
	var name_label = Label.new()
	var display_name = item.get_full_name()
	if display_name.length() > 10:
		display_name = display_name.substr(0, 9) + ".."
	name_label.text = display_name
	name_label.add_theme_font_size_override("font_size", 9)
	name_label.add_theme_color_override("font_color", item.get_rarity_color())
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Style based on rarity
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.12, 0.9)
	style.border_color = item.get_rarity_color()
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	card.add_theme_stylebox_override("normal", style)

	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 4)
	margin.add_theme_constant_override("margin_right", 4)
	margin.add_theme_constant_override("margin_top", 4)
	margin.add_theme_constant_override("margin_bottom", 4)
	margin.add_child(vbox)
	card.add_child(margin)

	return card

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
	home_btn.text = "🏠"
	home_btn.custom_minimum_size = Vector2(50, 50)
	home_btn.add_theme_font_size_override("font_size", 24)
	home_btn.pressed.connect(_on_main_menu_pressed)

	# Style the button
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.2, 0.2, 0.25, 0.9)
	style.set_corner_radius_all(8)
	home_btn.add_theme_stylebox_override("normal", style)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.3, 0.35, 0.9)
	style_hover.set_corner_radius_all(8)
	home_btn.add_theme_stylebox_override("hover", style_hover)

	# Position in top left
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_TOP_LEFT)
	margin.add_theme_constant_override("margin_left", 20)
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
	title.add_theme_font_size_override("font_size", 18)
	title.add_theme_color_override("font_color", Color(1, 1, 1))
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	vol_label.add_theme_font_size_override("font_size", 14)
	vol_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	vbox.add_child(vol_label)

	var vol_hbox = HBoxContainer.new()
	vol_hbox.alignment = BoxContainer.ALIGNMENT_CENTER

	var vol_down = Button.new()
	vol_down.text = "-"
	vol_down.custom_minimum_size = Vector2(40, 40)
	vol_down.pressed.connect(func(): GameSettings.decrease_volume())
	vol_hbox.add_child(vol_down)

	var vol_up = Button.new()
	vol_up.text = "+"
	vol_up.custom_minimum_size = Vector2(40, 40)
	vol_up.pressed.connect(func(): GameSettings.increase_volume())
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
