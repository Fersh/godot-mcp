extends EliteBase

# Elite Ghoul - "Rotfather"
# A massive undead brute with devastating melee and life drain
# Inspired by WoW Patchwerk and Diablo Butcher
#
# Three attack types:
# 1. Crushing Slam - Heavy melee with knockback
# 2. Gore Toss - Throws meat chunks that slow
# 3. Undying Fury - Below 30% HP, gains frenzy with life steal
#
# Ghoul Sprite Sheet: 8 cols x 5 rows, 32x32 per frame
# Row 0: Idle (4 frames)
# Row 1: Movement (8 frames)
# Row 2: Attack (6 frames)
# Row 3: Damaged (4 frames)
# Row 4: Death (6 frames)

# Attack-specific stats
@export var slam_damage: float = 30.0
@export var slam_range: float = 90.0
@export var slam_knockback: float = 350.0
@export var slam_aoe_radius: float = 110.0

@export var gore_damage: float = 12.0
@export var gore_range: float = 200.0
@export var gore_speed: float = 140.0
@export var gore_slow_amount: float = 0.4  # 40% slow
@export var gore_slow_duration: float = 2.5

@export var fury_threshold: float = 0.30  # 30% HP
@export var fury_lifesteal: float = 0.25  # 25% lifesteal
@export var fury_damage_mult: float = 1.4
@export var fury_speed_mult: float = 1.5
@export var fury_telegraph_time: float = 1.5

# Attack states
var slam_active: bool = false
var slam_windup_timer: float = 0.0
const SLAM_WINDUP: float = 0.6

var gore_active: bool = false
var gore_windup_timer: float = 0.0
const GORE_WINDUP: float = 0.4

var fury_active: bool = false
var fury_triggered: bool = false
var fury_telegraphing: bool = false
var fury_telegraph_timer: float = 0.0
var fury_warning_label: Label = null
var fury_warning_tween: Tween = null

# Store original stats for fury mode (base_speed inherited from EnemyBase)
var base_damage: float = 0.0

