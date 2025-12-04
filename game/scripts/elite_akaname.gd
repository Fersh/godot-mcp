extends EliteBase

# Elite Akaname - "The Plague Licker"
# A massive poison yokai that spreads devastating toxins
# Inspired by WoW poison bosses and Hades Hydra
#
# Three attack types:
# 1. Tongue Lash - Long-range melee with guaranteed poison
# 2. Poison Pool - Spits a damaging pool that persists
# 3. Miasma - Fills area with poison fog, stacking damage
#
# Akaname Sprite Sheet: 8 cols x 4 rows, 32x32 per frame
# Row 0: Idle (5 frames)
# Row 1: Move (8 frames)
# Row 2: Attack (8 frames)
# Row 3: Death (6 frames)

# Attack-specific stats
@export var tongue_damage: float = 20.0
@export var tongue_range: float = 120.0
@export var tongue_poison_damage: float = 8.0
@export var tongue_poison_duration: float = 5.0

@export var pool_damage: float = 6.0  # Per second
@export var pool_range: float = 220.0
@export var pool_duration: float = 6.0
@export var pool_radius: float = 70.0

@export var miasma_damage: float = 4.0  # Per second, stacking
@export var miasma_range: float = 200.0
@export var miasma_telegraph_time: float = 1.2
@export var miasma_duration: float = 5.0
@export var miasma_radius: float = 200.0

# Attack states
var tongue_lash_active: bool = false
var tongue_windup_timer: float = 0.0
const TONGUE_WINDUP: float = 0.35

var pool_spit_active: bool = false
var pool_windup_timer: float = 0.0
const POOL_WINDUP: float = 0.5
var pool_target_pos: Vector2 = Vector2.ZERO
var pool_indicator: Node2D = null
var pool_indicator_tween: Tween = null

var miasma_active: bool = false
var miasma_telegraphing: bool = false
var miasma_telegraph_timer: float = 0.0
var miasma_warning_label: Label = null
var miasma_warning_tween: Tween = null
var miasma_cloud: Node2D = null
var miasma_damage_timer: float = 0.0
var miasma_stack_count: int = 0

# Active poison pools
var active_pools: Array[Node2D] = []

