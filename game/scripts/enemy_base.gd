class_name EnemyBase
extends CharacterBody2D

# Base stats - override in subclasses or set via exported properties
@export var speed: float = 47.3  # 73 * 0.72 * 0.9 (10% slower)
@export var attack_range: float = 50.0
@export var animation_speed: float = 10.0
@export var max_health: float = 20.0
@export var attack_damage: float = 5.0
@export var attack_cooldown: float = 0.8
@export var windup_duration: float = 0.25
@export var gold_coin_scene: PackedScene
@export var damage_number_scene: PackedScene
@export var death_particles_scene: PackedScene
@export var dropped_item_scene: PackedScene
@export var health_potion_scene: PackedScene

# Enemy type identifier
@export var enemy_type: String = "base"
# Enemy rarity for drop calculations (normal, elite, boss)
@export var enemy_rarity: String = "normal"

var player: Node2D = null
var current_health: float
var is_dying: bool = false
var died_from_crit: bool = false
var died_from_ability: bool = false  # Track ability kills for flying head effect
var attack_timer: float = 0.0
var can_attack: bool = true

# Attack wind-up system
var is_winding_up: bool = false
var windup_timer: float = 0.0

# Stagger system (from melee hits)
var is_staggered: bool = false
var stagger_timer: float = 0.0
const STAGGER_DURATION: float = 0.35

# Stun system (from active abilities)
var is_stunned: bool = false
var stun_timer: float = 0.0

# Slow system (from active abilities)
var is_slowed: bool = false
var slow_timer: float = 0.0
var slow_percent: float = 0.0
var base_speed: float = 0.0

# Burn system (fire damage over time)
var is_burning: bool = false
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
const BURN_TICK_INTERVAL: float = 0.5

# Poison system (damage over time)
var is_poisoned: bool = false
var poison_timer: float = 0.0
var poison_damage: float = 0.0
var poison_tick_timer: float = 0.0
const POISON_TICK_INTERVAL: float = 0.5

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0

# Hit flash
var flash_timer: float = 0.0
var flash_duration: float = 0.1

# Animation - override these in subclasses for different spritesheet layouts
var ROW_IDLE: int = 0
var ROW_MOVE: int = 2
var ROW_ATTACK: int = 5
var ROW_DAMAGE: int = 6
var ROW_DEATH: int = 7
var COLS_PER_ROW: int = 8

var FRAME_COUNTS: Dictionary = {
	0: 4,  # IDLE
	1: 8,  # SLEEP
	2: 8,  # MOVE
	3: 8,  # CARRY
	4: 8,  # CARRY2
	5: 8,  # ATTACK
	6: 3,  # DAMAGE
	7: 6,  # DEATH
}

var current_row: int = 0
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite
@onready var health_bar: Node2D = $HealthBar

func _ready() -> void:
	current_health = max_health
	base_speed = speed  # Store base speed for slow calculations
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	collision_layer = 4
	collision_mask = 9  # Layer 1 (player) + Layer 8 (obstacles)

	if health_bar:
		health_bar.set_health(current_health, max_health)

	if sprite and sprite.material:
		sprite.material = sprite.material.duplicate()

	_on_ready()

# Override in subclasses for custom initialization
func _on_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Update z_index based on Y position for depth sorting with trees
	z_index = int(global_position.y / 10)

	if is_dying:
		update_death_animation(delta)
		return

	handle_hit_flash(delta)
	handle_status_effects(delta)

	if handle_knockback(delta):
		return

	if handle_stagger(delta):
		return

	if handle_stun(delta):
		return

	handle_attack_cooldown(delta)

	if handle_windup(delta):
		return

	_process_behavior(delta)

# Override in subclasses for custom AI behavior
func _process_behavior(delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()

		if distance > attack_range:
			direction = direction.normalized()
			velocity = direction * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, direction)
		else:
			velocity = Vector2.ZERO
			update_animation(delta, ROW_ATTACK, direction)
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func start_attack() -> void:
	is_winding_up = true
	windup_timer = windup_duration

# Override in subclasses for ranged attacks, etc.
func _on_attack_complete() -> void:
	if player and is_instance_valid(player) and player.has_method("take_damage"):
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player <= attack_range * 1.0:  # Exact range check
			player.take_damage(attack_damage)
			if AbilityManager and AbilityManager.has_thorns:
				take_damage(AbilityManager.thorns_damage * AbilityManager.get_passive_damage_multiplier(), false)
	can_attack = false

