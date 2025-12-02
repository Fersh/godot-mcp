extends CanvasLayer

# Stats will be created dynamically, not from scene
var points_label: Label = null
var coins_label: Label = null
var wave_label: Label = null
var points_icon: TextureRect = null
var coins_icon: TextureRect = null
var time_icon: TextureRect = null

var player: Node2D = null
var points: int = 0
var displayed_points: float = 0.0  # For smooth counting animation
var coins: int = 0
var displayed_coins: float = 0.0  # For smooth counting animation
var kills: int = 0
var time_survived: float = 0.0
var last_time_points_second: int = 0  # Track last second we gave time points
var items_collected: int = 0
var pixel_font: Font = null

const POINTS_PER_KILL = 100
const POINTS_PER_XP = 10
const POINTS_PER_COIN = 50
const POINTS_PER_SECOND = 5  # Points awarded each second alive
const POINTS_PER_LEVEL_UP = 500  # Bonus for leveling up
const POINTS_PER_ITEM = 200  # Points for picking up items

# Icon paths
const COINS_ICON_PATH = "res://assets/sprites/icons/raven/32x32/fb136.png"
const POINTS_ICON_PATH = "res://assets/sprites/icons/raven/32x32/fb673.png"
const TIME_ICON_PATH = "res://assets/sprites/icons/raven/32x32/fb86.png"

# Position constants
const MARGIN = 48
const PAUSE_BUTTON_SIZE = 32
const ICON_SIZE = 24
const SPACING = 8

# Smooth counting speed (points per second to catch up)
const COUNT_SPEED_MULTIPLIER = 5.0  # Catch up at 5x the difference per second

func _get_points_multiplier() -> float:
	"""Get the combined points multiplier from difficulty and curses."""
	var multiplier = 1.0

	# Difficulty multiplier
	if DifficultyManager:
		multiplier *= DifficultyManager.get_points_multiplier()

	# Curse multiplier (stacking bonus from princesses)
	if CurseEffects:
		multiplier *= CurseEffects.get_points_multiplier()

	return multiplier

func _ready() -> void:
	add_to_group("stats_display")

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Create UI dynamically
	_create_stats_ui()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_gained)
		player.connect("level_up", _on_level_up)
	update_display()

func _create_stats_ui() -> void:
	# Remove any existing MarginContainer from the scene
	var existing = get_node_or_null("MarginContainer")
	if existing:
		existing.queue_free()

	# Create main container - positioned at top left, right of pause button (stacked vertically)
	var container = VBoxContainer.new()
	container.name = "StatsContainer"
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.offset_left = MARGIN + PAUSE_BUTTON_SIZE + 24  # Right of pause button with more spacing
	container.offset_top = MARGIN  # Aligned with pause button top
	container.add_theme_constant_override("separation", 4)  # Tighter vertical spacing
	add_child(container)

	# Create points row (icon + value)
	var points_row = _create_stat_row(POINTS_ICON_PATH, Color(1, 1, 1, 1))
	points_icon = points_row.get_node("Icon")
	points_label = points_row.get_node("Label")
	container.add_child(points_row)

	# Create coins row (icon + value)
	var coins_row = _create_stat_row(COINS_ICON_PATH, Color(1, 0.84, 0, 1))
	coins_icon = coins_row.get_node("Icon")
	coins_label = coins_row.get_node("Label")
	container.add_child(coins_row)

	# Create time row (icon + value)
	var time_row = _create_stat_row(TIME_ICON_PATH, Color(0.7, 0.9, 1, 1))
	time_icon = time_row.get_node("Icon")
	wave_label = time_row.get_node("Label")
	container.add_child(time_row)

func _create_stat_row(icon_path: String, label_color: Color) -> HBoxContainer:
	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)

	# Icon
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	if ResourceLoader.exists(icon_path):
		icon.texture = load(icon_path)
	row.add_child(icon)

	# Value label
	var label = Label.new()
	label.name = "Label"
	label.text = "0"
	label.add_theme_color_override("font_color", label_color)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 2)
	label.add_theme_constant_override("shadow_offset_y", 2)
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 14)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	row.add_child(label)

	return row

