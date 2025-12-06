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
@export var hit_sparks_scene: PackedScene

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

# Aggro system - allows minions to draw attention
var current_target: Node2D = null  # Can be player or minion
var aggro_target: Node2D = null  # Minion that drew aggro
var aggro_timer: float = 0.0
const AGGRO_DURATION: float = 3.0  # How long to chase a minion
const AGGRO_CHANCE: float = 0.5  # 50% chance to aggro on minion that attacks

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
var burn_custom_damage: float = -1.0  # -1 means use default 5% max HP
const BURN_TICK_INTERVAL: float = 0.5

# Poison system (damage over time)
var is_poisoned: bool = false
var poison_timer: float = 0.0
var poison_damage: float = 0.0
var poison_tick_timer: float = 0.0
const POISON_TICK_INTERVAL: float = 0.5

# Freeze system (complete immobilization - like stun but icy)
var is_frozen: bool = false
var frozen_timer: float = 0.0

# Bleed system (damage over time - stacks with burn/poison)
var is_bleeding: bool = false
var bleed_timer: float = 0.0
var bleed_damage: float = 0.0
var bleed_tick_timer: float = 0.0
const BLEED_TICK_INTERVAL: float = 0.5

# Shock system (brief damage amp or chain effect)
var is_shocked: bool = false
var shock_timer: float = 0.0
var shock_damage_amp: float = 1.25  # 25% more damage taken while shocked
const SHOCK_DURATION: float = 2.0

# Status effect visual colors (saturated for clear visibility)
const STATUS_COLOR_BURN: Color = Color(1.0, 0.35, 0.15)   # Deep orange-red
const STATUS_COLOR_POISON: Color = Color(0.3, 1.0, 0.3)   # Vibrant green
const STATUS_COLOR_SLOW: Color = Color(0.4, 0.65, 1.0)    # Icy blue
const STATUS_COLOR_STUN: Color = Color(1.0, 0.85, 0.2)    # Bright yellow
const STATUS_COLOR_FREEZE: Color = Color(0.7, 0.95, 1.0)  # Cyan/white ice
const STATUS_COLOR_BLEED: Color = Color(0.8, 0.15, 0.15)  # Dark red
const STATUS_COLOR_SHOCK: Color = Color(0.7, 0.5, 1.0)    # Electric purple
const STATUS_TINT_STRENGTH: float = 0.8  # Strong tint for clear visibility
var base_modulate: Color = Color.WHITE  # Store original/champion color

# Knockback
var knockback_velocity: Vector2 = Vector2.ZERO
var knockback_decay: float = 10.0

# Pathfinding / obstacle avoidance
var stuck_timer: float = 0.0
var last_position: Vector2 = Vector2.ZERO
var avoidance_direction: Vector2 = Vector2.ZERO
var is_avoiding: bool = false
var avoidance_timer: float = 0.0
const STUCK_THRESHOLD: float = 0.3  # Time before considered stuck
const AVOIDANCE_DURATION: float = 0.5  # Time to continue avoiding
const STUCK_DISTANCE: float = 5.0  # Minimum movement to not be stuck

# Hit flash
var flash_timer: float = 0.0
var flash_hold_duration: float = 0.033  # Hold full white for 2 frames at 60fps
var flash_fade_duration: float = 0.05  # Then fade out quickly
var flash_duration: float = 0.083  # Total duration (hold + fade)

# Squash/stretch on hit
var base_sprite_scale: Vector2 = Vector2.ONE
var hit_squash_tween: Tween = null