func _setup_elite() -> void:
	elite_name = "The Plague Licker"
	enemy_type = "akaname_elite"

	# Stats - moderately tanky poison spreader
	speed = 58.0
	max_health = 680.0
	attack_damage = tongue_damage
	attack_cooldown = 1.0
	windup_duration = 0.4
	animation_speed = 10.0

	# Akaname spritesheet: 8 cols x 4 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 0
	ROW_DEATH = 3
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 5,   # IDLE
		1: 8,   # MOVE
		2: 8,   # ATTACK
		3: 6,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - big licking monster
	if sprite:
		sprite.scale = Vector2(4.0, 4.0)
		# Sickly green tint
		sprite.modulate = Color(0.8, 1.0, 0.7, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "tongue_lash",
			"range": tongue_range,
			"cooldown": 3.0,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "poison_pool",
			"range": pool_range,
			"cooldown": 6.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "miasma",
			"range": miasma_range,
			"cooldown": 14.0,
			"priority": 7
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"tongue_lash":
			_start_tongue_lash()
		"poison_pool":
			_start_poison_pool()
		"miasma":
			_start_miasma()

# ============================================
# TONGUE LASH
# ============================================

func _start_tongue_lash() -> void:
	tongue_lash_active = true
	tongue_windup_timer = TONGUE_WINDUP

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	# Show tongue indicator
	_show_tongue_indicator(dir)

func _show_tongue_indicator(direction: Vector2) -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1

	var line = ColorRect.new()
	line.size = Vector2(tongue_range, 20)
	line.position = Vector2(0, -10)
	line.color = Color(0.4, 0.8, 0.3, 0.4)
	line.rotation = direction.angle()
	line.pivot_offset = Vector2(0, 10)
	indicator.add_child(line)

	get_parent().add_child(indicator)

	var tween = create_tween()
	tween.tween_property(line, "color:a", 0.7, TONGUE_WINDUP * 0.8)
	tween.tween_property(line, "color:a", 0.0, 0.1)
	tween.tween_callback(indicator.queue_free)

func _execute_tongue_lash() -> void:
	if not player or not is_instance_valid(player):
		return

	var distance = global_position.distance_to(player.global_position)

	if distance <= tongue_range:
		if player.has_method("take_damage"):
			player.take_damage(tongue_damage)
			_on_elite_attack_hit(tongue_damage)

		# Guaranteed poison
		_apply_poison_to_player()

	# Visual tongue effect
	_spawn_tongue_effect()

func _spawn_tongue_effect() -> void:
	var tongue = Node2D.new()
	tongue.global_position = global_position
	tongue.z_index = 5

	var dir = Vector2.RIGHT
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()

	var visual = ColorRect.new()
	visual.size = Vector2(10, 15)
	visual.position = Vector2(0, -7.5)
	visual.color = Color(0.9, 0.3, 0.4, 1.0)
	visual.rotation = dir.angle()
	visual.pivot_offset = Vector2(0, 7.5)
	tongue.add_child(visual)

	get_parent().add_child(tongue)

	# Extend and retract
	var tween = create_tween()
	tween.tween_property(visual, "size:x", tongue_range, 0.08)
	tween.tween_property(visual, "size:x", 10, 0.1)
	tween.tween_callback(tongue.queue_free)

func _apply_poison_to_player() -> void:
	if not player or not is_instance_valid(player):
		return

	if player.has_method("apply_poison"):
		var total_damage = tongue_poison_damage * (tongue_poison_duration / 0.5)
		player.apply_poison(total_damage, tongue_poison_duration)
	elif player.has_method("apply_status_effect"):
		player.apply_status_effect("poison", tongue_poison_duration, tongue_poison_damage)
	else:
		# Fallback poison
		_apply_fallback_poison(tongue_poison_damage, tongue_poison_duration)

func _apply_fallback_poison(damage_per_tick: float, duration: float) -> void:
	var ticks = int(duration / 0.5)
	for i in range(ticks):
		var timer = get_tree().create_timer(0.5 * (i + 1))
		timer.timeout.connect(func():
			if player and is_instance_valid(player) and player.has_method("take_damage"):
				player.take_damage(damage_per_tick)
		)

# ============================================
# POISON POOL
# ============================================

func _start_poison_pool() -> void:
	pool_spit_active = true
	pool_windup_timer = POOL_WINDUP

	if player and is_instance_valid(player):
		pool_target_pos = player.global_position

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	_show_pool_indicator()

func _show_pool_indicator() -> void:
	_clear_pool_indicator()

	pool_indicator = Node2D.new()
	pool_indicator.global_position = pool_target_pos
	pool_indicator.z_index = -1

	var circle = ColorRect.new()
	circle.size = Vector2(pool_radius * 2, pool_radius * 2)
	circle.position = Vector2(-pool_radius, -pool_radius)
	circle.color = Color(0.3, 0.7, 0.2, 0.4)
	pool_indicator.add_child(circle)

	get_parent().add_child(pool_indicator)

	if pool_indicator_tween and pool_indicator_tween.is_valid():
		pool_indicator_tween.kill()

	pool_indicator_tween = create_tween().set_loops()
	pool_indicator_tween.tween_property(circle, "color:a", 0.2, 0.15)
	pool_indicator_tween.tween_property(circle, "color:a", 0.5, 0.15)

func _clear_pool_indicator() -> void:
	if pool_indicator_tween and pool_indicator_tween.is_valid():
		pool_indicator_tween.kill()
		pool_indicator_tween = null

	if pool_indicator and is_instance_valid(pool_indicator):
		pool_indicator.queue_free()
	pool_indicator = null

func _execute_poison_pool() -> void:
	_clear_pool_indicator()
	_spawn_poison_pool(pool_target_pos)

func _spawn_poison_pool(pos: Vector2) -> void:
	var pool = Node2D.new()
	pool.global_position = pos
	pool.z_index = -1
	pool.set_meta("is_poison_pool", true)
	pool.set_meta("damage", pool_damage)
	pool.set_meta("radius", pool_radius)

	var visual = ColorRect.new()
	visual.size = Vector2(pool_radius * 2, pool_radius * 2)
	visual.position = Vector2(-pool_radius, -pool_radius)
	visual.color = Color(0.3, 0.7, 0.2, 0.7)
	pool.add_child(visual)

	get_parent().add_child(pool)
	active_pools.append(pool)

	# Bubbling animation
	var bubble_tween = create_tween().set_loops()
	bubble_tween.tween_property(visual, "color:a", 0.5, 0.3)
	bubble_tween.tween_property(visual, "color:a", 0.7, 0.3)

	# Fade and remove after duration
	await get_tree().create_timer(pool_duration - 0.5).timeout

	if is_instance_valid(pool):
		bubble_tween.kill()
		var fade_tween = create_tween()
		fade_tween.tween_property(visual, "color:a", 0.0, 0.5)
		fade_tween.tween_callback(pool.queue_free)

		# Remove from tracking
		var idx = active_pools.find(pool)
		if idx >= 0:
			active_pools.remove_at(idx)

# ============================================
# MIASMA (Special Attack)
# ============================================

func _start_miasma() -> void:
	show_warning()
	is_using_special = true

	miasma_telegraphing = true
	miasma_telegraph_timer = miasma_telegraph_time
	special_timer = miasma_telegraph_time + miasma_duration + 0.5

	_show_miasma_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_miasma() -> void:
	miasma_telegraphing = false
	_hide_miasma_warning()

	miasma_active = true
	miasma_stack_count = 0
	miasma_damage_timer = 0.0

	# Create miasma cloud centered on elite
	_create_miasma_cloud()

	if JuiceManager:
		JuiceManager.shake_medium()

func _create_miasma_cloud() -> void:
	if miasma_cloud and is_instance_valid(miasma_cloud):
		miasma_cloud.queue_free()

	miasma_cloud = Node2D.new()
	miasma_cloud.z_index = 5
	add_child(miasma_cloud)

	var visual = ColorRect.new()
	visual.size = Vector2(miasma_radius * 2, miasma_radius * 2)
	visual.position = Vector2(-miasma_radius, -miasma_radius)
	visual.color = Color(0.2, 0.5, 0.1, 0.5)
	miasma_cloud.add_child(visual)

	# Swirling animation
	var swirl_tween = create_tween().set_loops()
	swirl_tween.tween_property(visual, "color:a", 0.3, 0.4)
	swirl_tween.tween_property(visual, "color:a", 0.6, 0.4)
	miasma_cloud.set_meta("swirl_tween", swirl_tween)

	# Schedule removal
	await get_tree().create_timer(miasma_duration).timeout

	if is_instance_valid(miasma_cloud):
		var stored_tween = miasma_cloud.get_meta("swirl_tween", null)
		if stored_tween and stored_tween.is_valid():
			stored_tween.kill()
		miasma_cloud.queue_free()
		miasma_cloud = null

	miasma_active = false

func _show_miasma_warning() -> void:
	if miasma_warning_label == null:
		miasma_warning_label = Label.new()
		miasma_warning_label.text = "MIASMA!"
		miasma_warning_label.add_theme_font_size_override("font_size", 18)
		miasma_warning_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.2, 1.0))
		miasma_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		miasma_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		miasma_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		miasma_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		miasma_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			miasma_warning_label.add_theme_font_override("font", pixel_font)

		add_child(miasma_warning_label)

	miasma_warning_label.position = Vector2(-40, -90)
	miasma_warning_label.visible = true

	if miasma_warning_tween and miasma_warning_tween.is_valid():
		miasma_warning_tween.kill()

	miasma_warning_tween = create_tween().set_loops()
	miasma_warning_tween.tween_property(miasma_warning_label, "modulate:a", 0.5, 0.15)
	miasma_warning_tween.tween_property(miasma_warning_label, "modulate:a", 1.0, 0.15)