func handle_hit_flash(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		var flash_intensity = flash_timer / flash_duration
		if sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", flash_intensity)
		if flash_timer <= 0 and sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", 0.0)

func handle_knockback(delta: float) -> bool:
	if knockback_velocity.length() > 1.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
		velocity = knockback_velocity
		move_and_slide()
		return true
	return false

func handle_stagger(delta: float) -> bool:
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0:
			is_staggered = false
		else:
			velocity = Vector2.ZERO
			update_animation(delta, ROW_DAMAGE, Vector2.ZERO)
			return true
	return false

func handle_attack_cooldown(delta: float) -> void:
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			can_attack = true

func handle_windup(delta: float) -> bool:
	if is_winding_up:
		windup_timer -= delta
		if windup_timer <= 0:
			is_winding_up = false
			_on_attack_complete()
		return true
	return false

func take_damage(amount: float, is_critical: bool = false) -> void:
	if is_dying:
		return

	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)

	if SoundManager:
		SoundManager.play_hit()

	spawn_damage_number(amount, is_critical)

	flash_timer = flash_duration
	if sprite.material:
		sprite.material.set_shader_parameter("flash_intensity", 1.0)

	if current_health > 0 and AbilityManager and AbilityManager.check_cull_weak(self):
		current_health = 0
		spawn_damage_number(999, true)
		is_critical = true

	if current_health <= 0:
		died_from_crit = is_critical
		die()

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force

func apply_stagger() -> void:
	# Bosses and elites cannot be staggered
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	is_staggered = true
	stagger_timer = STAGGER_DURATION
	is_winding_up = false
	windup_timer = 0.0

# ============================================
# STATUS EFFECTS FROM ACTIVE ABILITIES
# ============================================

func apply_stun(duration: float) -> void:
	"""Apply stun effect - enemy cannot move or attack. Bosses/elites are immune."""
	# Bosses and elites cannot be stunned
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	is_stunned = true
	stun_timer = max(stun_timer, duration)  # Don't reduce existing stun
	is_winding_up = false
	windup_timer = 0.0

func apply_slow(percent: float, duration: float) -> void:
	"""Apply slow effect - reduces movement speed."""
	is_slowed = true
	slow_percent = max(slow_percent, percent)  # Use strongest slow
	slow_timer = max(slow_timer, duration)
	_update_speed()

func apply_burn(duration: float) -> void:
	"""Apply burn effect - deals 5% max HP per tick."""
	is_burning = true
	burn_timer = max(burn_timer, duration)

func apply_poison(total_damage: float, duration: float) -> void:
	"""Apply poison effect - deals damage over time."""
	is_poisoned = true
	poison_timer = max(poison_timer, duration)
	poison_damage = total_damage / (duration / POISON_TICK_INTERVAL)  # Damage per tick

func handle_stun(delta: float) -> bool:
	"""Handle stun status - returns true if stunned and should skip behavior."""
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
		else:
			velocity = Vector2.ZERO
			update_animation(delta, ROW_DAMAGE, Vector2.ZERO)
			return true
	return false

func handle_status_effects(delta: float) -> void:
	"""Update all status effect timers."""
	# Handle slow timer
	if is_slowed:
		slow_timer -= delta
		if slow_timer <= 0:
			is_slowed = false
			slow_percent = 0.0
			_update_speed()

	# Handle burn damage
	if is_burning:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0:
			burn_tick_timer = BURN_TICK_INTERVAL
			var burn_damage = max_health * 0.05  # 5% max HP per tick
			_take_dot_damage(burn_damage, Color(1.0, 0.4, 0.2))
		if burn_timer <= 0:
			is_burning = false

	# Handle poison damage
	if is_poisoned:
		poison_timer -= delta
		poison_tick_timer -= delta
		if poison_tick_timer <= 0:
			poison_tick_timer = POISON_TICK_INTERVAL
			_take_dot_damage(poison_damage, Color(0.4, 1.0, 0.4))
		if poison_timer <= 0:
			is_poisoned = false
			poison_damage = 0.0

