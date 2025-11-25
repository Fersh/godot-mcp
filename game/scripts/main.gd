extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ability_selection: CanvasLayer = $AbilitySelection

var game_over_scene: PackedScene = preload("res://scenes/game_over.tscn")
var game_time: float = 0.0
var kill_count: int = 0

func _ready() -> void:
	# Connect player signals
	if player:
		player.level_up.connect(_on_player_level_up)
		player.player_died.connect(_on_player_died)

	# Start background music
	if SoundManager:
		SoundManager.play_music()

func _process(delta: float) -> void:
	game_time += delta

func _on_player_level_up(new_level: int) -> void:
	# Get random abilities and show selection
	var choices = AbilityManager.get_random_abilities(3)
	if choices.size() > 0:
		ability_selection.show_choices(choices)

func _on_player_died() -> void:
	# Wait for death animation then show game over
	await get_tree().create_timer(2.0).timeout
	show_game_over()

func show_game_over() -> void:
	get_tree().paused = true

	var game_over = game_over_scene.instantiate()

	# Get stats
	var level = player.current_level if player else 1
	var stats_display = get_node_or_null("StatsDisplay")
	if stats_display and stats_display.has_method("get_kill_count"):
		kill_count = stats_display.get_kill_count()

	game_over.set_stats(level, game_time, kill_count)
	add_child(game_over)

func add_kill() -> void:
	kill_count += 1
