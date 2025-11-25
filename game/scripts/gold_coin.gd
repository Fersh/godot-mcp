extends Area2D

@export var xp_value: float = 0.15  # Reduced XP gain (50% of previous)
@export var bob_speed: float = 3.0
@export var bob_height: float = 5.0
@export var magnet_range: float = 80.0
@export var magnet_speed: float = 400.0
@export var collect_distance: float = 20.0

var initial_y: float = 0.0
var time: float = 0.0
var is_magnetized: bool = false
var player: Node2D = null
var collected: bool = false

func _ready() -> void:
	initial_y = position.y
	time = randf() * TAU

func _physics_process(delta: float) -> void:
	# Find player if not found
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)

		# Get pickup range from player (ability modified)
		var effective_range = magnet_range
		if player.has_method("get_pickup_range"):
			effective_range = player.get_pickup_range()

		# Start magnetizing when player is close
		if distance < effective_range:
			is_magnetized = true

		if is_magnetized:
			# Move toward player
			var direction = (player.global_position - global_position).normalized()
			global_position += direction * magnet_speed * delta

			# Collect when very close
			if distance < collect_distance:
				collect_coin()
				return

	# Only bob if not magnetized
	if not is_magnetized:
		time += delta * bob_speed
		position.y = initial_y + sin(time) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect_coin()

func collect_coin() -> void:
	if collected:
		return
	collected = true

	if player and player.has_method("add_xp"):
		player.add_xp(xp_value)

	# Play XP pickup sound
	if SoundManager:
		SoundManager.play_xp()

	# Update stats display
	var stats = get_tree().get_first_node_in_group("stats_display")
	if stats == null:
		stats = get_node_or_null("/root/Main/StatsDisplay")
	if stats and stats.has_method("add_coin"):
		stats.add_coin()

	queue_free()