func _take_dot_damage(amount: float, color: Color) -> void:
	"""Take damage from DoT effects without triggering on-hit effects."""
	if is_dying:
		return

	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Spawn colored damage number (higher up to avoid overlapping normal damage)
	if damage_number_scene:
		var dmg_num = damage_number_scene.instantiate()
		dmg_num.global_position = global_position + Vector2(randf_range(-15, 15), -80)
		get_parent().add_child(dmg_num)
		if dmg_num.has_method("set_elemental"):
			dmg_num.set_elemental(str(int(amount)), color)
		else:
			dmg_num.set_damage(amount, false, false)

	if current_health <= 0:
		die()

func _update_speed() -> void:
	"""Update current speed based on slow effects."""
	if is_slowed:
		speed = base_speed * (1.0 - slow_percent)
	else:
		speed = base_speed

func get_current_speed() -> float:
	"""Get the current effective speed (affected by slows)."""
	return speed

func spawn_damage_number(amount: float, is_critical: bool = false) -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -30)
	get_parent().add_child(dmg_num)
	dmg_num.set_damage(amount, is_critical, false)

func die() -> void:
	is_dying = true
	current_row = ROW_DEATH
	animation_frame = 0.0
	velocity = Vector2.ZERO

	if SoundManager:
		SoundManager.play_enemy_death()

	flash_timer = 0.0
	if sprite.material:
		sprite.material.set_shader_parameter("flash_intensity", 0.0)

	spawn_death_particles()

	if player and is_instance_valid(player) and player.has_method("give_kill_xp"):
		player.give_kill_xp(max_health)

	if AbilityManager and player and is_instance_valid(player):
		AbilityManager.on_enemy_killed(self, player)

	# Register kill with KillStreakManager for combo tracking
	if KillStreakManager:
		KillStreakManager.register_kill()

	# Remove from group AFTER on_enemy_killed so abilities can find other enemies
	remove_from_group("enemies")

	var stats = get_node_or_null("/root/Main/StatsDisplay")
	if stats and stats.has_method("add_kill_points"):
		stats.add_kill_points()

func spawn_death_particles() -> void:
	if death_particles_scene == null:
		return

	var particles = death_particles_scene.instantiate()
	particles.global_position = global_position
	if particles.has_method("set_crit_kill"):
		particles.set_crit_kill(died_from_crit)

	# Flying head effect for ability kills
	if died_from_ability and particles.has_method("set_ability_kill") and sprite:
		var frame_width = sprite.texture.get_width() / COLS_PER_ROW
		var frame_height = sprite.texture.get_height() / 8  # Assume 8 rows
		particles.set_ability_kill(sprite.texture, sprite.frame, Vector2(frame_width, frame_height))

	get_parent().add_child(particles)

func mark_ability_kill() -> void:
	"""Mark this enemy as killed by an active ability for extra gore effects."""
	died_from_ability = true

func update_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 6)

	if animation_frame >= max_frames:
		spawn_gold_coin()
		queue_free()
	else:
		sprite.frame = ROW_DEATH * COLS_PER_ROW + int(animation_frame)

func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	var coin = gold_coin_scene.instantiate()
	coin.global_position = global_position
	get_parent().add_child(coin)

	# Try to drop a health potion
	try_drop_health_potion()

	# Try to drop an item
	try_drop_item()

func try_drop_health_potion() -> void:
	if health_potion_scene == null:
		return

	# Get game time from StatsDisplay
	var game_time: float = 0.0
	var stats = get_node_or_null("/root/Main/StatsDisplay")
	if stats and "time_survived" in stats:
		game_time = stats.time_survived

	# Use the static method from health_potion script to check drop
	var HealthPotion = load("res://scripts/health_potion.gd")
	var drop_result = HealthPotion.should_drop_potion(game_time)

	if not drop_result.drop:
		return

	# Spawn health potion with the appropriate tier
	var potion = health_potion_scene.instantiate()
	potion.global_position = global_position + Vector2(randf_range(-15, 15), randf_range(-15, 15))
	if potion.has_method("setup_tier"):
		potion.setup_tier(drop_result.tier)
	get_parent().add_child(potion)

func try_drop_item() -> void:
	if dropped_item_scene == null:
		return

	if EquipmentManager == null:
		return

	# Check if we should drop an item
	if not EquipmentManager.should_drop_item(enemy_rarity):
		return

	# Generate and spawn the item
	var item = EquipmentManager.generate_item(enemy_rarity)
	var dropped = dropped_item_scene.instantiate()
	dropped.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
	dropped.setup(item)
	get_parent().add_child(dropped)

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	sprite.frame = current_row * COLS_PER_ROW + int(animation_frame)