func _hide_miasma_warning() -> void:
	if miasma_warning_tween and miasma_warning_tween.is_valid():
		miasma_warning_tween.kill()
		miasma_warning_tween = null
	if miasma_warning_label:
		miasma_warning_label.visible = false

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle tongue lash windup
	if tongue_lash_active:
		tongue_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if tongue_windup_timer <= 0:
			_execute_tongue_lash()
			tongue_lash_active = false
			can_attack = false
		return

	# Handle pool spit windup
	if pool_spit_active:
		pool_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if pool_windup_timer <= 0:
			_execute_poison_pool()
			pool_spit_active = false
			can_attack = false
		return

	# Check poison pool damage
	_check_pool_damage(delta)

	# Check miasma damage
	if miasma_active:
		_check_miasma_damage(delta)

	super._physics_process(delta)

func _check_pool_damage(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	for pool in active_pools:
		if not is_instance_valid(pool):
			continue

		var dist = player.global_position.distance_to(pool.global_position)
		var radius = pool.get_meta("radius", pool_radius)

		if dist < radius:
			var damage = pool.get_meta("damage", pool_damage)
			if player.has_method("take_damage"):
				player.take_damage(damage * delta)

func _check_miasma_damage(delta: float) -> void:
	if not player or not is_instance_valid(player):
		return

	var dist = player.global_position.distance_to(global_position)

	if dist < miasma_radius:
		miasma_damage_timer += delta

		# Damage every 0.5 seconds with stacking intensity
		if miasma_damage_timer >= 0.5:
			miasma_damage_timer = 0.0
			miasma_stack_count += 1

			# Stacking damage: base + (stack * multiplier)
			var current_damage = miasma_damage * (1.0 + miasma_stack_count * 0.25)

			if player.has_method("take_damage"):
				player.take_damage(current_damage)

			# Also apply poison
			_apply_fallback_poison(2.0, 2.0)

func _process_special_attack(delta: float) -> void:
	if miasma_telegraphing:
		miasma_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Pulsing green effect
		if sprite:
			var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.2
			sprite.modulate = Color(0.6 + pulse, 1.0, 0.5 + pulse, 1.0)

		if miasma_telegraph_timer <= 0:
			sprite.modulate = Color(0.8, 1.0, 0.7, 1.0)
			_execute_miasma()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_miasma()

func _end_miasma() -> void:
	miasma_telegraphing = false
	miasma_active = false
	hide_warning()
	_hide_miasma_warning()

	if miasma_cloud and is_instance_valid(miasma_cloud):
		miasma_cloud.queue_free()
		miasma_cloud = null

	if sprite:
		sprite.modulate = Color(0.8, 1.0, 0.7, 1.0)

func die() -> void:
	_end_miasma()
	_clear_pool_indicator()

	# Remove all pools
	for pool in active_pools:
		if is_instance_valid(pool):
			pool.queue_free()
	active_pools.clear()

	super.die()
