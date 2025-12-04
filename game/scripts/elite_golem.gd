extends EliteBase

# Elite Golem - "Stoneheart the Immovable"
# A colossal stone guardian with devastating area attacks
# Inspired by WoW Stone Giants and Dark Souls bosses
#
# Three attack types:
# 1. Crushing Blow - Devastating single-target melee
# 2. Shockwave - AOE ground pound that creates expanding ring
# 3. Boulder Storm - Summons falling rocks that leave rubble
#
# Golem Sprite Sheet: 10 cols x 10 rows, 32x32 per frame
# Row 0: Idle (10 frames)
# Row 1: Move (5 frames)
# Row 2: Attack (5 frames)
# Row 3: Damaged (5 frames)
# Row 4: Death (10 frames)

# Attack-specific stats
@export var crush_damage: float = 45.0
@export var crush_range: float = 100.0

@export var shockwave_damage: float = 25.0
@export var shockwave_range: float = 180.0
@export var shockwave_telegraph_time: float = 0.8
@export var shockwave_expand_speed: float = 300.0

@export var boulder_damage: float = 30.0
@export var boulder_count: int = 8
@export var boulder_telegraph_time: float = 1.5
@export var boulder_area_radius: float = 200.0
@export var boulder_range: float = 350.0

# Attack states
var crush_active: bool = false
var crush_windup_timer: float = 0.0
const CRUSH_WINDUP: float = 0.8  # Long telegraph

var shockwave_active: bool = false
var shockwave_windup_timer: float = 0.0
var shockwave_ring: Node2D = null

var boulder_storm_active: bool = false
var boulder_telegraphing: bool = false
var boulder_telegraph_timer: float = 0.0
var boulder_warning_label: Label = null
var boulder_warning_tween: Tween = null
var boulder_indicators: Array[Node2D] = []
var boulder_indicator_tweens: Array[Tween] = []
var boulder_target_positions: Array[Vector2] = []

# Rubble obstacles that persist
var active_rubble: Array[Node2D] = []
const MAX_RUBBLE: int = 6