# Champion system (Nightmare+ difficulty)
var is_champion: bool = false
var champion_indicator: Label = null
var champion_fire_aura: AnimatedSprite2D = null

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
	player = get_tree().get_first_node_in_group("player")
	add_to_group("enemies")

	collision_layer = 4
	collision_mask = 9  # Layer 1 (player) + Layer 8 (obstacles)

	if sprite and sprite.material:
		sprite.material = sprite.material.duplicate()

	# Store original sprite scale for squash/stretch effects
	if sprite:
		base_sprite_scale = sprite.scale
		# Prevent texture bleeding between sprite sheet frames
		sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	# Let subclasses set their base stats first
	_on_ready()

	# THEN apply difficulty multipliers to those base stats
	_apply_difficulty_scaling()

	# Now set current health and speed from the scaled values
	current_health = max_health
	base_speed = speed  # Store base speed for slow calculations

	if health_bar:
		health_bar.set_health(current_health, max_health)
		# Hide health bar for regular mobs until they take damage
		# (champions will show health bar when make_champion() is called)
		if enemy_rarity == "normal":
			health_bar.visible = false

	# Capture sprite modulate for status effect blending
	# If subclass set a custom modulate in _on_ready(), preserve it
	# Otherwise ensure pure white (no errant tints)
	if sprite:
		# Check if subclass set a custom base_modulate
		if base_modulate == Color.WHITE:
			# No custom tint set - ensure sprite is pure white
			sprite.modulate = Color.WHITE
		else:
			# Subclass set a custom base_modulate - apply it to sprite
			sprite.modulate = base_modulate

func _apply_difficulty_scaling() -> void:
	"""Apply difficulty multipliers to enemy stats."""
	if DifficultyManager:
		max_health *= DifficultyManager.get_health_multiplier()
		attack_damage *= DifficultyManager.get_damage_multiplier()
		speed *= DifficultyManager.get_speed_multiplier()

# Override in subclasses for custom initialization
func _on_ready() -> void:
	pass

func _physics_process(delta: float) -> void:
	# Update z_index based on Y position for depth sorting with trees
	z_index = int(global_position.y / 10)

	# Always process hit flash, even when dying
	handle_hit_flash(delta)

	if is_dying:
		update_death_animation(delta)
		return
	handle_status_effects(delta)

	# Update aggro system
	_update_aggro(delta)

	# Apply status effect tint continuously (must run every frame)
	if is_burning or is_poisoned or is_slowed or is_stunned or is_frozen or is_bleeding or is_shocked:
		_update_status_modulate()

	if handle_knockback(delta):
		return

	if handle_stagger(delta):
		return

	if handle_stun(delta):
		return

	if handle_freeze(delta):
		return

	handle_attack_cooldown(delta)

	if handle_windup(delta):
		return

	_process_behavior(delta)

# Override in subclasses for custom AI behavior
func _process_behavior(delta: float) -> void:
	# Use current_target (can be player or aggro'd minion)
	var target = current_target if current_target and is_instance_valid(current_target) else player

	if target and is_instance_valid(target):
		var to_target = target.global_position - global_position
		var distance = to_target.length()

		if distance > attack_range:
			var direction = to_target.normalized()

			# Check if we're stuck (not moving despite trying)
			var movement_distance = global_position.distance_to(last_position)
			if movement_distance < STUCK_DISTANCE * delta * 60:  # Scale by expected movement
				stuck_timer += delta
			else:
				stuck_timer = 0.0
				is_avoiding = false

			# Update avoidance timer
			if is_avoiding:
				avoidance_timer -= delta
				if avoidance_timer <= 0:
					is_avoiding = false

			# If stuck, find an avoidance direction
			if stuck_timer > STUCK_THRESHOLD and not is_avoiding:
				is_avoiding = true
				avoidance_timer = AVOIDANCE_DURATION
				# Choose to go left or right around the obstacle
				avoidance_direction = _find_avoidance_direction(direction)

			# Apply movement with optional avoidance
			var move_direction: Vector2
			if is_avoiding:
				# Blend avoidance direction with target direction for smoother pathing
				move_direction = (avoidance_direction * 0.7 + direction * 0.3).normalized()
			else:
				move_direction = direction

			velocity = move_direction * speed
			move_and_slide()
			last_position = global_position
			update_animation(delta, ROW_MOVE, direction)  # Always face target
		else:
			velocity = Vector2.ZERO
			stuck_timer = 0.0
			is_avoiding = false
			update_animation(delta, ROW_ATTACK, to_target.normalized())
			if can_attack:
				start_attack()
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _find_avoidance_direction(desired_direction: Vector2) -> Vector2:
	"""Find a direction to avoid obstacles using raycasting."""
	var space_state = get_world_2d().direct_space_state

	# Test multiple angles to find a clear path
	var test_angles = [PI/4, -PI/4, PI/2, -PI/2, PI*3/4, -PI*3/4]
	var best_direction = desired_direction.rotated(PI/2)  # Default: perpendicular
	var best_score = -1.0

	for angle in test_angles:
		var test_dir = desired_direction.rotated(angle)
		var ray_params = PhysicsRayQueryParameters2D.create(
			global_position,
			global_position + test_dir * 100.0,
			collision_mask
		)
		ray_params.exclude = [self]

		var result = space_state.intersect_ray(ray_params)

		if result.is_empty():
			# No collision - this direction is clear
			# Prefer directions closer to the player direction
			var score = test_dir.dot(desired_direction)
			if score > best_score:
				best_score = score
				best_direction = test_dir
		else:
			# Collision found - check distance
			var hit_distance = global_position.distance_to(result.position)
			if hit_distance > 60.0:  # Far enough to still be useful
				var score = test_dir.dot(desired_direction) * (hit_distance / 100.0)
				if score > best_score:
					best_score = score
					best_direction = test_dir

	return best_direction