func _setup_elite() -> void:
	elite_name = "Rotfather"
	enemy_type = "ghoul_elite"

	# Stats - extremely tanky melee bruiser
	speed = 52.0
	base_speed = speed
	max_health = 950.0  # Very high HP
	attack_damage = slam_damage
	base_damage = attack_damage
	attack_cooldown = 1.2
	windup_duration = 0.5
	animation_speed = 9.0

	# Ghoul spritesheet: 8 cols x 5 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 6,   # ATTACK
		3: 4,   # DAMAGED
		4: 6,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - massive ghoul
	if sprite:
		sprite.scale = Vector2(4.5, 4.5)
		# Slightly pale/undead tint
		sprite.modulate = Color(0.85, 0.9, 0.85, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "crushing_slam",
			"range": slam_range,
			"cooldown": 3.5,
			"priority": 6
		},
		{
			"type": AttackType.RANGED,
			"name": "gore_toss",
			"range": gore_range,
			"cooldown": 5.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "undying_fury",
			"range": 9999.0,  # Always in range
			"cooldown": 999.0,  # One-time trigger
			"priority": 10
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"crushing_slam":
			_start_crushing_slam()
		"gore_toss":
			_start_gore_toss()
		"undying_fury":
			_start_undying_fury()

# Override to check for fury trigger
func _process_behavior(delta: float) -> void:
	# Check for fury activation
	if not fury_triggered and not fury_active and current_health <= max_health * fury_threshold:
		_trigger_fury_check()

	super._process_behavior(delta)

func _trigger_fury_check() -> void:
	# Force fury activation when below threshold
	fury_triggered = true
	attack_cooldowns["undying_fury"] = 0  # Reset cooldown to allow trigger

# Override attack selection to prioritize fury when triggered
func _select_best_attack(distance: float) -> Dictionary:
	# If fury should trigger, prioritize it
	if fury_triggered and not fury_active and attack_cooldowns.get("undying_fury", 0) <= 0:
		for attack in available_attacks:
			if attack.name == "undying_fury":
				return attack

	return super._select_best_attack(distance)

# ============================================
# CRUSHING SLAM
# ============================================

func _start_crushing_slam() -> void:
	slam_active = true
	slam_windup_timer = SLAM_WINDUP
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	# Show slam indicator
	_show_slam_indicator()

func _show_slam_indicator() -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1

	var circle = ColorRect.new()
	circle.size = Vector2(slam_aoe_radius * 2, slam_aoe_radius * 2)
	circle.position = Vector2(-slam_aoe_radius, -slam_aoe_radius)
	circle.color = Color(0.7, 0.3, 0.3, 0.3)
	indicator.add_child(circle)

	get_parent().add_child(indicator)

	var tween = create_tween()
	tween.tween_property(circle, "color:a", 0.6, SLAM_WINDUP * 0.8)
	tween.tween_property(circle, "color:a", 0.0, 0.15)
	tween.tween_callback(indicator.queue_free)

func _execute_crushing_slam() -> void:
	hide_warning()

	# AOE damage with knockback
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= slam_aoe_radius:
			var damage = slam_damage
			if fury_active:
				damage *= fury_damage_mult

			if player.has_method("take_damage"):
				player.take_damage(damage)
				_on_elite_attack_hit(damage)

				# Lifesteal in fury mode
				if fury_active:
					var heal = damage * fury_lifesteal
					current_health = min(current_health + heal, max_health)
					elite_health_changed.emit(current_health, max_health)
					_show_lifesteal_effect()

			# Knockback
			if player.has_method("apply_knockback"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.apply_knockback(knockback_dir * slam_knockback)

	# Visual slam effect
	_spawn_slam_effect()

	if JuiceManager:
		JuiceManager.shake_large()

func _spawn_slam_effect() -> void:
	var slam = Node2D.new()
	slam.global_position = global_position
	slam.z_index = 5

	var visual = ColorRect.new()
	visual.size = Vector2(30, 30)
	visual.position = Vector2(-15, -15)
	visual.color = Color(0.8, 0.4, 0.3, 0.9)
	slam.add_child(visual)

	get_parent().add_child(slam)

	var tween = create_tween()
	tween.tween_property(visual, "size", Vector2(slam_aoe_radius * 2, slam_aoe_radius * 2), 0.12)
	tween.parallel().tween_property(visual, "position", Vector2(-slam_aoe_radius, -slam_aoe_radius), 0.12)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.25)
	tween.tween_callback(slam.queue_free)

# ============================================
# GORE TOSS
# ============================================

func _start_gore_toss() -> void:
	gore_active = true
	gore_windup_timer = GORE_WINDUP

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_gore_toss() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Create gore projectile
	var gore = Node2D.new()
	gore.global_position = global_position + direction * 30
	gore.z_index = 5
	gore.set_meta("direction", direction)
	gore.set_meta("speed", gore_speed)
	gore.set_meta("damage", gore_damage)
	gore.set_meta("lifetime", gore_range / gore_speed)

	var visual = ColorRect.new()
	visual.size = Vector2(25, 25)
	visual.position = Vector2(-12.5, -12.5)
	visual.color = Color(0.6, 0.2, 0.2, 1.0)
	gore.add_child(visual)

	get_parent().add_child(gore)

	# Process gore movement
	_process_gore_projectile(gore)

func _process_gore_projectile(gore: Node2D) -> void:
	var direction = gore.get_meta("direction")
	var proj_speed = gore.get_meta("speed")
	var damage = gore.get_meta("damage")
	var lifetime = gore.get_meta("lifetime")
	var elapsed = 0.0

	while elapsed < lifetime and is_instance_valid(gore):
		var delta = get_process_delta_time()
		elapsed += delta
		gore.global_position += direction * proj_speed * delta

		# Check for player collision
		if player and is_instance_valid(player):
			var dist = gore.global_position.distance_to(player.global_position)
			if dist < 35:
				if player.has_method("take_damage"):
					player.take_damage(damage)
					_on_elite_attack_hit(damage)

				# Apply slow
				if player.has_method("apply_slow"):
					player.apply_slow(gore_slow_amount, gore_slow_duration)

				gore.queue_free()
				return

		await get_tree().process_frame

	if is_instance_valid(gore):
		gore.queue_free()

# ============================================
# UNDYING FURY (Special Attack)
# ============================================

func _start_undying_fury() -> void:
	show_warning()
	is_using_special = true

	fury_telegraphing = true
	fury_telegraph_timer = fury_telegraph_time
	special_timer = fury_telegraph_time + 0.5

	_show_fury_warning()

	# Stop and telegraph
	velocity = Vector2.ZERO

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_DAMAGE, dir)  # Use damage animation for rage
	animation_frame = 0

