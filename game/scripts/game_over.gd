extends CanvasLayer

@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var lifetime_stats_label: Label = $Panel/VBoxContainer/LifetimeStatsLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton

var final_level: int = 1
var final_time: float = 0.0
var final_kills: int = 0
var final_coins: int = 0
var final_points: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_pressed)

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

		lifetime_stats_label.text = "Total Runs: %d\nBest Time: %s\nBest Kills: %d\n\n+%d coins added to wallet!\nWallet: %d" % [
			lifetime.total_runs,
			format_time(lifetime.best_time),
			lifetime.best_kills,
			coins_earned,
			StatsManager.spendable_coins
		]

	# Format the run stats
	var time_str = format_time(final_time)
	stats_label.text = "Level: %d\nTime: %s\nKills: %d\nCoins: %d\nPoints: %d" % [
		final_level, time_str, final_kills, final_coins, final_points
	]

func set_stats(level: int, time: float, kills: int) -> void:
	final_level = level
	final_time = time
	final_kills = kills

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

func _on_restart_pressed() -> void:
	# Unpause and go to main menu
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _input(event: InputEvent) -> void:
	# Allow restart with spacebar or enter
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_restart_pressed()