func start_attack() -> void:
	is_winding_up = true
	windup_timer = windup_duration

# Override in subclasses for ranged attacks, etc.
func _on_attack_complete() -> void:
	# Determine attack target (minion or player)
	var target = current_target if current_target and is_instance_valid(current_target) else player

	# Attack minion if that's our target
	if target and target != player and target.has_method("take_damage"):
		var dist_to_target = global_position.distance_to(target.global_position)
		if dist_to_target <= attack_range * 1.0:
			target.take_damage(attack_damage)
			can_attack = false
			return

	# Attack player
	if player and is_instance_valid(player) and player.has_method("take_damage"):
		var dist_to_player = global_position.distance_to(player.global_position)
		if dist_to_player <= attack_range * 1.0:  # Exact range check
			player.take_damage(attack_damage)
			# Difficulty modifier: Chilling Touch - enemies slow player on hit
			if DifficultyManager and DifficultyManager.has_enemy_slow_on_hit():
				if player.has_method("apply_difficulty_slow"):
					player.apply_difficulty_slow(0.15, 1.5)  # 15% slow for 1.5s
			if AbilityManager and AbilityManager.has_thorns:
				take_damage(AbilityManager.thorns_damage * AbilityManager.get_passive_damage_multiplier(), false)
	can_attack = false

func handle_hit_flash(delta: float) -> void:
	if flash_timer > 0:
		flash_timer -= delta
		var intensity: float
		if flash_timer > flash_fade_duration:
			# Hold phase - full white
			intensity = 1.0
		elif flash_timer > 0:
			# Fade phase - ease out for snappier feel
			var fade_progress = flash_timer / flash_fade_duration
			intensity = fade_progress * fade_progress  # Quadratic ease-out
		else:
			intensity = 0.0
		if sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", intensity)
		if flash_timer <= 0 and sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", 0.0)

func _apply_hit_squash() -> void:
	# Check if visual effects are enabled
	if GameSettings and not GameSettings.visual_effects_enabled:
		return
	if not sprite:
		return

	# Kill any existing squash tween
	if hit_squash_tween and hit_squash_tween.is_valid():
		hit_squash_tween.kill()

	# Instant squash: wider (1.15x) and shorter (0.85x)
	sprite.scale = base_sprite_scale * Vector2(1.15, 0.85)

	# Bounce back with elastic ease
	hit_squash_tween = create_tween()
	hit_squash_tween.tween_property(sprite, "scale", base_sprite_scale, 0.15) \
		.set_trans(Tween.TRANS_ELASTIC) \
		.set_ease(Tween.EASE_OUT)

func _spawn_hit_sparks() -> void:
	if hit_sparks_scene == null:
		return

	var sparks = hit_sparks_scene.instantiate()
	sparks.global_position = global_position
	get_parent().add_child(sparks)

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

# ============================================
# AGGRO SYSTEM - Minions can draw enemy attention
# ============================================

