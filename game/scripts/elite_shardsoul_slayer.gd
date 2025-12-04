extends EliteBase

# Elite Shardsoul Slayer - "Vexroth the Soulrender"
# The ultimate elite melee predator with devastating combos
# Inspired by Hades Asterius/Theseus and WoW Warrior bosses
#
# Three attack types:
# 1. Rending Strike - Heavy melee with bleed damage over time
# 2. Lunging Assault - Dash attack through player, leaves soul trail
# 3. Soul Shatter - Below 40% HP, becomes enraged with attack speed, damage, and soul trails
#
# Shardsoul Slayer Sprite Sheet: 8 cols x 5 rows, 64x64 per frame
# Row 0: Movement (8 frames)
# Row 1: Attack (8 frames)
# Row 2: Damaged (5 frames)
# Row 3: Death (4 frames)
# Row 4: Special/Lunge (6 frames)

# Attack-specific stats
@export var rend_damage: float = 28.0
@export var rend_range: float = 80.0
@export var rend_bleed_damage: float = 5.0
@export var rend_bleed_duration: float = 4.0

@export var lunge_damage: float = 35.0
@export var lunge_range: float = 250.0
@export var lunge_speed: float = 500.0
@export var lunge_through_distance: float = 100.0  # How far past player

@export var shatter_threshold: float = 0.40  # 40% HP
@export var shatter_damage_mult: float = 1.5
@export var shatter_speed_mult: float = 1.6
@export var shatter_cooldown_mult: float = 0.6
@export var shatter_telegraph_time: float = 2.0

# Animation rows
var ROW_SPECIAL: int = 4

# Attack states
var rend_active: bool = false
var rend_windup_timer: float = 0.0
const REND_WINDUP: float = 0.35

var lunge_active: bool = false
var lunge_windup_timer: float = 0.0
const LUNGE_WINDUP: float = 0.3
var is_lunging: bool = false
var lunge_target: Vector2 = Vector2.ZERO
var lunge_end_pos: Vector2 = Vector2.ZERO

var shatter_active: bool = false
var shatter_triggered: bool = false
var shatter_telegraphing: bool = false
var shatter_telegraph_timer: float = 0.0
var shatter_warning_label: Label = null
var shatter_warning_tween: Tween = null

# Soul trail system
var soul_trail_timer: float = 0.0
const SOUL_TRAIL_INTERVAL: float = 0.15
var active_soul_trails: Array[Node2D] = []
const MAX_SOUL_TRAILS: int = 20

# Store original stats
var base_speed: float = 0.0
var base_damage: float = 0.0

