extends CharacterBody2D

@export var speed: float = 180.0  # 3 pixels/frame * 60fps
@export var animation_speed: float = 10.0
@export var attack_cooldown: float = 0.79  # ~1.27 attacks per second (25% slower)
@export var fire_range: float = 440.0  # 55 frames * 8 pixels/frame
@export var arrow_scene: PackedScene
@export var max_health: float = 25.0
@export var damage_number_scene: PackedScene
@export var muzzle_flash_scene: PackedScene
@export var swipe_effect_scene: PackedScene

# Camera
@onready var camera: Camera2D = $Camera2D
var camera_lerp_speed: float = 8.0

# Recoil
var recoil_offset: Vector2 = Vector2.ZERO
var recoil_recovery: float = 15.0

# Base stats (for ability modifications)
var base_speed: float
var base_attack_cooldown: float
var base_max_health: float
var base_damage: float = 1.0

var current_health: float
@onready var health_bar: Node2D = $HealthBar

# Ability-related stats
var pickup_range_multiplier: float = 1.0
var size_scale: float = 1.0

# Temporary buffs
var temp_speed_boost: float = 0.0
var temp_speed_timer: float = 0.0

# Heal accumulator (for small heals that would round to 0)
var accumulated_heal: float = 0.0

var touch_start_pos: Vector2 = Vector2.ZERO
var touch_current_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false

# Character data
var character_data: CharacterData = null
var is_melee: bool = false

# Animation rows - dynamically set based on character
var row_idle: int = 0
var row_move: int = 1
var row_attack: int = 2
var row_attack_up: int = 3
var row_attack_down: int = 4
var row_damage: int = 5
var row_death: int = 6

var cols_per_row: int = 8

var frame_counts: Dictionary = {}

var current_row: int = 0
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite

# Combat
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var facing_right: bool = true

# Melee attack hitbox
var melee_hitbox_active: bool = false
var melee_hit_enemies: Array = []  # Track enemies hit this attack

# Death state
var is_dead: bool = false
var death_animation_finished: bool = false

# XP System
var current_xp: float = 0.0
var xp_to_next_level: float = 15.0
var current_level: int = 1

signal xp_changed(current_xp: float, xp_needed: float, level: int)
signal level_up(new_level: int)
signal health_changed(current_health: float, max_health: float)
signal player_died()

func _ready() -> void:
	# Load character data from CharacterManager
	_load_character_data()

	# Store base stats for ability calculations
	base_speed = speed
	base_attack_cooldown = attack_cooldown
	base_max_health = max_health
	base_damage = character_data.base_damage if character_data else 1.0

	# Apply permanent upgrades to base stats
	_apply_permanent_upgrades()

	# Apply character passive bonuses
	_apply_character_passive()

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Register camera with JuiceManager for screen shake
	if camera and JuiceManager:
		JuiceManager.register_camera(camera)
		# Disable camera position smoothing since we do it manually
		camera.position_smoothing_enabled = false

func _load_character_data() -> void:
	if not CharacterManager:
		# Fallback to archer defaults
		_setup_archer_defaults()
		return

	character_data = CharacterManager.get_selected_character()
	if character_data == null:
		_setup_archer_defaults()
		return

	# Apply character stats
	speed = character_data.base_speed
	attack_cooldown = character_data.base_attack_cooldown
	max_health = character_data.base_health
	fire_range = character_data.attack_range
	is_melee = character_data.attack_type == CharacterData.AttackType.MELEE

	# Setup sprite
	if sprite and character_data.sprite_texture:
		sprite.texture = character_data.sprite_texture
		sprite.hframes = character_data.hframes
		sprite.vframes = character_data.vframes
		sprite.scale = character_data.sprite_scale

	# Setup animation rows
	row_idle = character_data.row_idle
	row_move = character_data.row_move
	row_attack = character_data.row_attack
	row_attack_up = character_data.row_attack_up
	row_attack_down = character_data.row_attack_down
	row_damage = character_data.row_damage
	row_death = character_data.row_death
	cols_per_row = character_data.hframes

	# Setup frame counts
	frame_counts = {
		row_idle: character_data.frames_idle,
		row_move: character_data.frames_move,
		row_attack: character_data.frames_attack,
		row_attack_up: character_data.frames_attack_up,
		row_attack_down: character_data.frames_attack_down,
		row_damage: character_data.frames_damage,
		row_death: character_data.frames_death,
	}

	current_row = row_idle