func _update_aggro(delta: float) -> void:
	"""Update aggro timer and current target."""
	if aggro_timer > 0:
		aggro_timer -= delta
		if aggro_timer <= 0:
			# Aggro expired, go back to player
			aggro_target = null
			current_target = player

	# Validate current target
	if current_target and not is_instance_valid(current_target):
		current_target = player
		aggro_target = null
		aggro_timer = 0.0

func draw_aggro(minion: Node2D, custom_chance: float = -1.0) -> void:
	"""Called when a minion attacks this enemy. May cause enemy to target the minion."""
	if is_dying:
		return

	# Use custom chance if provided, otherwise use default
	var chance = custom_chance if custom_chance >= 0.0 else AGGRO_CHANCE

	# Only have a chance to aggro
	if randf() > chance:
		return

	# Set the minion as our target
	aggro_target = minion
	current_target = minion
	aggro_timer = AGGRO_DURATION

func take_damage(amount: float, is_critical: bool = false) -> void:
	if is_dying:
		return

	# Apply shock damage amplification
	if is_shocked:
		amount *= shock_damage_amp

	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)
		# Show health bar for regular mobs when they take damage
		if enemy_rarity == "normal" and current_health < max_health:
			health_bar.visible = true

	if SoundManager:
		SoundManager.play_hit()

	spawn_damage_number(amount, is_critical)

	# Hit flash effect (only if visual effects enabled)
	if not GameSettings or GameSettings.visual_effects_enabled:
		flash_timer = flash_duration
		if sprite.material:
			sprite.material.set_shader_parameter("flash_intensity", 1.0)

	# Squash effect on hit
	_apply_hit_squash()

	# Hit spark particles
	_spawn_hit_sparks()

	# Chromatic aberration pulse on hit
	if JuiceManager:
		if is_critical:
			JuiceManager.chromatic_pulse(0.3)
			JuiceManager.zoom_punch_medium()  # Zoom punch on crits
		else:
			JuiceManager.chromatic_pulse(0.15)

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
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_stunned = is_stunned
	is_stunned = true
	stun_timer = max(stun_timer, duration)  # Don't reduce existing stun
	is_winding_up = false
	windup_timer = 0.0
	if not was_stunned:
		_update_status_modulate()
		_spawn_status_text("STUN", Color(1.0, 0.9, 0.4))

func apply_slow(percent: float, duration: float) -> void:
	"""Apply slow effect - reduces movement speed. Bosses/elites are immune."""
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_slowed = is_slowed
	is_slowed = true
	slow_percent = max(slow_percent, percent)  # Use strongest slow
	slow_timer = max(slow_timer, duration)
	_update_speed()
	if not was_slowed:
		_update_status_modulate()
		_spawn_status_text("SLOW", Color(0.4, 0.7, 1.0))

func apply_burn(duration: float, custom_damage_per_tick: float = -1.0) -> void:
	"""Apply burn effect - deals damage per tick (default: 5% max HP). Bosses/elites are immune."""
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_burning = is_burning
	is_burning = true
	burn_timer = max(burn_timer, duration)
	if custom_damage_per_tick > 0:
		burn_custom_damage = custom_damage_per_tick
	if not was_burning:
		_update_status_modulate()
		_spawn_status_text("BURN", Color(1.0, 0.4, 0.2))

func apply_poison(total_damage: float, duration: float) -> void:
	"""Apply poison effect - deals damage over time. Bosses/elites are immune."""
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_poisoned = is_poisoned
	is_poisoned = true
	poison_timer = max(poison_timer, duration)
	poison_damage = total_damage / (duration / POISON_TICK_INTERVAL)  # Damage per tick
	if not was_poisoned:
		_update_status_modulate()
		_spawn_status_text("POISON", Color(0.4, 1.0, 0.4))

func apply_freeze(duration: float) -> void:
	"""Apply freeze effect - complete immobilization (icy stun). Bosses/elites are immune."""
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_frozen = is_frozen
	is_frozen = true
	frozen_timer = max(frozen_timer, duration)
	is_winding_up = false
	windup_timer = 0.0
	if not was_frozen:
		_update_status_modulate()
		_spawn_status_text("FREEZE", Color(0.7, 0.95, 1.0))

