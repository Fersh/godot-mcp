extends CanvasLayer

@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel
@onready var restart_button: Button = $Panel/VBoxContainer/RestartButton

var final_level: int = 1
var final_time: float = 0.0
var final_kills: int = 0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	restart_button.pressed.connect(_on_restart_pressed)

	# Format the stats
	var time_str = format_time(final_time)
	stats_label.text = "Level: %d\nTime: %s\nKills: %d" % [final_level, time_str, final_kills]

func set_stats(level: int, time: float, kills: int) -> void:
	final_level = level
	final_time = time
	final_kills = kills

func format_time(seconds: float) -> String:
	var mins = int(seconds) / 60
	var secs = int(seconds) % 60
	return "%02d:%02d" % [mins, secs]

func _on_restart_pressed() -> void:
	# Reset abilities
	if AbilityManager:
		AbilityManager.reset()

	# Unpause and reload
	get_tree().paused = false
	get_tree().reload_current_scene()

func _input(event: InputEvent) -> void:
	# Allow restart with spacebar or enter
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER:
			_on_restart_pressed()