func _setup_archer_defaults() -> void:
	# Fallback archer configuration
	is_melee = false
	row_idle = 0
	row_move = 1
	row_attack = 2
	row_attack_up = 3
	row_attack_down = 4
	row_damage = 5
	row_death = 6
	cols_per_row = 8

	frame_counts = {
		row_idle: 4,
		row_move: 8,
		row_attack: 8,
		row_attack_up: 8,
		row_attack_down: 8,
		row_damage: 4,
		row_death: 4,
	}

	current_row = row_idle

func _apply_character_passive() -> void:
	if not CharacterManager:
		return

	var bonuses = CharacterManager.get_passive_bonuses()

	# Apply max HP bonus from passive
	var hp_bonus = bonuses.get("max_hp", 0.0)
	if hp_bonus > 0:
		base_max_health = base_max_health * (1.0 + hp_bonus)
		max_health = base_max_health

func _apply_permanent_upgrades() -> void:
	if not PermanentUpgrades:
		return

	var bonuses = PermanentUpgrades.get_all_bonuses()

	# Apply max HP bonus
	var hp_bonus = bonuses.get("max_hp", 0.0)
	base_max_health = base_max_health * (1.0 + hp_bonus)
	max_health = base_max_health

	# Apply movement speed bonus
	var speed_bonus = bonuses.get("move_speed", 0.0)
	base_speed = base_speed * (1.0 + speed_bonus)
	speed = base_speed

	# Apply attack speed bonus
	var attack_speed_bonus = bonuses.get("attack_speed", 0.0)
	base_attack_cooldown = base_attack_cooldown / (1.0 + attack_speed_bonus)
	attack_cooldown = base_attack_cooldown

	# Apply pickup range bonus
	var pickup_bonus = bonuses.get("pickup_range", 0.0)
	pickup_range_multiplier = 1.0 + pickup_bonus