func apply_bleed(total_damage: float, duration: float) -> void:
	"""Apply bleed effect - deals damage over time. Bosses/elites are immune."""
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_bleeding = is_bleeding
	is_bleeding = true
	bleed_timer = max(bleed_timer, duration)
	bleed_damage = total_damage / (duration / BLEED_TICK_INTERVAL)  # Damage per tick
	if not was_bleeding:
		_update_status_modulate()
		_spawn_status_text("BLEED", Color(0.8, 0.15, 0.15))

func apply_shock(damage: float = 0.0) -> void:
	"""Apply shock effect - increases damage taken. Bosses/elites are immune."""
	if enemy_rarity == "boss" or enemy_rarity == "elite":
		return
	var was_shocked = is_shocked
	is_shocked = true
	shock_timer = SHOCK_DURATION
	# If damage provided, deal it immediately
	if damage > 0:
		take_damage(damage, false)
	if not was_shocked:
		_update_status_modulate()
		_spawn_status_text("SHOCK", Color(0.7, 0.5, 1.0))

func handle_stun(delta: float) -> bool:
	"""Handle stun status - returns true if stunned and should skip behavior."""
	if is_stunned:
		stun_timer -= delta
		if stun_timer <= 0:
			is_stunned = false
			_update_status_modulate()
		else:
			velocity = Vector2.ZERO
			update_animation(delta, ROW_DAMAGE, Vector2.ZERO)
			return true
	return false

func handle_freeze(delta: float) -> bool:
	"""Handle freeze status - returns true if frozen and should skip behavior."""
	if is_frozen:
		frozen_timer -= delta
		if frozen_timer <= 0:
			is_frozen = false
			_update_status_modulate()
		else:
			velocity = Vector2.ZERO
			# Frozen enemies don't animate - they're frozen solid
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
			_update_status_modulate()

	# Handle burn damage
	if is_burning:
		burn_timer -= delta
		burn_tick_timer -= delta
		if burn_tick_timer <= 0:
			burn_tick_timer = BURN_TICK_INTERVAL
			var burn_damage_value: float
			if burn_custom_damage > 0:
				burn_damage_value = burn_custom_damage
			else:
				burn_damage_value = max_health * 0.05  # Default: 5% max HP per tick
			_take_dot_damage(burn_damage_value, Color(1.0, 0.4, 0.2))
		if burn_timer <= 0:
			is_burning = false
			burn_custom_damage = -1.0  # Reset custom damage
			_update_status_modulate()

	# Handle poison damage
	if is_poisoned:
		poison_timer -= delta
		poison_tick_timer -= delta
		if poison_tick_timer <= 0:
			poison_tick_timer = POISON_TICK_INTERVAL
			_take_dot_damage(poison_damage, Color(0.4, 1.0, 0.4))
		if poison_timer <= 0:
			is_poisoned = false
			_update_status_modulate()
			poison_damage = 0.0

	# Handle bleed damage
	if is_bleeding:
		bleed_timer -= delta
		bleed_tick_timer -= delta
		if bleed_tick_timer <= 0:
			bleed_tick_timer = BLEED_TICK_INTERVAL
			_take_dot_damage(bleed_damage, Color(0.8, 0.15, 0.15))
		if bleed_timer <= 0:
			is_bleeding = false
			_update_status_modulate()
			bleed_damage = 0.0

	# Handle shock timer (damage amp wears off)
	if is_shocked:
		shock_timer -= delta
		if shock_timer <= 0:
			is_shocked = false
			_update_status_modulate()

func _take_dot_damage(amount: float, color: Color) -> void:
	"""Take damage from DoT effects without triggering on-hit effects."""
	if is_dying:
		return

	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)
		# Show health bar for regular mobs when they take damage
		if enemy_rarity == "normal" and current_health < max_health:
			health_bar.visible = true

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

