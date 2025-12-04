extends EliteBase

# Elite Ratfolk Mage - "Archmage Whiskersnatch"
# A powerful caster with devastating magical attacks
# Inspired by Hades mage enemies and WoW mage bosses
#
# Three attack types:
# 1. Magic Missile Barrage - Fires 3-5 slow homing magic missiles
# 2. Arcane Explosion - AOE burst around self when player gets too close
# 3. Meteor Shower - Special attack that rains meteors in area around player
#
# Ratfolk Mage Sprite Sheet: 8 cols x 6 rows, 32x32 per frame
# Row 0: Idle (8 frames)
# Row 1: Movement (8 frames)
# Row 2: Cast 1 (6 frames)
# Row 3: Cast 2 (6 frames)
# Row 4: Damaged (4 frames)
# Row 5: Death (5 frames)

@export var spell_projectile_scene: PackedScene

# Attack-specific stats
@export var missile_damage: float = 12.0
@export var missile_range: float = 280.0
@export var missile_speed: float = 100.0  # Slow but homing
@export var missile_count: int = 4

@export var arcane_explosion_damage: float = 20.0
@export var arcane_explosion_range: float = 120.0
@export var explosion_trigger_distance: float = 80.0

@export var meteor_damage: float = 25.0
@export var meteor_range: float = 300.0
@export var meteor_telegraph_time: float = 1.5
@export var meteor_count: int = 6
@export var meteor_area_radius: float = 150.0

# Animation rows
var ROW_CAST_1: int = 2
var ROW_CAST_2: int = 3

# Attack states
var missile_barrage_active: bool = false
var missile_windup_timer: float = 0.0
const MISSILE_WINDUP: float = 0.6

var explosion_active: bool = false
var explosion_windup_timer: float = 0.0
const EXPLOSION_WINDUP: float = 0.3
var explosion_cooldown_timer: float = 0.0

var meteor_shower_active: bool = false
var meteor_telegraphing: bool = false
var meteor_telegraph_timer: float = 0.0
var meteor_warning_label: Label = null
var meteor_warning_tween: Tween = null
var meteor_indicators: Array[Node2D] = []
var meteor_indicator_tweens: Array[Tween] = []
var meteor_target_positions: Array[Vector2] = []

# Preferred range - mage wants to stay at distance
var preferred_range: float = 180.0

func _setup_elite() -> void:
	elite_name = "Archmage Whiskersnatch"
	enemy_type = "ratfolk_mage_elite"

	# Stats - glass cannon, but elite-tier HP
	speed = 55.0  # Fast for kiting
	max_health = 550.0
	attack_damage = missile_damage
	attack_cooldown = 1.0
	windup_duration = 0.5
	animation_speed = 10.0

	# Ratfolk Mage spritesheet: 8 cols x 6 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_CAST_1 = 2
	ROW_CAST_2 = 3
	ROW_DAMAGE = 4
	ROW_DEATH = 5
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # IDLE
		1: 8,   # MOVE
		2: 6,   # CAST 1
		3: 6,   # CAST 2
		4: 4,   # DAMAGED
		5: 5,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size
	if sprite:
		sprite.scale = Vector2(3.5, 3.5)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.RANGED,
			"name": "magic_missile_barrage",
			"range": missile_range,
			"cooldown": 4.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "arcane_explosion",
			"range": explosion_trigger_distance,
			"cooldown": 6.0,
			"priority": 8  # High priority when player is close
		},
		{
			"type": AttackType.SPECIAL,
			"name": "meteor_shower",
			"range": meteor_range,
			"cooldown": 12.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"magic_missile_barrage":
			_start_magic_missile_barrage()
		"arcane_explosion":
			_start_arcane_explosion()
		"meteor_shower":
			_start_meteor_shower()

# Override behavior to maintain distance
func _process_behavior(delta: float) -> void:
	if is_using_special:
		_process_special_attack(delta)
		return

	# Update explosion cooldown
	explosion_cooldown_timer -= delta

	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Kite behavior - retreat if too close
		if distance < preferred_range * 0.5 and explosion_cooldown_timer <= 0:
			# Player is very close - either explosion or retreat
			var best_attack = _select_best_attack(distance)
			if not best_attack.is_empty() and best_attack.name == "arcane_explosion":
				velocity = Vector2.ZERO
				if can_attack and attack_cooldowns[best_attack.name] <= 0:
					current_attack = best_attack
					_start_elite_attack(best_attack)
				else:
					update_animation(delta, ROW_IDLE, dir_normalized)
			else:
				# Retreat
				velocity = -dir_normalized * speed * 1.3
				move_and_slide()
				update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance < preferred_range:
			# Slightly too close - back away slowly while casting
			velocity = -dir_normalized * speed * 0.5
			move_and_slide()

			var best_attack = _select_best_attack(distance)
			if not best_attack.is_empty() and can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > missile_range:
			# Too far - approach
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			# In ideal range - cast spells
			velocity = Vector2.ZERO

			var best_attack = _select_best_attack(distance)
			if not best_attack.is_empty() and can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_IDLE, dir_normalized)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