func _process(delta: float) -> void:
	time_survived += delta

	# Award points per second survived (with difficulty multiplier)
	var current_second = int(time_survived)
	if current_second > last_time_points_second:
		var seconds_to_award = current_second - last_time_points_second
		points += int(seconds_to_award * POINTS_PER_SECOND * _get_points_multiplier())
		last_time_points_second = current_second
		if StatsManager:
			StatsManager.set_points(points)

	# Smoothly animate displayed points towards actual points
	if displayed_points < points:
		var diff = points - displayed_points
		var increment = max(diff * COUNT_SPEED_MULTIPLIER * delta, 1.0)
		displayed_points = min(displayed_points + increment, float(points))
		_update_points_display()

	# Smoothly animate displayed coins towards actual coins
	if displayed_coins < coins:
		var diff = coins - displayed_coins
		var increment = max(diff * COUNT_SPEED_MULTIPLIER * delta, 0.5)
		displayed_coins = min(displayed_coins + increment, float(coins))
		_update_coins_display()

	update_wave_display()
	# Update StatsManager
	if StatsManager:
		StatsManager.set_time(time_survived)

func add_kill_points() -> void:
	kills += 1
	points += int(POINTS_PER_KILL * _get_points_multiplier())
	update_display()
	# Update StatsManager
	if StatsManager:
		StatsManager.add_kill()
		StatsManager.set_points(points)

func get_kill_count() -> int:
	return kills

func add_coin() -> void:
	coins += 1
	points += int(POINTS_PER_COIN * _get_points_multiplier())
	update_display()
	# Update StatsManager
	if StatsManager:
		StatsManager.add_coin()
		StatsManager.set_points(points)

func add_xp_points(amount: float) -> void:
	points += int(amount * POINTS_PER_XP * _get_points_multiplier())
	update_display()

func add_item_points() -> void:
	items_collected += 1
	points += int(POINTS_PER_ITEM * _get_points_multiplier())
	update_display()
	if StatsManager:
		StatsManager.set_points(points)

func _on_xp_gained(_current_xp: float, _xp_needed: float, _level: int) -> void:
	# XP points are added via add_xp_points when coins are collected
	pass

func _on_level_up(new_level: int) -> void:
	# Award bonus points for leveling up (with difficulty multiplier)
	points += int(POINTS_PER_LEVEL_UP * _get_points_multiplier())
	update_display()
	if StatsManager:
		StatsManager.set_level(new_level)
		StatsManager.set_points(points)

func update_display() -> void:
	_update_points_display()
	_update_coins_display()

func _format_number(num: int) -> String:
	var str_num = str(num)
	var result = ""
	var count = 0
	for i in range(str_num.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			result = "," + result
		result = str_num[i] + result
		count += 1
	return result

func _update_points_display() -> void:
	if points_label:
		points_label.text = _format_number(int(displayed_points))

func _get_coin_multiplier() -> float:
	"""Get the combined coin multiplier from permanent upgrades and curses."""
	var multiplier = 1.0

	# Permanent upgrade bonus
	if PermanentUpgrades:
		multiplier += PermanentUpgrades.get_all_bonuses().get("coin_gain", 0.0)

	# Curse multiplier (stacking bonus from princesses)
	if CurseEffects:
		multiplier *= CurseEffects.get_points_multiplier()

	return multiplier

func _update_coins_display() -> void:
	if coins_label:
		var multiplier = _get_coin_multiplier()
		var multiplied_coins = int(ceil(displayed_coins * multiplier))
		coins_label.text = _format_number(multiplied_coins)

func update_wave_display() -> void:
	if wave_label:
		var minutes = int(time_survived) / 60
		var seconds = int(time_survived) % 60
		wave_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
