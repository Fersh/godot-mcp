extends EliteBase

# Goblin King Elite - Large goblin with three attack types:
# 1. Stomp - Close range AOE ground slam
# 2. Coin Bag Throw - Ranged projectile that explodes on contact/landing
# 3. Gold Rain - Special attack, rains multiple coin bags in area around player
#
# Sprite Sheet: 16 cols x 11 rows, 64x64 per frame
# Row 0: idle (4 frames)
# Row 1: movement (6 frames)
# Row 2: panic (8 frames) - plays when health < 35%
# Row 3: ready ranged attack (12 frames)
# Row 4: throw ranged attack (8 frames)
# Row 5-6: eat (16 frames) - idle variation, not used for attack
# Row 7: take damage (4 frames)
# Row 8: death (11 frames)

@export var coin_bag_projectile_scene: PackedScene

# Attack-specific stats
@export var stomp_damage: float = 20.0  # Reduced from 35
@export var stomp_range: float = 80.0
@export var stomp_aoe_radius: float = 100.0

@export var coin_bag_damage: float = 25.0
@export var coin_bag_range: float = 280.0
@export var coin_bag_speed: float = 180.0

# Gold Rain special attack
@export var gold_rain_damage: float = 20.0
@export var gold_rain_range: float = 300.0
@export var gold_rain_telegraph_time: float = 1.2
@export var gold_rain_bag_count: int = 5
@export var gold_rain_area_radius: float = 120.0

# Animation rows for Goblin King spritesheet
var ROW_PANIC: int = 2
var ROW_READY_RANGED: int = 3
var ROW_THROW: int = 4
var ROW_EAT: int = 5
var ROW_STOMP: int = 3  # Use ready ranged for stomp windup visually

# Special attack state (Gold Rain)
var gold_rain_active: bool = false
var gold_rain_telegraphing: bool = false
var gold_rain_telegraph_timer: float = 0.0
var gold_rain_target_pos: Vector2 = Vector2.ZERO
var gold_rain_warning_label: Label = null
var gold_rain_indicators: Array[Node2D] = []

# Stomp state
var stomp_active: bool = false
var stomp_windup_timer: float = 0.0
const STOMP_WINDUP: float = 0.7

# Throw state
var throw_active: bool = false
var throw_windup_timer: float = 0.0
const THROW_WINDUP: float = 0.5

# Panic state
var is_panicking: bool = false
const PANIC_HEALTH_THRESHOLD: float = 0.35  # 35% health

# Target positions for gold rain
var gold_rain_targets: Array[Vector2] = []

func _setup_elite() -> void:
	elite_name = "Goblin King"
	enemy_type = "goblin_king"

	# Goblin King stats - tankier and slower than Cyclops
	speed = 40.5  # Slower than Cyclops (reduced 20%)
	max_health = 800.0  # More HP than Cyclops (675)
	attack_damage = stomp_damage
	attack_cooldown = 1.0
	windup_duration = 0.5
	animation_speed = 8.0

	# Goblin King spritesheet: 16 cols x 11 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_PANIC = 2
	ROW_READY_RANGED = 3
	ROW_THROW = 4
	ROW_EAT = 5
	ROW_DAMAGE = 7
	ROW_DEATH = 8
	ROW_ATTACK = 3  # Use ready ranged for stomp
	ROW_STOMP = 3
	COLS_PER_ROW = 16

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 6,   # MOVE
		2: 8,   # PANIC
		3: 12,  # READY RANGED / STOMP
		4: 8,   # THROW
		5: 16,  # EAT (spans to row 6)
		6: 0,   # EAT continued
		7: 4,   # DAMAGE
		8: 11,  # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "stomp",
			"range": stomp_range,
			"cooldown": 3.5,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "coin_bag_throw",
			"range": coin_bag_range,
			"cooldown": 4.5,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "gold_rain",
			"range": gold_rain_range,
			"cooldown": 10.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"stomp":
			_start_stomp()
		"coin_bag_throw":
			_start_coin_bag_throw()
		"gold_rain":
			_start_gold_rain()

func _start_stomp() -> void:
	stomp_active = true
	stomp_windup_timer = STOMP_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_STOMP, dir)
	animation_frame = 0

func _start_coin_bag_throw() -> void:
	throw_active = true
	throw_windup_timer = THROW_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_THROW, dir)
	animation_frame = 0

func _start_gold_rain() -> void:
	show_warning()
	is_using_special = true

	# Start telegraph phase
	gold_rain_telegraphing = true
	gold_rain_telegraph_timer = gold_rain_telegraph_time
	special_timer = gold_rain_telegraph_time + 1.0  # Extra time for bags to land

	if player and is_instance_valid(player):
		gold_rain_target_pos = player.global_position

	# Generate random target positions around the player
	gold_rain_targets.clear()
	for i in range(gold_rain_bag_count):
		var offset = Vector2(
			randf_range(-gold_rain_area_radius, gold_rain_area_radius),
			randf_range(-gold_rain_area_radius, gold_rain_area_radius)
		)
		gold_rain_targets.append(gold_rain_target_pos + offset)

	# Show warning and indicators
	_show_gold_rain_warning()
	_show_gold_rain_indicators()

	# Use ready ranged animation during telegraph
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_READY_RANGED, dir)
	animation_frame = 0

