extends CharacterBody2D

@export var speed: float = 90.0  # 1.5 pixels/frame * 60fps
@export var attack_range: float = 50.0
@export var animation_speed: float = 10.0
@export var max_health: float = 20.0
@export var attack_damage: float = 5.0
@export var attack_cooldown: float = 0.8  # Time between attacks
@export var gold_coin_scene: PackedScene
@export var damage_number_scene: PackedScene
@export var death_particles_scene: PackedScene

var player: Node2D = null
var current_health: float
var is_dying: bool = false
var died_from_crit: bool = false  # Track if killing blow was a crit
var attack_timer: float = 0.0
var can_attack: bool = true

# Attack wind-up system
var is_winding_up: bool = false
var windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.25  # 0.25 second wind-up before damage

# Stagger system (from melee hits)
var is_staggered: bool = false
var stagger_timer: float = 0.0
const STAGGER_DURATION: float = 0.35  # 0.35 second stagger

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0

# Hit flash
var flash_timer: float = 0.0
var flash_duration: float = 0.1

# Animation rows (0-indexed)
const ROW_IDLE = 0       # 4 frames
const ROW_SLEEP = 1      # 8 frames
const ROW_MOVE = 2       # 8 frames
const ROW_CARRY = 3      # 8 frames
const ROW_CARRY2 = 4     # 8 frames
const ROW_ATTACK = 5     # 8 frames
const ROW_DAMAGE = 6     # 3 frames
const ROW_DEATH = 7      # 6 frames

const COLS_PER_ROW = 8

const FRAME_COUNTS = {
	ROW_IDLE: 4,
	ROW_SLEEP: 8,
	ROW_MOVE: 8,
	ROW_CARRY: 8,
	ROW_CARRY2: 8,
	ROW_ATTACK: 8,
	ROW_DAMAGE: 3,
	ROW_DEATH: 6,
}

var current_row: int = ROW_IDLE
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite
@onready var health_bar: Node2D = $HealthBar

func _ready() -> void:
	current_health = max_health
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	# Set collision layer for enemy (layer 3)
	collision_layer = 4
	collision_mask = 1

	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Duplicate shader material so hit flash only affects this enemy
	if sprite and sprite.material:
		sprite.material = sprite.material.duplicate()

func _physics_process(delta: float) -> void:
	if is_dying:
		update_death_animation(delta)
		return

	# Handle hit flash
	if flash_timer > 0:
		flash_timer -= delta
		var flash_intensity = flash_timer / flash_duration
		if sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", flash_intensity)
		if flash_timer <= 0 and sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", 0.0)

	# Handle knockback decay
	if knockback_velocity.length() > 1.0:
		knockback_velocity = knockback_velocity.lerp(Vector2.ZERO, knockback_decay * delta)
		velocity = knockback_velocity
		move_and_slide()
		return

	# Handle stagger (from melee hits)
	if is_staggered:
		stagger_timer -= delta
		if stagger_timer <= 0:
			is_staggered = false
		else:
			velocity = Vector2.ZERO
			# Stay on damage animation during stagger
			update_animation(delta, ROW_DAMAGE, Vector2.ZERO)
			return

	# Handle attack cooldown
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			attack_timer = 0.0
			can_attack = true

	# Handle attack wind-up
	if is_winding_up:
		windup_timer -= delta
		if windup_timer <= 0:
			is_winding_up = false
			# Now actually deal damage after wind-up completes - but only if still in range
			if player and is_instance_valid(player) and player.has_method("take_damage"):
				var dist_to_player = global_position.distance_to(player.global_position)
				# Only deal damage if player is still within attack range (with generous buffer)
				if dist_to_player <= attack_range * 1.5:
					player.take_damage(attack_damage)
					# Thorns damage
					if AbilityManager and AbilityManager.has_thorns:
						take_damage(AbilityManager.thorns_damage, false)
				can_attack = false
		return

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
			# Start attack wind-up (damage dealt after wind-up completes)
			if can_attack:
				is_winding_up = true
				windup_timer = WINDUP_DURATION
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func take_damage(amount: float, is_critical: bool = false) -> void:
	if is_dying:
		return

	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Play hit sound
	if SoundManager:
		SoundManager.play_hit()

	# Spawn damage number
	spawn_damage_number(amount, is_critical)

	# Hit flash effect
	flash_timer = flash_duration
	if sprite.material:
		sprite.material.set_shader_parameter("flash_intensity", 1.0)

	# Micro hitstop for impact feel (1 frame)
	# if JuiceManager:
	# 	JuiceManager.hitstop_micro()

	# Check for cull the weak
	if current_health > 0 and AbilityManager and AbilityManager.check_cull_weak(self):
		current_health = 0
		spawn_damage_number(999, true)  # Show execute damage
		is_critical = true  # Cull the weak counts as crit for gore

	if current_health <= 0:
		died_from_crit = is_critical
		die()

func apply_knockback(force: Vector2) -> void:
	knockback_velocity = force

func apply_stagger() -> void:
	is_staggered = true
	stagger_timer = STAGGER_DURATION
	# Cancel any attack wind-up when staggered
	is_winding_up = false
	windup_timer = 0.0

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

	# Play death sound
	if SoundManager:
		SoundManager.play_enemy_death()

	# Clear hit flash immediately on death
	flash_timer = 0.0
	if sprite.material:
		sprite.material.set_shader_parameter("flash_intensity", 0.0)

	# Remove from enemies group so player stops targeting
	remove_from_group("enemies")

	# Spawn death particles
	spawn_death_particles()

	# Give player kill XP
	if player and is_instance_valid(player) and player.has_method("give_kill_xp"):
		player.give_kill_xp()

	# Notify AbilityManager for on-kill effects
	if AbilityManager and player and is_instance_valid(player):
		AbilityManager.on_enemy_killed(self, player)

	# Update stats display
	var stats = get_node_or_null("/root/Main/StatsDisplay")
	if stats and stats.has_method("add_kill_points"):
		stats.add_kill_points()

func spawn_death_particles() -> void:
	if death_particles_scene == null:
		return

	var particles = death_particles_scene.instantiate()
	particles.global_position = global_position
	# Pass crit info to particles for extra gore
	if particles.has_method("set_crit_kill"):
		particles.set_crit_kill(died_from_crit)
	get_parent().add_child(particles)

func update_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 6)

	if animation_frame >= max_frames:
		# Death animation finished - spawn coin and remove
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
