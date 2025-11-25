extends Node2D

@export var enemy_scene: PackedScene
@export var spawn_interval: float = 1.0  # Reduced spawn rate (25% slower)
@export var min_spawn_distance: float = 200.0

const ARENA_SIZE = 1536

var spawn_timer: float = 0.0

func _process(delta: float) -> void:
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
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
