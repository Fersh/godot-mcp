extends CanvasLayer

@onready var points_label: Label = $MarginContainer/VBoxContainer/PointsLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/CoinsLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel

var player: Node2D = null
var points: int = 0
var displayed_points: float = 0.0  # For smooth counting animation
var coins: int = 0
var displayed_coins: float = 0.0  # For smooth counting animation
var kills: int = 0
var time_survived: float = 0.0
var last_time_points_second: int = 0  # Track last second we gave time points
var items_collected: int = 0

const POINTS_PER_KILL = 100
const POINTS_PER_XP = 10
const POINTS_PER_COIN = 50
const POINTS_PER_SECOND = 5  # Points awarded each second alive
const POINTS_PER_LEVEL_UP = 500  # Bonus for leveling up
const POINTS_PER_ITEM = 200  # Points for picking up items

# Smooth counting speed (points per second to catch up)
const COUNT_SPEED_MULTIPLIER = 5.0  # Catch up at 5x the difference per second

func _get_points_multiplier() -> float:
	"""Get the difficulty-based points multiplier."""
	if DifficultyManager:
		return DifficultyManager.get_points_multiplier()
	return 1.0

func _ready() -> void:
	add_to_group("stats_display")

	# Apply slight rotation with left side down (~1 degree)
	var margin_container = $MarginContainer
	if margin_container:
		margin_container.pivot_offset = Vector2(margin_container.size.x, 0)  # Rotate from top-right corner
		margin_container.rotation = 0.017  # ~1 degree, left side down

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_gained)
		player.connect("level_up", _on_level_up)
	update_display()

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
	points_label.text = _format_number(int(displayed_points)) + "  POINTS"

func _update_coins_display() -> void:
	coins_label.text = _format_number(int(displayed_coins)) + "  COINS"

func update_wave_display() -> void:
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	wave_label.text = str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2) + "  TIME"