func _execute_undying_fury() -> void:
	fury_telegraphing = false
	fury_active = true
	_hide_fury_warning()

	# Apply fury buffs
	speed = base_speed * fury_speed_mult
	attack_damage = base_damage * fury_damage_mult

	# Reduce attack cooldowns
	for attack_name in attack_cooldowns:
		attack_cooldowns[attack_name] = 0.0

	# Visual feedback - red rage aura
	if sprite:
		sprite.modulate = Color(1.3, 0.6, 0.6, 1.0)

	if JuiceManager:
		JuiceManager.shake_large()

func _show_fury_warning() -> void:
	if fury_warning_label == null:
		fury_warning_label = Label.new()
		fury_warning_label.text = "UNDYING FURY!"
		fury_warning_label.add_theme_font_size_override("font_size", 16)
		fury_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.2, 1.0))
		fury_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		fury_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		fury_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		fury_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		fury_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			fury_warning_label.add_theme_font_override("font", pixel_font)

		add_child(fury_warning_label)

	fury_warning_label.position = Vector2(-65, -100)
	fury_warning_label.visible = true

	if fury_warning_tween and fury_warning_tween.is_valid():
		fury_warning_tween.kill()

	fury_warning_tween = create_tween().set_loops()
	fury_warning_tween.tween_property(fury_warning_label, "modulate:a", 0.5, 0.1)
	fury_warning_tween.tween_property(fury_warning_label, "modulate:a", 1.0, 0.1)

func _hide_fury_warning() -> void:
	if fury_warning_tween and fury_warning_tween.is_valid():
		fury_warning_tween.kill()
		fury_warning_tween = null
	if fury_warning_label:
		fury_warning_label.visible = false

func _show_lifesteal_effect() -> void:
	if sprite:
		var original = sprite.modulate
		sprite.modulate = Color(0.5, 1.0, 0.5)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.3, 0.6, 0.6), 0.2)

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle slam windup
	if slam_active:
		slam_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 6)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if slam_windup_timer <= 0:
			_execute_crushing_slam()
			slam_active = false
			can_attack = false
		return

	# Handle gore windup
	if gore_active:
		gore_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 6)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if gore_windup_timer <= 0:
			_execute_gore_toss()
			gore_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if fury_telegraphing:
		fury_telegraph_timer -= delta

		# Shake and pulse during telegraph
		animation_frame += animation_speed * 0.3 * delta
		var max_frames = FRAME_COUNTS.get(ROW_DAMAGE, 4)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_DAMAGE * COLS_PER_ROW + clamped_frame

		# Intensifying red pulse
		var progress = 1.0 - (fury_telegraph_timer / fury_telegraph_time)
		var intensity = 0.8 + progress * 0.5
		sprite.modulate = Color(intensity, 0.6 - progress * 0.2, 0.6 - progress * 0.2, 1.0)

		if fury_telegraph_timer <= 0:
			_execute_undying_fury()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	fury_telegraphing = false
	hide_warning()
	_hide_fury_warning()

# Ghoul has damage resistance
func take_damage(amount: float, is_critical: bool = false) -> void:
	# 15% damage reduction
	var reduced = amount * 0.85
	super.take_damage(reduced, is_critical)

# Ghoul resists knockback
func apply_knockback(force: Vector2) -> void:
	super.apply_knockback(force * 0.3)

func die() -> void:
	_hide_fury_warning()
	super.die()
