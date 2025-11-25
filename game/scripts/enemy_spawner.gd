extends Node2D

@export var enemy_scene: PackedScene
@export var initial_spawn_interval: float = 1.0  # Starting spawn interval
@export var final_spawn_interval: float = 0.5  # Target spawn interval (2x faster)
@export var ramp_up_time: float = 60.0  # Time in seconds to reach full spawn rate
@export var min_spawn_distance: float = 200.0

const ARENA_SIZE = 1536

var spawn_timer: float = 0.0
var game_time: float = 0.0

func _process(delta: float) -> void:
	game_time += delta
	spawn_timer += delta

	# Calculate current spawn interval (scales from initial to final over ramp_up_time)
	var ramp_progress = clamp(game_time / ramp_up_time, 0.0, 1.0)
	var current_interval = lerp(initial_spawn_interval, final_spawn_interval, ramp_progress)

	if spawn_timer >= current_interval:
		spawn_timer = 0.0
		spawn_enemy()

func spawn_enemy() -> void:
	if enemy_scene == null:
		return

	var enemy = enemy_scene.instantiate()
	enemy.global_position = get_spawn_position()
	get_parent().add_child(enemy)

func get_spawn_position() -> Vector2:
	# Spawn from edges of the arena
	var edge = randi() % 4
	var pos: Vector2

	match edge:
		0:  # Top
			pos = Vector2(randf_range(50, ARENA_SIZE - 50), -50)
		1:  # Bottom
			pos = Vector2(randf_range(50, ARENA_SIZE - 50), ARENA_SIZE + 50)
		2:  # Left
			pos = Vector2(-50, randf_range(50, ARENA_SIZE - 50))
		3:  # Right
			pos = Vector2(ARENA_SIZE + 50, randf_range(50, ARENA_SIZE - 50))

	return pos