# ============================================
# MAGIC MISSILE BARRAGE
# ============================================

func _start_magic_missile_barrage() -> void:
	missile_barrage_active = true
	missile_windup_timer = MISSILE_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_CAST_1, dir)
	animation_frame = 0

func _execute_magic_missile_barrage() -> void:
	if not player or not is_instance_valid(player):
		return

	# Fire multiple homing missiles in a spread pattern
	for i in range(missile_count):
		# Stagger the missiles slightly
		var delay = i * 0.15
		_spawn_homing_missile_delayed(delay, i)

func _spawn_homing_missile_delayed(delay: float, index: int) -> void:
	await get_tree().create_timer(delay).timeout

	if not player or not is_instance_valid(player) or is_dying:
		return

	var base_dir = (player.global_position - global_position).normalized()

	# Spread the missiles in an arc
	var spread_angle = deg_to_rad(15)  # 15 degrees spread
	var angle_offset = (index - (missile_count - 1) / 2.0) * spread_angle
	var missile_dir = base_dir.rotated(angle_offset)

	_spawn_homing_missile(missile_dir)

func _spawn_homing_missile(direction: Vector2) -> void:
	var proj_scene = spell_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 30

		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = missile_speed
		if "damage" in proj:
			proj.damage = missile_damage

		# Add homing behavior via script modification
		proj.set_meta("homing", true)
		proj.set_meta("homing_strength", 1.5)
		proj.set_meta("target", player)

		# Purple magic tint
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(0.8, 0.3, 1.0)
			proj.get_node("Sprite2D").scale = Vector2(1.5, 1.5)
		elif proj.has_node("Sprite"):
			proj.get_node("Sprite").modulate = Color(0.8, 0.3, 1.0)
			proj.get_node("Sprite").scale = Vector2(1.5, 1.5)

		get_parent().add_child(proj)

# ============================================
# ARCANE EXPLOSION
# ============================================

func _start_arcane_explosion() -> void:
	explosion_active = true
	explosion_windup_timer = EXPLOSION_WINDUP
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_CAST_2, dir)
	animation_frame = 0

	# Visual indicator - expanding ring
	_show_explosion_indicator()

func _show_explosion_indicator() -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1

	var circle = ColorRect.new()
	circle.size = Vector2(arcane_explosion_range * 2, arcane_explosion_range * 2)
	circle.position = Vector2(-arcane_explosion_range, -arcane_explosion_range)
	circle.color = Color(0.8, 0.3, 1.0, 0.3)
	indicator.add_child(circle)

	get_parent().add_child(indicator)

	# Pulse and then remove
	var tween = create_tween()
	tween.tween_property(circle, "color:a", 0.6, EXPLOSION_WINDUP * 0.5)
	tween.tween_property(circle, "color:a", 0.0, 0.2)
	tween.tween_callback(indicator.queue_free)

func _execute_arcane_explosion() -> void:
	hide_warning()
	explosion_cooldown_timer = 3.0  # Internal cooldown

	# AOE damage around self
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= arcane_explosion_range:
			if player.has_method("take_damage"):
				player.take_damage(arcane_explosion_damage)
				_on_elite_attack_hit(arcane_explosion_damage)

			# Knockback player
			if player.has_method("apply_knockback"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.apply_knockback(knockback_dir * 300.0)

	# Visual explosion effect
	_spawn_explosion_effect()

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_explosion_effect() -> void:
	var explosion = Node2D.new()
	explosion.global_position = global_position
	explosion.z_index = 10

	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.8, 0.3, 1.0, 1.0)
	explosion.add_child(visual)

	get_parent().add_child(explosion)

	# Expand and fade
	var tween = create_tween()
	tween.tween_property(visual, "size", Vector2(arcane_explosion_range * 2, arcane_explosion_range * 2), 0.15)
	tween.parallel().tween_property(visual, "position", Vector2(-arcane_explosion_range, -arcane_explosion_range), 0.15)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

# ============================================
# METEOR SHOWER (Special Attack)
# ============================================

func _start_meteor_shower() -> void:
	show_warning()
	is_using_special = true

	meteor_telegraphing = true
	meteor_telegraph_timer = meteor_telegraph_time
	special_timer = meteor_telegraph_time + 1.5

	# Generate meteor target positions around player
	meteor_target_positions.clear()
	if player and is_instance_valid(player):
		for i in range(meteor_count):
			var offset = Vector2(
				randf_range(-meteor_area_radius, meteor_area_radius),
				randf_range(-meteor_area_radius, meteor_area_radius)
			)
			meteor_target_positions.append(player.global_position + offset)

	_show_meteor_warning()
	_show_meteor_indicators()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_CAST_2, dir)
	animation_frame = 0