func _execute_gold_rain() -> void:
	# Called after telegraph finishes - throw all coin bags
	gold_rain_telegraphing = false
	gold_rain_active = false

	# Hide warning and indicators
	_hide_gold_rain_warning()
	_clear_gold_rain_indicators()

	# Throw coin bags at each target position
	if coin_bag_projectile_scene == null:
		return

	for target_pos in gold_rain_targets:
		var projectile = coin_bag_projectile_scene.instantiate()
		projectile.global_position = global_position + Vector2(0, -40)  # Throw from above head

		var direction = (target_pos - global_position).normalized()
		projectile.direction = direction
		projectile.speed = coin_bag_speed * 1.2  # Slightly faster for rain
		projectile.damage = gold_rain_damage
		projectile.target_position = target_pos

		get_parent().add_child(projectile)

		# Small delay between throws for visual effect
		await get_tree().create_timer(0.08).timeout

func _show_gold_rain_warning() -> void:
	if gold_rain_warning_label == null:
		gold_rain_warning_label = Label.new()
		gold_rain_warning_label.text = "GOLD RAIN!"
		gold_rain_warning_label.add_theme_font_size_override("font_size", 14)
		gold_rain_warning_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
		gold_rain_warning_label.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0, 1))
		gold_rain_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		gold_rain_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		gold_rain_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		gold_rain_warning_label.z_index = 100

		# Load pixel font if available
		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			gold_rain_warning_label.add_theme_font_override("font", pixel_font)

		add_child(gold_rain_warning_label)

	gold_rain_warning_label.position = Vector2(-50, -90)
	gold_rain_warning_label.visible = true

	# Pulsing animation
	var tween = create_tween().set_loops()
	tween.tween_property(gold_rain_warning_label, "modulate:a", 0.5, 0.15)
	tween.tween_property(gold_rain_warning_label, "modulate:a", 1.0, 0.15)

func _hide_gold_rain_warning() -> void:
	if gold_rain_warning_label:
		gold_rain_warning_label.visible = false

func _show_gold_rain_indicators() -> void:
	# Show warning circles at each target position
	_clear_gold_rain_indicators()

	for target_pos in gold_rain_targets:
		var indicator = Node2D.new()
		indicator.global_position = target_pos
		indicator.z_index = 5

		# Create warning circle
		var circle = ColorRect.new()
		circle.size = Vector2(50, 50)
		circle.position = Vector2(-25, -25)
		circle.color = Color(1.0, 0.85, 0.2, 0.4)  # Gold, semi-transparent
		indicator.add_child(circle)

		get_parent().add_child(indicator)
		gold_rain_indicators.append(indicator)

		# Pulsing animation for indicator
		var tween = create_tween().set_loops()
		tween.tween_property(circle, "color:a", 0.2, 0.2)
		tween.tween_property(circle, "color:a", 0.5, 0.2)

func _clear_gold_rain_indicators() -> void:
	for indicator in gold_rain_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	gold_rain_indicators.clear()

func _physics_process(delta: float) -> void:
	# Check for panic state based on health
	_check_panic_state()

	# Handle stomp windup
	if stomp_active:
		stomp_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		# Animate stomp
		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_STOMP, 12)
		sprite.frame = ROW_STOMP * COLS_PER_ROW + int(animation_frame) % max_frames

		if stomp_windup_timer <= 0:
			_execute_stomp()
			stomp_active = false
			can_attack = false
		return

	# Handle throw windup
	if throw_active:
		throw_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		# Animate throw
		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_THROW, 8)
		sprite.frame = ROW_THROW * COLS_PER_ROW + int(animation_frame) % max_frames

		if throw_windup_timer <= 0:
			_execute_coin_bag_throw()
			throw_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _check_panic_state() -> void:
	var health_percent = current_health / max_health
	is_panicking = health_percent <= PANIC_HEALTH_THRESHOLD

func _process_special_attack(delta: float) -> void:
	# Handle telegraph phase for gold rain
	if gold_rain_telegraphing:
		gold_rain_telegraph_timer -= delta

		# Animate during telegraph
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_READY_RANGED, 12)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_READY_RANGED * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Telegraph finished - execute gold rain
		if gold_rain_telegraph_timer <= 0:
			_execute_gold_rain()
		return

func _end_gold_rain() -> void:
	gold_rain_active = false
	gold_rain_telegraphing = false
	hide_warning()
	_hide_gold_rain_warning()
	_clear_gold_rain_indicators()

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_gold_rain()

func _execute_stomp() -> void:
	# AOE damage around goblin king
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= stomp_aoe_radius:
			if player.has_method("take_damage"):
				player.take_damage(stomp_damage)

	# Screen shake for impact
	if JuiceManager:
		JuiceManager.shake_large()

func _execute_coin_bag_throw() -> void:
	if coin_bag_projectile_scene == null or player == null or not is_instance_valid(player):
		return

	var projectile = coin_bag_projectile_scene.instantiate()
	projectile.global_position = global_position + Vector2(0, -25)  # Throw from above head

	var direction = (player.global_position - global_position).normalized()
	projectile.direction = direction
	projectile.speed = coin_bag_speed
	projectile.damage = coin_bag_damage
	projectile.target_position = player.global_position

	get_parent().add_child(projectile)

# Override animation to use panic animation when health is low
func update_animation(delta: float, row: int, direction: Vector2) -> void:
	# Use panic animation when health is low and not attacking
	if is_panicking and row == ROW_IDLE:
		row = ROW_PANIC
	elif is_panicking and row == ROW_MOVE:
		row = ROW_PANIC

	super.update_animation(delta, row, direction)

# Override to handle cleanup
func die() -> void:
	_end_gold_rain()
	super.die()