func _update_status_modulate() -> void:
	"""Update sprite color based on active status effects. Performance-friendly."""
	if not sprite:
		return

	# Check if visual effects are disabled - restore base color
	if GameSettings and not GameSettings.visual_effects_enabled:
		sprite.modulate = base_modulate
		return

	# Use max per channel for vibrant color stacking (no muddy averaging)
	var has_status: bool = false
	var blended_color: Color = Color(0, 0, 0, 1.0)

	if is_burning:
		blended_color.r = max(blended_color.r, STATUS_COLOR_BURN.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_BURN.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_BURN.b)
		has_status = true
	if is_poisoned:
		blended_color.r = max(blended_color.r, STATUS_COLOR_POISON.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_POISON.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_POISON.b)
		has_status = true
	if is_slowed:
		blended_color.r = max(blended_color.r, STATUS_COLOR_SLOW.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_SLOW.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_SLOW.b)
		has_status = true
	if is_stunned:
		blended_color.r = max(blended_color.r, STATUS_COLOR_STUN.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_STUN.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_STUN.b)
		has_status = true
	if is_frozen:
		blended_color.r = max(blended_color.r, STATUS_COLOR_FREEZE.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_FREEZE.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_FREEZE.b)
		has_status = true
	if is_bleeding:
		blended_color.r = max(blended_color.r, STATUS_COLOR_BLEED.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_BLEED.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_BLEED.b)
		has_status = true
	if is_shocked:
		blended_color.r = max(blended_color.r, STATUS_COLOR_SHOCK.r)
		blended_color.g = max(blended_color.g, STATUS_COLOR_SHOCK.g)
		blended_color.b = max(blended_color.b, STATUS_COLOR_SHOCK.b)
		has_status = true

	# Apply blended status color or restore base
	if has_status:
		sprite.modulate = base_modulate.lerp(blended_color, STATUS_TINT_STRENGTH)
	else:
		sprite.modulate = base_modulate

func get_current_speed() -> float:
	"""Get the current effective speed (affected by slows)."""
	return speed

func spawn_damage_number(amount: float, is_critical: bool = false) -> void:
	# Check if damage numbers are enabled in settings
	if GameSettings and not GameSettings.damage_numbers_enabled:
		return
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -30)
	get_parent().add_child(dmg_num)
	dmg_num.set_damage(amount, is_critical, false)

func _spawn_status_text(text: String, color: Color) -> void:
	"""Spawn colored status text above this enemy."""
	# Check if status text is enabled in settings
	if GameSettings and not GameSettings.status_text_enabled:
		return
	if damage_number_scene == null:
		return
	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -50)
	get_parent().add_child(dmg_num)
	if dmg_num.has_method("set_status"):
		dmg_num.set_status(text, color)
	elif dmg_num.has_method("set_elemental"):
		dmg_num.set_elemental(text, color)

func die() -> void:
	is_dying = true
	current_row = ROW_DEATH
	animation_frame = 0.0
	velocity = Vector2.ZERO

	if SoundManager:
		SoundManager.play_enemy_death()

	# Zoom punch on crit kills for visual impact (no freeze frame)
	if died_from_crit and JuiceManager:
		JuiceManager.zoom_punch_large()

	# Don't reset flash - let it fade naturally for satisfying hit feedback
	spawn_death_particles()

	if player and is_instance_valid(player) and player.has_method("give_kill_xp"):
		player.give_kill_xp(max_health)

	if AbilityManager and player and is_instance_valid(player):
		AbilityManager.on_enemy_killed(self, player)

	# Register kill with KillStreakManager for combo tracking
	if KillStreakManager:
		KillStreakManager.register_kill()

	# Track kill for missions
	if MissionsManager:
		MissionsManager.track_kill(enemy_type)

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
	if died_from_ability and particles.has_method("set_ability_kill") and sprite and sprite.texture:
		# Calculate frame size based on sprite properties
		var frame_width: float
		var frame_height: float
		if sprite.hframes > 1 or sprite.vframes > 1:
			# Sprite has hframes/vframes set
			frame_width = sprite.texture.get_width() / float(sprite.hframes)
			frame_height = sprite.texture.get_height() / float(sprite.vframes)
		else:
			# Fallback to COLS_PER_ROW and row count
			frame_width = sprite.texture.get_width() / float(COLS_PER_ROW)
			var num_rows = FRAME_COUNTS.size()
			frame_height = sprite.texture.get_height() / float(num_rows)
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
	elif sprite:
		sprite.frame = ROW_DEATH * COLS_PER_ROW + int(animation_frame)