func _execute_meteor_shower() -> void:
	meteor_telegraphing = false
	_hide_meteor_warning()
	_clear_meteor_indicators()

	# Drop meteors at each target position with slight delays
	for i in range(meteor_target_positions.size()):
		var target_pos = meteor_target_positions[i]
		_spawn_meteor_delayed(target_pos, i * 0.12)

func _spawn_meteor_delayed(target_pos: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	if is_dying:
		return

	# Create meteor impact
	var meteor = Node2D.new()
	meteor.global_position = target_pos
	meteor.z_index = 10

	var visual = ColorRect.new()
	visual.size = Vector2(60, 60)
	visual.position = Vector2(-30, -30)
	visual.color = Color(1.0, 0.4, 0.1, 1.0)
	meteor.add_child(visual)

	get_parent().add_child(meteor)

	# Check for player damage
	if player and is_instance_valid(player):
		var dist = player.global_position.distance_to(target_pos)
		if dist < 50:
			if player.has_method("take_damage"):
				player.take_damage(meteor_damage)
				_on_elite_attack_hit(meteor_damage)

	# Screen shake per meteor
	if JuiceManager:
		JuiceManager.shake_small()

	# Fade out meteor
	var tween = create_tween()
	tween.tween_property(visual, "color:a", 0.0, 0.4)
	tween.tween_callback(meteor.queue_free)

func _show_meteor_warning() -> void:
	if meteor_warning_label == null:
		meteor_warning_label = Label.new()
		meteor_warning_label.text = "METEOR SHOWER!"
		meteor_warning_label.add_theme_font_size_override("font_size", 16)
		meteor_warning_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2, 1.0))
		meteor_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		meteor_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		meteor_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		meteor_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		meteor_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			meteor_warning_label.add_theme_font_override("font", pixel_font)

		add_child(meteor_warning_label)

	meteor_warning_label.position = Vector2(-65, -80)
	meteor_warning_label.visible = true

	if meteor_warning_tween and meteor_warning_tween.is_valid():
		meteor_warning_tween.kill()

	meteor_warning_tween = create_tween().set_loops()
	meteor_warning_tween.tween_property(meteor_warning_label, "modulate:a", 0.5, 0.15)
	meteor_warning_tween.tween_property(meteor_warning_label, "modulate:a", 1.0, 0.15)

func _hide_meteor_warning() -> void:
	if meteor_warning_tween and meteor_warning_tween.is_valid():
		meteor_warning_tween.kill()
		meteor_warning_tween = null
	if meteor_warning_label:
		meteor_warning_label.visible = false

func _show_meteor_indicators() -> void:
	_clear_meteor_indicators()

	for target_pos in meteor_target_positions:
		var indicator = Node2D.new()
		indicator.global_position = target_pos
		indicator.z_index = 5

		var circle = ColorRect.new()
		circle.size = Vector2(60, 60)
		circle.position = Vector2(-30, -30)
		circle.color = Color(1.0, 0.4, 0.1, 0.4)
		indicator.add_child(circle)

		get_parent().add_child(indicator)
		meteor_indicators.append(indicator)

		var tween = create_tween().set_loops()
		tween.tween_property(circle, "color:a", 0.2, 0.2)
		tween.tween_property(circle, "color:a", 0.5, 0.2)
		meteor_indicator_tweens.append(tween)

func _clear_meteor_indicators() -> void:
	for tween in meteor_indicator_tweens:
		if tween and tween.is_valid():
			tween.kill()
	meteor_indicator_tweens.clear()

	for indicator in meteor_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	meteor_indicators.clear()

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle missile barrage windup
	if missile_barrage_active:
		missile_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_CAST_1, 6)
		sprite.frame = ROW_CAST_1 * COLS_PER_ROW + int(animation_frame) % max_frames

		if missile_windup_timer <= 0:
			_execute_magic_missile_barrage()
			missile_barrage_active = false
			can_attack = false
		return

	# Handle explosion windup
	if explosion_active:
		explosion_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_CAST_2, 6)
		sprite.frame = ROW_CAST_2 * COLS_PER_ROW + int(animation_frame) % max_frames

		if explosion_windup_timer <= 0:
			_execute_arcane_explosion()
			explosion_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if meteor_telegraphing:
		meteor_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_CAST_2, 6)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_CAST_2 * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		if meteor_telegraph_timer <= 0:
			_execute_meteor_shower()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_meteor_shower()

func _end_meteor_shower() -> void:
	meteor_telegraphing = false
	hide_warning()
	_hide_meteor_warning()
	_clear_meteor_indicators()

func die() -> void:
	_end_meteor_shower()
	super.die()