func take_damage(amount: float) -> void:
	# Check for dodge first
	if AbilityManager:
		var dodge_chance = AbilityManager.get_dodge_chance()
		if randf() < dodge_chance:
			# Dodged the attack!
			spawn_dodge_text()
			return

	# Check for block
	var was_blocked = false
	if AbilityManager:
		var block_chance = AbilityManager.get_block_chance()
		if randf() < block_chance:
			was_blocked = true

	# Apply character passive damage reduction (Knight's Iron Will)
	var final_damage = amount
	if CharacterManager:
		var bonuses = CharacterManager.get_passive_bonuses()
		var reduction = bonuses.get("damage_reduction", 0.0)
		var threshold = bonuses.get("damage_reduction_threshold", 0.0)
		if reduction > 0 and threshold > 0:
			var health_percent = current_health / max_health
			if health_percent < threshold:
				final_damage = amount * (1.0 - reduction)

	# Block reduces damage by 50%
	if was_blocked:
		final_damage *= 0.5

	current_health -= final_damage
	if health_bar:
		health_bar.set_health(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	# Play player hurt sound
	if SoundManager:
		SoundManager.play_player_hurt()

	# Spawn damage number (red for player, show blocked if applicable)
	if was_blocked:
		spawn_blocked_damage_number(final_damage)
	else:
		spawn_damage_number(final_damage)

	# Screen shake and damage flash when taking damage
	if JuiceManager:
		if was_blocked:
			JuiceManager.shake_small()  # Less shake when blocked
		else:
			JuiceManager.shake_medium()
		JuiceManager.damage_flash()
		JuiceManager.update_player_health(current_health / max_health)

	if current_health <= 0 and not is_dead:
		current_health = 0
		is_dead = true
		death_animation_finished = false
		animation_frame = 0.0
		current_row = row_death
		emit_signal("player_died")
		if JuiceManager:
			JuiceManager.shake_large()

func spawn_damage_number(amount: float) -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	dmg_num.set_damage(amount, false, true)  # is_player_damage = true

func spawn_blocked_damage_number(amount: float) -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	if dmg_num.has_method("set_blocked"):
		dmg_num.set_blocked(amount)
	else:
		dmg_num.set_damage(amount, false, true)

func spawn_dodge_text() -> void:
	if damage_number_scene == null:
		return

	var dmg_num = damage_number_scene.instantiate()
	dmg_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(dmg_num)
	if dmg_num.has_method("set_dodge"):
		dmg_num.set_dodge()
	else:
		# Fallback - just show 0 damage
		dmg_num.set_damage(0, false, true)

func _input(event: InputEvent) -> void:
	# Ignore input when dead
	if is_dead:
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			is_touching = true
			touch_start_pos = event.position
			touch_current_pos = event.position
		else:
			is_touching = false
			velocity = Vector2.ZERO
	elif event is InputEventScreenDrag:
		touch_current_pos = event.position

func _physics_process(delta: float) -> void:
	# If dead, only update death animation
	if is_dead:
		update_death_animation(delta)
		return

	# Update temporary buffs
	if temp_speed_timer > 0:
		temp_speed_timer -= delta
		if temp_speed_timer <= 0:
			temp_speed_boost = 0.0

	var direction := Vector2.ZERO

	# Touch/drag input for mobile
	if is_touching:
		var touch_delta = touch_current_pos - touch_start_pos
		if touch_delta.length() > 20.0:
			direction = touch_delta.normalized()

	# Keyboard input for testing (Arrow keys + WASD)
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1

	if direction.length() > 0:
		direction = direction.normalized()

	# Apply speed with ability modifiers and temp boosts
	var effective_speed = speed * (1.0 + temp_speed_boost)
	velocity = direction * effective_speed
	move_and_slide()

	# Keep player within arena bounds (1536x1536)
	const ARENA_SIZE = 1536
	const MARGIN = 40
	position.x = clamp(position.x, MARGIN, ARENA_SIZE - MARGIN)
	position.y = clamp(position.y, MARGIN, ARENA_SIZE - MARGIN)

	# Auto-attack
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		try_attack()

	# Apply recoil to actual position
	if recoil_offset.length() > 0.1:
		position += recoil_offset * delta * 60  # Apply as movement
		recoil_offset = recoil_offset.lerp(Vector2.ZERO, recoil_recovery * delta)

	# Update animation
	update_animation(delta, direction)

func try_attack() -> void:
	var closest_enemy = find_closest_enemy()
	if closest_enemy:
		attack_timer = 0.0
		is_attacking = true
		animation_frame = 0.0  # Reset animation frame to ensure attack animation plays from start
		attack_direction = (closest_enemy.global_position - global_position).normalized()

		# Update facing direction
		if attack_direction.x != 0:
			facing_right = attack_direction.x > 0
			sprite.flip_h = not facing_right

		if is_melee:
			# Melee attack
			perform_melee_attack()
		else:
			# Ranged attack - spawn arrow
			spawn_arrow()

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = fire_range  # Only consider enemies within fire range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	return closest

func spawn_arrow() -> void:
	if arrow_scene == null:
		return

	# Play arrow sound
	if SoundManager:
		SoundManager.play_arrow()

	# Muzzle flash
	spawn_muzzle_flash()

	# Recoil - push player back slightly
	recoil_offset = -attack_direction * 1.0

	# Get ability modifiers (includes permanent upgrades)
	var extra_projectiles: int = 0
	var spread_angle: float = 0.0
	var has_rear_shot: bool = false

	if AbilityManager:
		extra_projectiles = AbilityManager.get_total_projectile_count()
		spread_angle = AbilityManager.stat_modifiers.get("projectile_spread", 0.0)
		has_rear_shot = AbilityManager.has_rear_shot

	var total_projectiles = 1 + extra_projectiles

	# Calculate spread for multiple projectiles
	if total_projectiles > 1:
		var base_spread = spread_angle if spread_angle > 0 else 0.2  # Default small spread
		var start_angle = -base_spread * (total_projectiles - 1) / 2.0

		for i in total_projectiles:
			var angle_offset = start_angle + i * base_spread
			var dir = attack_direction.rotated(angle_offset)
			spawn_single_arrow(dir)
	else:
		spawn_single_arrow(attack_direction)

	# Rear shot ability
	if has_rear_shot:
		spawn_single_arrow(-attack_direction)

func spawn_muzzle_flash() -> void:
	if muzzle_flash_scene == null:
		return

	var flash = muzzle_flash_scene.instantiate()
	flash.global_position = global_position + attack_direction * 20
	get_parent().add_child(flash)

func spawn_swipe_effect() -> void:
	if swipe_effect_scene == null:
		return

	var swipe = swipe_effect_scene.instantiate()
	swipe.global_position = global_position
	swipe.direction = attack_direction
	# Set arc radius based on melee range
	var melee_reach = fire_range
	if AbilityManager:
		melee_reach *= AbilityManager.get_melee_range_multiplier()
	swipe.arc_radius = melee_reach
	get_parent().add_child(swipe)

func spawn_single_arrow(direction: Vector2) -> void:
	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = direction

	# Pass ability info to arrow (includes permanent upgrades)
	if AbilityManager:
		arrow.pierce_count = AbilityManager.stat_modifiers.get("projectile_pierce", 0)
		arrow.can_bounce = AbilityManager.has_rubber_walls
		arrow.has_sniper = AbilityManager.has_sniper_damage
		arrow.sniper_bonus = AbilityManager.sniper_bonus
		arrow.damage_multiplier = AbilityManager.get_damage_multiplier()
		arrow.crit_chance = AbilityManager.get_crit_chance()
		arrow.crit_multiplier = AbilityManager.get_crit_damage_multiplier()
		arrow.has_knockback = AbilityManager.has_knockback
		arrow.knockback_force = AbilityManager.knockback_force
		arrow.speed_multiplier = AbilityManager.get_projectile_speed_multiplier()

	get_parent().add_child(arrow)

func snap_to_8_directions(dir: Vector2) -> Vector2:
	# Snap direction to nearest of 8 cardinal/diagonal directions
	var angle = dir.angle()
	# Round to nearest 45 degrees (PI/4)
	var snapped_angle = round(angle / (PI / 4)) * (PI / 4)
	return Vector2(cos(snapped_angle), sin(snapped_angle))

func perform_melee_attack() -> void:
	# Reset hit tracking for this attack
	melee_hit_enemies.clear()
	melee_hitbox_active = true

	# Snap attack direction to 8 directions for cleaner arc attacks
	attack_direction = snap_to_8_directions(attack_direction)

	# Play swing sound
	if SoundManager:
		SoundManager.play_swing()

	# Spawn swipe effect for melee attacks
	spawn_swipe_effect()

	# Recoil - push player forward slightly for melee
	recoil_offset = attack_direction * 0.5

	# Calculate melee damage
	var melee_damage = 10.0 * base_damage  # Base melee damage

	# Apply ability modifiers
	if AbilityManager:
		melee_damage *= AbilityManager.get_damage_multiplier()

	# Get enemies in melee range with arc check
	var enemies = get_tree().get_nodes_in_group("enemies")

	# Base melee arc (90 degrees), modified by melee_area ability
	var melee_arc = PI / 2
	if AbilityManager:
		melee_arc *= AbilityManager.get_melee_area_multiplier()

	# Melee range, modified by melee_range ability
	var melee_reach = fire_range
	if AbilityManager:
		melee_reach *= AbilityManager.get_melee_range_multiplier()

	for enemy in enemies:
		if is_instance_valid(enemy) and enemy not in melee_hit_enemies:
			var to_enemy = enemy.global_position - global_position
			var dist = to_enemy.length()

			if dist <= melee_reach:
				# Check if enemy is within attack arc
				var angle_to_enemy = to_enemy.angle()
				var attack_angle = attack_direction.angle()
				var angle_diff = abs(angle_to_enemy - attack_angle)

				# Normalize angle difference
				if angle_diff > PI:
					angle_diff = TAU - angle_diff

				if angle_diff <= melee_arc / 2:
					# Hit this enemy
					melee_hit_enemies.append(enemy)

					# Calculate final damage
					var final_damage = melee_damage
					var is_crit = false

					# Crit check
					if AbilityManager:
						var crit_chance = AbilityManager.get_crit_chance()
						if randf() < crit_chance:
							is_crit = true
							final_damage *= AbilityManager.get_crit_damage_multiplier()

					# Apply damage
					if enemy.has_method("take_damage"):
						enemy.take_damage(final_damage, is_crit)

					# Apply stagger on melee hit (0.5s stun)
					if enemy.has_method("apply_stagger"):
						enemy.apply_stagger()

					# Knockback
					if AbilityManager and AbilityManager.has_knockback:
						if enemy.has_method("apply_knockback"):
							enemy.apply_knockback(to_enemy.normalized() * AbilityManager.knockback_force)

	# Slight screen shake on melee hit
	if melee_hit_enemies.size() > 0 and JuiceManager:
		JuiceManager.shake_small()

func update_animation(delta: float, move_direction: Vector2) -> void:
	var prev_row = current_row
	var target_row: int

	if is_attacking:
		if is_melee:
			# Melee uses single attack animation
			target_row = row_attack
		else:
			# Ranged - choose shoot animation based on attack direction
			var angle = attack_direction.angle()
			if angle > -PI/4 and angle < PI/4:
				# Shooting right (straight)
				target_row = row_attack
			elif angle >= PI/4 and angle <= 3*PI/4:
				# Shooting down
				target_row = row_attack_down
			elif angle <= -PI/4 and angle >= -3*PI/4:
				# Shooting up
				target_row = row_attack_up
			else:
				# Shooting left (straight, sprite flipped)
				target_row = row_attack

		# Check if attack animation finished
		if animation_frame >= frame_counts.get(target_row, 8) - 1:
			is_attacking = false
			melee_hitbox_active = false
	elif move_direction.length() > 0:
		target_row = row_move
		# Update facing based on movement when not attacking
		if move_direction.x != 0:
			facing_right = move_direction.x > 0
			sprite.flip_h = not facing_right
	else:
		target_row = row_idle

	current_row = target_row

	# Reset frame when animation changes
	if prev_row != current_row:
		animation_frame = 0.0

	# Advance animation frame
	animation_frame += animation_speed * delta
	var max_frames = frame_counts.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0
		if is_attacking:
			is_attacking = false
			melee_hitbox_active = false

	# Set the sprite frame
	sprite.frame = current_row * cols_per_row + int(animation_frame)

func update_death_animation(delta: float) -> void:
	# Play death animation once, then hold on last frame
	if death_animation_finished:
		return

	current_row = row_death
	animation_frame += animation_speed * delta

	var max_frames = frame_counts.get(row_death, 4)
	if animation_frame >= max_frames - 1:
		animation_frame = max_frames - 1
		death_animation_finished = true

	# Set the sprite frame
	sprite.frame = current_row * cols_per_row + int(animation_frame)

func add_xp(amount: float) -> void:
	# Apply XP multiplier from abilities
	var xp_multiplier = 1.0
	if AbilityManager:
		xp_multiplier = AbilityManager.get_xp_multiplier()
		# Check for double XP
		if AbilityManager.should_double_xp():
			xp_multiplier *= 2.0

	var final_amount = amount * xp_multiplier
	current_xp += final_amount
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level *= 1.5
		# Play level up sound
		if SoundManager:
			SoundManager.play_levelup()
		emit_signal("level_up", current_level)
		emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func give_kill_xp() -> void:
	# Killing enemy gives 3-7% of XP needed
	var xp_gain = xp_to_next_level * randf_range(0.03, 0.07)
	add_xp(xp_gain)

# Ability system helper functions
func heal(amount: float) -> void:
	var actual_heal = min(amount, max_health - current_health)
	if actual_heal <= 0:
		return  # Already at full health

	current_health += actual_heal
	if health_bar:
		health_bar.set_health(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	# Play heal sound
	if SoundManager:
		SoundManager.play_heal()

	# Update low HP vignette
	if JuiceManager:
		JuiceManager.update_player_health(current_health / max_health)

	# Accumulate heal for display - only show when >= 1
	accumulated_heal += actual_heal
	if accumulated_heal >= 1.0:
		var display_amount = floor(accumulated_heal)
		spawn_heal_number(display_amount)
		accumulated_heal -= display_amount

func spawn_heal_number(amount: float) -> void:
	if damage_number_scene == null:
		return

	var heal_num = damage_number_scene.instantiate()
	heal_num.global_position = global_position + Vector2(0, -40)
	get_parent().add_child(heal_num)
	heal_num.set_heal(amount)

func apply_temporary_speed_boost(boost: float, duration: float) -> void:
	temp_speed_boost = boost
	temp_speed_timer = duration

func update_ability_stats(modifiers: Dictionary) -> void:
	# Update speed
	var speed_mult = 1.0 + modifiers.get("move_speed", 0.0)
	speed = base_speed * speed_mult

	# Update attack cooldown (attack speed is inverse)
	var attack_speed_mult = 1.0 + modifiers.get("attack_speed", 0.0)
	# Check for frenzy
	if AbilityManager and AbilityManager.has_frenzy:
		if current_health / max_health < 0.3:
			attack_speed_mult += AbilityManager.frenzy_boost
	attack_cooldown = base_attack_cooldown / attack_speed_mult

	# Update max HP (add flat amount)
	var hp_change = modifiers.get("max_hp", 0.0)
	var old_max = max_health
	max_health = base_max_health + hp_change

	# Adjust current health proportionally
	if old_max > 0 and max_health != old_max:
		var health_percent = current_health / old_max
		current_health = max_health * health_percent
		if health_bar:
			health_bar.set_health(current_health, max_health)
		# Update low HP vignette
		if JuiceManager:
			JuiceManager.update_player_health(current_health / max_health)

	# Update pickup range
	pickup_range_multiplier = 1.0 + modifiers.get("pickup_range", 0.0)

	# Update size
	var new_size = 1.0 + modifiers.get("size", 0.0)
	if new_size != size_scale:
		size_scale = new_size
		scale = Vector2(size_scale, size_scale)

func get_pickup_range() -> float:
	return 80.0 * pickup_range_multiplier  # Base pickup range * multiplier
