extends CanvasLayer

@onready var points_label: Label = $MarginContainer/VBoxContainer/PointsLabel
@onready var coins_label: Label = $MarginContainer/VBoxContainer/CoinsLabel
@onready var wave_label: Label = $MarginContainer/VBoxContainer/WaveLabel

var player: Node2D = null
var points: int = 0
var coins: int = 0
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

func _ready() -> void:
	add_to_group("stats_display")
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_gained)
		player.connect("level_up", _on_level_up)
	update_display()

func _process(delta: float) -> void:
	time_survived += delta

	# Award points per second survived
	var current_second = int(time_survived)
	if current_second > last_time_points_second:
		var seconds_to_award = current_second - last_time_points_second
		points += seconds_to_award * POINTS_PER_SECOND
		last_time_points_second = current_second
		update_display()
		if StatsManager:
			StatsManager.set_points(points)

	update_wave_display()
	# Update StatsManager
	if StatsManager:
		StatsManager.set_time(time_survived)

func add_kill_points() -> void:
	kills += 1
	points += POINTS_PER_KILL
	update_display()
	# Update StatsManager
	if StatsManager:
		StatsManager.add_kill()
		StatsManager.set_points(points)

func get_kill_count() -> int:
	return kills

func add_coin() -> void:
	coins += 1
	points += POINTS_PER_COIN
	update_display()
	# Update StatsManager
	if StatsManager:
		StatsManager.add_coin()
		StatsManager.set_points(points)

func add_xp_points(amount: float) -> void:
	points += int(amount * POINTS_PER_XP)
	update_display()

func add_item_points() -> void:
	items_collected += 1
	points += POINTS_PER_ITEM
	update_display()
	if StatsManager:
		StatsManager.set_points(points)

func _on_xp_gained(_current_xp: float, _xp_needed: float, _level: int) -> void:
	# XP points are added via add_xp_points when coins are collected
	pass

func _on_level_up(new_level: int) -> void:
	# Award bonus points for leveling up
	points += POINTS_PER_LEVEL_UP
	update_display()
	if StatsManager:
		StatsManager.set_level(new_level)
		StatsManager.set_points(points)

func update_display() -> void:
	points_label.text = "POINTS  " + str(points)
	coins_label.text = "COINS   " + str(coins)

func update_wave_display() -> void:
	var minutes = int(time_survived) / 60
	var seconds = int(time_survived) % 60
	wave_label.text = "WAVE    " + str(minutes).pad_zeros(2) + ":" + str(seconds).pad_zeros(2)