func _setup_elite() -> void:
	elite_name = "Vexroth the Soulrender"
	enemy_type = "shardsoul_slayer_elite"

	# Stats - extremely dangerous melee predator
	speed = 85.0  # Very fast
	base_speed = speed
	max_health = 850.0  # High HP
	attack_damage = rend_damage
	base_damage = attack_damage
	attack_cooldown = 0.7  # Fast attacks
	windup_duration = 0.3
	animation_speed = 14.0

	# Shardsoul Slayer spritesheet: 8 cols x 5 rows
	ROW_IDLE = 0
	ROW_MOVE = 0
	ROW_ATTACK = 1
	ROW_DAMAGE = 2
	ROW_DEATH = 3
	ROW_SPECIAL = 4
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # MOVE/IDLE
		1: 8,   # ATTACK
		2: 5,   # DAMAGED
		3: 4,   # DEATH
		4: 6,   # SPECIAL
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - imposing warrior
	if sprite:
		sprite.scale = Vector2(3.5, 3.5)
		# Dark red soul energy tint
		sprite.modulate = Color(1.0, 0.85, 0.85, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "rending_strike",
			"range": rend_range,
			"cooldown": 2.5,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "lunging_assault",
			"range": lunge_range,
			"cooldown": 6.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "soul_shatter",
			"range": 9999.0,
			"cooldown": 999.0,  # One-time trigger
			"priority": 10
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"rending_strike":
			_start_rending_strike()
		"lunging_assault":
			_start_lunging_assault()
		"soul_shatter":
			_start_soul_shatter()

# Override to check for shatter trigger and spawn soul trails
func _process_behavior(delta: float) -> void:
	# Check for shatter activation
	if not shatter_triggered and not shatter_active and current_health <= max_health * shatter_threshold:
		_trigger_shatter_check()

	# Spawn soul trails when shattered
	if shatter_active:
		_process_soul_trails(delta)

	# Handle lunge movement
	if is_lunging:
		return

	super._process_behavior(delta)

func _trigger_shatter_check() -> void:
	shatter_triggered = true
	attack_cooldowns["soul_shatter"] = 0

# Override attack selection to prioritize shatter when triggered
func _select_best_attack(distance: float) -> Dictionary:
	if shatter_triggered and not shatter_active and attack_cooldowns.get("soul_shatter", 0) <= 0:
		for attack in available_attacks:
			if attack.name == "soul_shatter":
				return attack

	# Prefer lunge when at medium-long range
	if distance > rend_range * 2 and distance < lunge_range and attack_cooldowns.get("lunging_assault", 0) <= 0:
		for attack in available_attacks:
			if attack.name == "lunging_assault":
				return attack

	return super._select_best_attack(distance)

# ============================================
# RENDING STRIKE
# ============================================

func _start_rending_strike() -> void:
	rend_active = true
	rend_windup_timer = REND_WINDUP

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_rending_strike() -> void:
	if not player or not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)

	if dist <= rend_range:
		var damage = rend_damage
		if shatter_active:
			damage *= shatter_damage_mult

		if player.has_method("take_damage"):
			player.take_damage(damage)
			_on_elite_attack_hit(damage)

		# Apply bleed
		_apply_bleed_to_player()

	# Visual slash effect
	_spawn_rend_effect()

	if JuiceManager:
		JuiceManager.shake_small()

func _spawn_rend_effect() -> void:
	var dir = Vector2.RIGHT
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()

	var slash = Node2D.new()
	slash.global_position = global_position + dir * 50
	slash.z_index = 5
	slash.rotation = dir.angle()

	var visual = ColorRect.new()
	visual.size = Vector2(60, 15)
	visual.position = Vector2(-30, -7.5)
	visual.color = Color(0.9, 0.3, 0.3, 0.9)
	slash.add_child(visual)

	get_parent().add_child(slash)

	var tween = create_tween()
	tween.tween_property(visual, "color:a", 0.0, 0.2)
	tween.tween_callback(slash.queue_free)

func _apply_bleed_to_player() -> void:
	if not player or not is_instance_valid(player):
		return

	if player.has_method("apply_bleed"):
		player.apply_bleed(rend_bleed_damage, rend_bleed_duration)
	elif player.has_method("apply_status_effect"):
		player.apply_status_effect("bleed", rend_bleed_duration, rend_bleed_damage)
	else:
		# Fallback bleed
		_apply_fallback_bleed()

func _apply_fallback_bleed() -> void:
	var ticks = int(rend_bleed_duration / 0.5)
	for i in range(ticks):
		var timer = get_tree().create_timer(0.5 * (i + 1))
		timer.timeout.connect(func():
			if player and is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(rend_bleed_damage)
		)

# ============================================
# LUNGING ASSAULT
# ============================================

func _start_lunging_assault() -> void:
	lunge_active = true
	lunge_windup_timer = LUNGE_WINDUP
	show_warning()

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		lunge_target = player.global_position
		lunge_end_pos = player.global_position + dir * lunge_through_distance

		# Show lunge line indicator
		_show_lunge_indicator(dir)

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_SPECIAL, dir)
	animation_frame = 0

func _show_lunge_indicator(direction: Vector2) -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1

	var line = ColorRect.new()
	var total_distance = global_position.distance_to(lunge_end_pos)
	line.size = Vector2(total_distance, 30)
	line.position = Vector2(0, -15)
	line.color = Color(0.8, 0.2, 0.2, 0.3)
	line.rotation = direction.angle()
	line.pivot_offset = Vector2(0, 15)
	indicator.add_child(line)

	get_parent().add_child(indicator)

	var tween = create_tween()
	tween.tween_property(line, "color:a", 0.6, LUNGE_WINDUP * 0.8)
	tween.tween_property(line, "color:a", 0.0, 0.1)
	tween.tween_callback(indicator.queue_free)