func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	# Apply Cursed Gold curse (reduced gold drops)
	if CurseEffects:
		var drop_chance = CurseEffects.get_gold_drop_multiplier()
		if randf() > drop_chance:
			return  # No coin dropped

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

	# Check for player's health drop multiplier (Ratfolk Scavenger passive)
	var drop_multiplier: float = 1.0
	if CharacterManager:
		var bonuses = CharacterManager.get_passive_bonuses()
		if bonuses.get("has_scavenger", 0) > 0:
			drop_multiplier = bonuses.get("health_drop_multiplier", 1.0)

	# Use the static method from health_potion script to check drop
	var HealthPotion = load("res://scripts/health_potion.gd")
	var drop_result = HealthPotion.should_drop_potion(game_time, drop_multiplier)

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
	get_parent().add_child(dropped)  # Must add to tree BEFORE setup() so @onready vars are initialized
	dropped.setup(item)

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if not sprite:
		return

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

# ============================================
# CHAMPION SYSTEM (Nightmare+ Difficulty)
# ============================================

func make_champion() -> void:
	"""Transform this enemy into a champion with 9x HP, 2x damage, 1.25x speed, and visual indicator."""
	is_champion = true

	# Apply champion buffs
	max_health *= 9.0
	current_health = max_health
	attack_damage *= 2.0
	speed *= 1.25

	# Visual changes - 25% larger
	scale *= 1.25

	# Update base_sprite_scale for squash effect
	if sprite:
		base_sprite_scale = sprite.scale

	# Update health bar and make it visible for champions
	if health_bar:
		health_bar.set_health(current_health, max_health)
		health_bar.visible = true

	# Create champion indicator
	_create_champion_indicator()

	# Apply golden/orange tint to indicate champion status
	# Store as base_modulate so status effects blend correctly
	if sprite:
		base_modulate = Color(1.0, 0.85, 0.5)  # Golden tint
		sprite.modulate = base_modulate

func _create_champion_indicator() -> void:
	"""Create a visual indicator showing CHAMPION above the health bar and fire aura below feet."""
	# Small CHAMPION label just above health bar
	champion_indicator = Label.new()
	champion_indicator.text = "CHAMPION"
	champion_indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	champion_indicator.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	champion_indicator.custom_minimum_size = Vector2(60, 10)
	champion_indicator.position = Vector2(-30, -40)  # Centered above health bar

	# Load and apply pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
		champion_indicator.add_theme_font_override("font", pixel_font)

	champion_indicator.add_theme_font_size_override("font_size", 8)
	champion_indicator.add_theme_color_override("font_color", Color(1.0, 0.8, 0.2))  # Gold
	champion_indicator.add_theme_color_override("font_shadow_color", Color(0.3, 0.1, 0.0, 0.8))
	champion_indicator.add_theme_constant_override("shadow_offset_x", 1)
	champion_indicator.add_theme_constant_override("shadow_offset_y", 1)
	add_child(champion_indicator)

	# Fire aura effect below feet
	_create_champion_fire_aura()

func _create_champion_fire_aura() -> void:
	"""Create animated fire aura effect below the champion's feet."""
	champion_fire_aura = AnimatedSprite2D.new()
	champion_fire_aura.position = Vector2(0, 20)  # At bottom of feet (same as target indicator)
	champion_fire_aura.z_index = -1  # Render behind the enemy
	champion_fire_aura.scale = Vector2(0.4, 0.4)  # Smaller to fit under enemy

	# Create sprite frames from the fire aura images
	var frames = SpriteFrames.new()
	frames.add_animation("fire")
	frames.set_animation_loop("fire", true)
	frames.set_animation_speed("fire", 24.0)  # 24 FPS for smooth fire

	# Load all 68 frames (1_0.png to 1_67.png)
	for i in range(68):
		var path = "res://assets/sprites/effects/Fire Aura/6/1_%d.png" % i
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				frames.add_frame("fire", texture)

	champion_fire_aura.sprite_frames = frames
	champion_fire_aura.play("fire")
	add_child(champion_fire_aura)