func _setup_elite() -> void:
	elite_name = "Stoneheart the Immovable"
	enemy_type = "golem_elite"

	# Stats - EXTREMELY tanky, slow, devastating
	speed = 32.0  # Very slow
	max_health = 1200.0  # Highest HP elite
	attack_damage = crush_damage
	attack_cooldown = 1.5
	windup_duration = 0.7
	animation_speed = 6.0  # Slow animations

	# Golem spritesheet: 10 cols x 10 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 10

	FRAME_COUNTS = {
		0: 10,  # IDLE
		1: 5,   # MOVE
		2: 5,   # ATTACK
		3: 5,   # DAMAGED
		4: 10,  # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - MASSIVE golem
	if sprite:
		sprite.scale = Vector2(5.5, 5.5)
		# Stone gray tint
		sprite.modulate = Color(0.85, 0.85, 0.9, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "crushing_blow",
			"range": crush_range,
			"cooldown": 4.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "shockwave",
			"range": shockwave_range,
			"cooldown": 7.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "boulder_storm",
			"range": boulder_range,
			"cooldown": 16.0,
			"priority": 7
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"crushing_blow":
			_start_crushing_blow()
		"shockwave":
			_start_shockwave()
		"boulder_storm":
			_start_boulder_storm()

# ============================================
# CRUSHING BLOW
# ============================================

func _start_crushing_blow() -> void:
	crush_active = true
	crush_windup_timer = CRUSH_WINDUP
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	# Show crush indicator
	_show_crush_indicator(dir)

func _show_crush_indicator(direction: Vector2) -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position + direction * (crush_range * 0.5)
	indicator.z_index = -1

	var rect = ColorRect.new()
	rect.size = Vector2(80, 80)
	rect.position = Vector2(-40, -40)
	rect.color = Color(0.6, 0.3, 0.2, 0.4)
	indicator.add_child(rect)

	get_parent().add_child(indicator)

	var tween = create_tween()
	tween.tween_property(rect, "color:a", 0.7, CRUSH_WINDUP * 0.8)
	tween.tween_property(rect, "color:a", 0.0, 0.15)
	tween.tween_callback(indicator.queue_free)

func _execute_crushing_blow() -> void:
	hide_warning()

	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= crush_range:
			if player.has_method("take_damage"):
				player.take_damage(crush_damage)
				_on_elite_attack_hit(crush_damage)

			# Massive knockback
			if player.has_method("apply_knockback"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.apply_knockback(knockback_dir * 450.0)

	# Visual impact
	_spawn_crush_effect()

	if JuiceManager:
		JuiceManager.shake_large()

func _spawn_crush_effect() -> void:
	var dir = Vector2.RIGHT
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()

	var impact = Node2D.new()
	impact.global_position = global_position + dir * (crush_range * 0.5)
	impact.z_index = 5

	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.6, 0.4, 0.3, 1.0)
	impact.add_child(visual)

	get_parent().add_child(impact)

	var tween = create_tween()
	tween.tween_property(visual, "size", Vector2(100, 100), 0.1)
	tween.parallel().tween_property(visual, "position", Vector2(-50, -50), 0.1)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.3)
	tween.tween_callback(impact.queue_free)

# ============================================
# SHOCKWAVE
# ============================================

func _start_shockwave() -> void:
	shockwave_active = true
	shockwave_windup_timer = shockwave_telegraph_time
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	# Show expanding warning ring
	_show_shockwave_indicator()

func _show_shockwave_indicator() -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1

	var circle = ColorRect.new()
	circle.size = Vector2(shockwave_range * 2, shockwave_range * 2)
	circle.position = Vector2(-shockwave_range, -shockwave_range)
	circle.color = Color(0.5, 0.35, 0.25, 0.3)
	indicator.add_child(circle)

	get_parent().add_child(indicator)

	var tween = create_tween()
	tween.tween_property(circle, "color:a", 0.6, shockwave_telegraph_time * 0.8)
	tween.tween_property(circle, "color:a", 0.0, 0.15)
	tween.tween_callback(indicator.queue_free)

func _execute_shockwave() -> void:
	hide_warning()

	# Create expanding ring effect
	_spawn_shockwave_ring()

	# Damage check happens during ring expansion
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= shockwave_range:
			if player.has_method("take_damage"):
				player.take_damage(shockwave_damage)
				_on_elite_attack_hit(shockwave_damage)

			# Knockback outward
			if player.has_method("apply_knockback"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.apply_knockback(knockback_dir * 300.0)

	if JuiceManager:
		JuiceManager.shake_large()

func _spawn_shockwave_ring() -> void:
	var ring = Node2D.new()
	ring.global_position = global_position
	ring.z_index = 5

	var visual = ColorRect.new()
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = Color(0.7, 0.5, 0.3, 0.8)
	ring.add_child(visual)

	get_parent().add_child(ring)

	var tween = create_tween()
	tween.tween_property(visual, "size", Vector2(shockwave_range * 2, shockwave_range * 2), 0.25)
	tween.parallel().tween_property(visual, "position", Vector2(-shockwave_range, -shockwave_range), 0.25)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.35)
	tween.tween_callback(ring.queue_free)

# ============================================
# BOULDER STORM (Special Attack)
# ============================================

func _start_boulder_storm() -> void:
	show_warning()
	is_using_special = true

	boulder_telegraphing = true
	boulder_telegraph_timer = boulder_telegraph_time
	special_timer = boulder_telegraph_time + 2.0

	# Generate boulder target positions around player
	boulder_target_positions.clear()
	if player and is_instance_valid(player):
		for i in range(boulder_count):
			var offset = Vector2(
				randf_range(-boulder_area_radius, boulder_area_radius),
				randf_range(-boulder_area_radius, boulder_area_radius)
			)
			boulder_target_positions.append(player.global_position + offset)

	_show_boulder_warning()
	_show_boulder_indicators()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_boulder_storm() -> void:
	boulder_telegraphing = false
	_hide_boulder_warning()
	_clear_boulder_indicators()

	# Drop boulders at each target position
	for i in range(boulder_target_positions.size()):
		var target_pos = boulder_target_positions[i]
		_spawn_boulder_delayed(target_pos, i * 0.15)

func _spawn_boulder_delayed(target_pos: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	if is_dying:
		return

	# Create boulder impact
	var boulder = Node2D.new()
	boulder.global_position = target_pos
	boulder.z_index = 10

	var visual = ColorRect.new()
	visual.size = Vector2(50, 50)
	visual.position = Vector2(-25, -25)
	visual.color = Color(0.5, 0.4, 0.35, 1.0)
	boulder.add_child(visual)

	get_parent().add_child(boulder)

	# Check for player damage
	if player and is_instance_valid(player):
		var dist = player.global_position.distance_to(target_pos)
		if dist < 40:
			if player.has_method("take_damage"):
				player.take_damage(boulder_damage)
				_on_elite_attack_hit(boulder_damage)

	# Screen shake per boulder
	if JuiceManager:
		JuiceManager.shake_small()

	# Fade boulder and spawn rubble
	var tween = create_tween()
	tween.tween_property(visual, "color:a", 0.3, 0.3)
	tween.tween_callback(func():
		_spawn_rubble(target_pos)
		boulder.queue_free()
	)

func _spawn_rubble(pos: Vector2) -> void:
	# Clean up old rubble if too many
	while active_rubble.size() >= MAX_RUBBLE:
		var old_rubble = active_rubble.pop_front()
		if is_instance_valid(old_rubble):
			old_rubble.queue_free()

	var rubble = Node2D.new()
	rubble.global_position = pos
	rubble.z_index = -2
	rubble.set_meta("is_rubble", true)

	var visual = ColorRect.new()
	visual.size = Vector2(35, 35)
	visual.position = Vector2(-17.5, -17.5)
	visual.color = Color(0.4, 0.35, 0.3, 0.7)
	rubble.add_child(visual)

	get_parent().add_child(rubble)
	active_rubble.append(rubble)

	# Rubble fades after some time
	await get_tree().create_timer(10.0).timeout
	if is_instance_valid(rubble):
		var fade_tween = create_tween()
		fade_tween.tween_property(visual, "color:a", 0.0, 1.0)
		fade_tween.tween_callback(rubble.queue_free)

		var idx = active_rubble.find(rubble)
		if idx >= 0:
			active_rubble.remove_at(idx)

func _show_boulder_warning() -> void:
	if boulder_warning_label == null:
		boulder_warning_label = Label.new()
		boulder_warning_label.text = "BOULDER STORM!"
		boulder_warning_label.add_theme_font_size_override("font_size", 16)
		boulder_warning_label.add_theme_color_override("font_color", Color(0.7, 0.5, 0.3, 1.0))
		boulder_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		boulder_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		boulder_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		boulder_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		boulder_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			boulder_warning_label.add_theme_font_override("font", pixel_font)

		add_child(boulder_warning_label)

	boulder_warning_label.position = Vector2(-65, -110)
	boulder_warning_label.visible = true

	if boulder_warning_tween and boulder_warning_tween.is_valid():
		boulder_warning_tween.kill()

	boulder_warning_tween = create_tween().set_loops()
	boulder_warning_tween.tween_property(boulder_warning_label, "modulate:a", 0.5, 0.15)
	boulder_warning_tween.tween_property(boulder_warning_label, "modulate:a", 1.0, 0.15)

func _hide_boulder_warning() -> void:
	if boulder_warning_tween and boulder_warning_tween.is_valid():
		boulder_warning_tween.kill()
		boulder_warning_tween = null
	if boulder_warning_label:
		boulder_warning_label.visible = false

func _show_boulder_indicators() -> void:
	_clear_boulder_indicators()

	for target_pos in boulder_target_positions:
		var indicator = Node2D.new()
		indicator.global_position = target_pos
		indicator.z_index = 5

		var circle = ColorRect.new()
		circle.size = Vector2(50, 50)
		circle.position = Vector2(-25, -25)
		circle.color = Color(0.6, 0.4, 0.3, 0.4)
		indicator.add_child(circle)

		get_parent().add_child(indicator)
		boulder_indicators.append(indicator)

		var tween = create_tween().set_loops()
		tween.tween_property(circle, "color:a", 0.2, 0.2)
		tween.tween_property(circle, "color:a", 0.5, 0.2)
		boulder_indicator_tweens.append(tween)

func _clear_boulder_indicators() -> void:
	for tween in boulder_indicator_tweens:
		if tween and tween.is_valid():
			tween.kill()
	boulder_indicator_tweens.clear()

	for indicator in boulder_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	boulder_indicators.clear()

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle crush windup
	if crush_active:
		crush_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 5)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if crush_windup_timer <= 0:
			_execute_crushing_blow()
			crush_active = false
			can_attack = false
		return

	# Handle shockwave windup
	if shockwave_active:
		shockwave_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 5)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if shockwave_windup_timer <= 0:
			_execute_shockwave()
			shockwave_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if boulder_telegraphing:
		boulder_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 5)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Rumbling effect - slight shake
		var offset = Vector2(randf_range(-2, 2), randf_range(-2, 2))
		sprite.position = offset

		if boulder_telegraph_timer <= 0:
			sprite.position = Vector2.ZERO
			_execute_boulder_storm()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_boulder_storm()

func _end_boulder_storm() -> void:
	boulder_telegraphing = false
	hide_warning()
	_hide_boulder_warning()
	_clear_boulder_indicators()
	if sprite:
		sprite.position = Vector2.ZERO

# Golem has massive damage resistance
func take_damage(amount: float, is_critical: bool = false) -> void:
	# 25% damage reduction from stone body
	var reduced = amount * 0.75
	super.take_damage(reduced, is_critical)

# Golem is immovable
func apply_knockback(force: Vector2) -> void:
	# Golem cannot be knocked back
	pass

func die() -> void:
	_end_boulder_storm()

	# Clean up rubble
	for rubble in active_rubble:
		if is_instance_valid(rubble):
			rubble.queue_free()
	active_rubble.clear()

	super.die()