func _execute_lunging_assault() -> void:
	hide_warning()
	is_lunging = true

	var start_pos = global_position
	var direction = (lunge_end_pos - start_pos).normalized()
	var distance = start_pos.distance_to(lunge_end_pos)
	var lunge_time = distance / lunge_speed

	# Update facing
	if sprite:
		sprite.flip_h = direction.x < 0

	# Spawn soul trail during lunge
	if shatter_active:
		_spawn_soul_trail_line(start_pos, lunge_end_pos)

	# Tween to end position
	var tween = create_tween()
	tween.tween_property(self, "global_position", lunge_end_pos, lunge_time)
	tween.tween_callback(_on_lunge_complete)

func _on_lunge_complete() -> void:
	is_lunging = false
	lunge_active = false

	# Check for damage (hit during pass-through)
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= 80:
			var damage = lunge_damage
			if shatter_active:
				damage *= shatter_damage_mult

			if player.has_method("take_damage"):
				player.take_damage(damage)
				_on_elite_attack_hit(damage)

			# Apply bleed on lunge hit too
			_apply_bleed_to_player()

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _spawn_soul_trail_line(start: Vector2, end: Vector2) -> void:
	var direction = (end - start).normalized()
	var distance = start.distance_to(end)
	var trail_count = int(distance / 40)

	for i in range(trail_count):
		var pos = start + direction * (i * 40)
		_spawn_single_soul_trail(pos)

# ============================================
# SOUL SHATTER (Special Attack)
# ============================================

func _start_soul_shatter() -> void:
	show_warning()
	is_using_special = true

	shatter_telegraphing = true
	shatter_telegraph_timer = shatter_telegraph_time
	special_timer = shatter_telegraph_time + 0.5

	_show_shatter_warning()

	velocity = Vector2.ZERO

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_DAMAGE, dir)
	animation_frame = 0

func _execute_soul_shatter() -> void:
	shatter_telegraphing = false
	shatter_active = true
	_hide_shatter_warning()

	# Apply shatter buffs
	speed = base_speed * shatter_speed_mult
	attack_damage = base_damage * shatter_damage_mult

	# Reduce all cooldowns
	for attack_name in attack_cooldowns:
		attack_cooldowns[attack_name] = 0.0

	# Reduce future cooldowns
	for attack in available_attacks:
		if attack.name != "soul_shatter":
			attack.cooldown *= shatter_cooldown_mult

	# Visual transformation - intense red soul glow
	if sprite:
		sprite.modulate = Color(1.4, 0.5, 0.5, 1.0)

	# Burst of soul energy
	_spawn_shatter_burst()

	if JuiceManager:
		JuiceManager.shake_large()

func _spawn_shatter_burst() -> void:
	var burst = Node2D.new()
	burst.global_position = global_position
	burst.z_index = 5

	var visual = ColorRect.new()
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = Color(0.9, 0.2, 0.2, 1.0)
	burst.add_child(visual)

	get_parent().add_child(burst)

	var tween = create_tween()
	tween.tween_property(visual, "size", Vector2(200, 200), 0.2)
	tween.parallel().tween_property(visual, "position", Vector2(-100, -100), 0.2)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.35)
	tween.tween_callback(burst.queue_free)

func _process_soul_trails(delta: float) -> void:
	soul_trail_timer += delta
	if soul_trail_timer >= SOUL_TRAIL_INTERVAL:
		soul_trail_timer = 0.0
		_spawn_single_soul_trail(global_position)

func _spawn_single_soul_trail(pos: Vector2) -> void:
	# Clean up old trails
	while active_soul_trails.size() >= MAX_SOUL_TRAILS:
		var old = active_soul_trails.pop_front()
		if is_instance_valid(old):
			old.queue_free()

	var trail = Node2D.new()
	trail.global_position = pos
	trail.z_index = -1
	trail.set_meta("is_soul_trail", true)
	trail.set_meta("damage", 3.0)

	var visual = ColorRect.new()
	visual.size = Vector2(30, 30)
	visual.position = Vector2(-15, -15)
	visual.color = Color(0.8, 0.2, 0.2, 0.6)
	trail.add_child(visual)

	get_parent().add_child(trail)
	active_soul_trails.append(trail)

	# Fade and remove
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(visual, "color:a", 0.0, 0.5)
	tween.tween_callback(func():
		var idx = active_soul_trails.find(trail)
		if idx >= 0:
			active_soul_trails.remove_at(idx)
		trail.queue_free()
	)

