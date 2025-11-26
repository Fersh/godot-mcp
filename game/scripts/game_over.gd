extends CanvasLayer

@onready var points_label: Label = $Panel/VBoxContainer/StatsContainer/LeftStats/PointsLabel
@onready var time_label: Label = $Panel/VBoxContainer/StatsContainer/LeftStats/TimeLabel
@onready var best_time_label: Label = $Panel/VBoxContainer/StatsContainer/LeftStats/BestTimeLabel
@onready var level_label: Label = $Panel/VBoxContainer/StatsContainer/RightStats/LevelLabel
@onready var kills_label: Label = $Panel/VBoxContainer/StatsContainer/RightStats/KillsLabel
@onready var best_kills_label: Label = $Panel/VBoxContainer/StatsContainer/RightStats/BestKillsLabel
@onready var coins_label: Label = $Panel/VBoxContainer/CoinsLabel
@onready var play_again_button: Button = $Panel/VBoxContainer/ButtonContainer/PlayAgainButton
@onready var main_menu_button: Button = $Panel/VBoxContainer/ButtonContainer/MainMenuButton
@onready var loot_container: HBoxContainer = $Panel/VBoxContainer/LootContainer

var final_level: int = 1
var final_time: float = 0.0
var final_kills: int = 0
var final_coins: int = 0
var final_points: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	play_again_button.pressed.connect(_on_play_again_pressed)
	main_menu_button.pressed.connect(_on_main_menu_pressed)

	# Style the buttons
	_style_play_again_button()
	_style_main_menu_button()

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
	level_label.text = "Level: %d" % final_level
	kills_label.text = "Kills: %s" % format_number(final_kills)
	coins_label.text = "+%s coins" % format_number(final_coins)

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

func _input(event: InputEvent) -> void:
	# Allow play again with spacebar or enter
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_play_again_pressed()

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

func _style_main_menu_button() -> void:
	# Darker, secondary button for Main Menu
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.25, 0.25, 0.3, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.15, 0.15, 0.2, 1)
	style_normal.corner_radius_top_left = 8
	style_normal.corner_radius_top_right = 8
	style_normal.corner_radius_bottom_left = 8
	style_normal.corner_radius_bottom_right = 8

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.35, 0.4, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.2, 0.2, 0.25, 1)
	style_hover.corner_radius_top_left = 8
	style_hover.corner_radius_top_right = 8
	style_hover.corner_radius_bottom_left = 8
	style_hover.corner_radius_bottom_right = 8

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.2, 0.2, 0.25, 1)
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 5
	style_pressed.border_width_bottom = 4
	style_pressed.border_color = Color(0.12, 0.12, 0.15, 1)
	style_pressed.corner_radius_top_left = 8
	style_pressed.corner_radius_top_right = 8
	style_pressed.corner_radius_bottom_left = 8
	style_pressed.corner_radius_bottom_right = 8

	main_menu_button.add_theme_stylebox_override("normal", style_normal)
	main_menu_button.add_theme_stylebox_override("hover", style_hover)
	main_menu_button.add_theme_stylebox_override("pressed", style_pressed)
	main_menu_button.add_theme_stylebox_override("focus", style_normal)
