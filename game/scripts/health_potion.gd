extends Area2D

# Health potion tiers based on game time
# Tier 1 (0-3min): fb265.png - +10 HP
# Tier 2 (3-6min): fb266.png - +15 HP
# Tier 3 (6-9min): fb267.png - +20 HP
# Tier 4 (9-12min): fb268.png - +25 HP
# Tier 5 (12-15min+): fb269.png - +30 HP

@export var heal_amount: float = 10.0
@export var tier: int = 1
@export var bob_speed: float = 4.0
@export var bob_height: float = 4.0
@export var magnet_range: float = 60.0
@export var magnet_speed: float = 350.0
@export var collect_distance: float = 20.0

var initial_y: float = 0.0
var time: float = 0.0
var is_magnetized: bool = false
var player: Node2D = null
var collected: bool = false

@onready var sprite: Sprite2D = $Sprite

# Tier configuration
const TIER_DATA = {
	1: {"icon": "res://assets/sprites/icons/raven/32x32/fb265.png", "heal": 10.0},
	2: {"icon": "res://assets/sprites/icons/raven/32x32/fb266.png", "heal": 15.0},
	3: {"icon": "res://assets/sprites/icons/raven/32x32/fb267.png", "heal": 20.0},
	4: {"icon": "res://assets/sprites/icons/raven/32x32/fb268.png", "heal": 25.0},
	5: {"icon": "res://assets/sprites/icons/raven/32x32/fb269.png", "heal": 30.0},
}

func _ready() -> void:
	initial_y = position.y
	time = randf() * TAU
	_apply_tier()

func _apply_tier() -> void:
	if tier < 1:
		tier = 1
	if tier > 5:
		tier = 5

	var data = TIER_DATA.get(tier, TIER_DATA[1])
	heal_amount = data.heal

	if sprite and ResourceLoader.exists(data.icon):
		sprite.texture = load(data.icon)

func setup_tier(potion_tier: int) -> void:
	tier = potion_tier
	_apply_tier()

func _physics_process(delta: float) -> void:
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
			var direction = (player.global_position - global_position).normalized()
			global_position += direction * magnet_speed * delta

			if distance < collect_distance:
				collect_potion()
				return

	# Only bob if not magnetized
	if not is_magnetized:
		time += delta * bob_speed
		position.y = initial_y + sin(time) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		collect_potion()

func collect_potion() -> void:
	if collected:
		return
	collected = true

	if player and player.has_method("heal"):
		player.heal(heal_amount, true, true)  # show_particles = true

	# Play heal sound
	if SoundManager and SoundManager.has_method("play_heal"):
		SoundManager.play_heal()
	elif SoundManager:
		SoundManager.play_xp()  # Fallback to xp sound

	queue_free()

# Static method to determine which tier potion to drop based on game time
static func get_tier_for_time(game_time_seconds: float) -> int:
	# Time thresholds in seconds
	if game_time_seconds < 180:  # 0-3 min
		return 1
	elif game_time_seconds < 360:  # 3-6 min
		return 2
	elif game_time_seconds < 540:  # 6-9 min
		return 3
	elif game_time_seconds < 720:  # 9-12 min
		return 4
	else:  # 12+ min
		return 5

# Static method to check if a potion should drop
# Base 2% chance, with higher tiers having weighted chance at later times
static func should_drop_potion(game_time_seconds: float) -> Dictionary:
	var base_chance = 0.02  # 2% base

	# Determine max tier available
	var max_tier = get_tier_for_time(game_time_seconds)

	# Roll for drop
	if randf() > base_chance:
		return {"drop": false, "tier": 0}

	# If we get a drop, determine which tier
	# Later in game, higher chance for better potions, but can still get lower ones
	var tier_weights: Array[float] = []
	var total_weight = 0.0

	for t in range(1, max_tier + 1):
		# Higher tiers get more weight as time goes on
		var weight = float(t)
		tier_weights.append(weight)
		total_weight += weight

	# Roll for tier
	var roll = randf() * total_weight
	var cumulative = 0.0

	for i in range(tier_weights.size()):
		cumulative += tier_weights[i]
		if roll <= cumulative:
			return {"drop": true, "tier": i + 1}

	return {"drop": true, "tier": max_tier}