func _check_soul_trail_damage(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	for trail in active_soul_trails:
		if not is_instance_valid(trail):
			continue

		var dist = player.global_position.distance_to(trail.global_position)
		if dist < 20:
			var damage = trail.get_meta("damage", 3.0)
			if player.has_method("take_damage"):
				player.take_damage(damage * delta * 3)

func _show_shatter_warning() -> void:
	if shatter_warning_label == null:
		shatter_warning_label = Label.new()
		shatter_warning_label.text = "SOUL SHATTER!"
		shatter_warning_label.add_theme_font_size_override("font_size", 16)
		shatter_warning_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
		shatter_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		shatter_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		shatter_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		shatter_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		shatter_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			shatter_warning_label.add_theme_font_override("font", pixel_font)

		add_child(shatter_warning_label)

	shatter_warning_label.position = Vector2(-55, -80)
	shatter_warning_label.visible = true

	if shatter_warning_tween and shatter_warning_tween.is_valid():
		shatter_warning_tween.kill()

	shatter_warning_tween = create_tween().set_loops()
	shatter_warning_tween.tween_property(shatter_warning_label, "modulate:a", 0.5, 0.1)
	shatter_warning_tween.tween_property(shatter_warning_label, "modulate:a", 1.0, 0.1)

func _hide_shatter_warning() -> void:
	if shatter_warning_tween and shatter_warning_tween.is_valid():
		shatter_warning_tween.kill()
		shatter_warning_tween = null
	if shatter_warning_label:
		shatter_warning_label.visible = false

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Check soul trail damage
	if shatter_active:
		_check_soul_trail_damage(delta)

	# Handle rend windup
	if rend_active:
		rend_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if rend_windup_timer <= 0:
			_execute_rending_strike()
			rend_active = false
			can_attack = false
		return

	# Handle lunge windup
	if lunge_active and not is_lunging:
		lunge_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_SPECIAL, 6)
		sprite.frame = ROW_SPECIAL * COLS_PER_ROW + int(animation_frame) % max_frames

		if lunge_windup_timer <= 0:
			_execute_lunging_assault()
		return

	# Handle lunge movement animation
	if is_lunging:
		var dir = (lunge_end_pos - global_position).normalized()
		animation_frame += animation_speed * 1.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_SPECIAL, 6)
		sprite.frame = ROW_SPECIAL * COLS_PER_ROW + int(animation_frame) % max_frames
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if shatter_telegraphing:
		shatter_telegraph_timer -= delta

		# Shake and intensify during telegraph
		animation_frame += animation_speed * 0.3 * delta
		var max_frames = FRAME_COUNTS.get(ROW_DAMAGE, 5)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_DAMAGE * COLS_PER_ROW + clamped_frame

		# Intensifying red glow
		var progress = 1.0 - (shatter_telegraph_timer / shatter_telegraph_time)
		var intensity = 1.0 + progress * 0.4
		sprite.modulate = Color(intensity, 0.7 - progress * 0.3, 0.7 - progress * 0.3, 1.0)

		# Shake effect
		var shake = Vector2(randf_range(-3, 3), randf_range(-3, 3)) * progress
		sprite.position = shake

		if shatter_telegraph_timer <= 0:
			sprite.position = Vector2.ZERO
			_execute_soul_shatter()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	shatter_telegraphing = false
	hide_warning()
	_hide_shatter_warning()
	if sprite:
		sprite.position = Vector2.ZERO

func die() -> void:
	_hide_shatter_warning()

	# Clean up soul trails
	for trail in active_soul_trails:
		if is_instance_valid(trail):
			trail.queue_free()
	active_soul_trails.clear()

	super.die()
