extends EliteBase

# Elite Bat - "Dreadwing the Eclipsed"
# A terrifying giant bat with devastating speed and swarm attacks
# Inspired by Vampire Survivors bat swarms and Diablo Butcher charge
#
# Three attack types:
# 1. Sonic Screech - Cone damage in front, stuns briefly
# 2. Swooping Blitz - Multiple rapid dive attacks at player
# 3. Summon Swarm - Spawns smaller bats that orbit and attack independently
#
# Bat Sprite Sheet: 5 cols x 3 rows, 16x24 per frame
# Row 0: Idle/Move (5 frames) - flapping
# Row 1: Damage (5 frames)
# Row 2: Death (5 frames)

@export var mini_bat_scene: PackedScene

# Attack-specific stats
@export var screech_damage: float = 18.0
@export var screech_range: float = 150.0
@export var screech_cone_angle: float = 60.0  # Degrees

@export var blitz_damage: float = 15.0
@export var blitz_range: float = 200.0
@export var blitz_speed: float = 600.0
@export var blitz_count: int = 3

@export var swarm_count: int = 5
@export var swarm_telegraph_time: float = 1.0
@export var swarm_range: float = 250.0

# Attack states
var screech_active: bool = false
var screech_windup_timer: float = 0.0
const SCREECH_WINDUP: float = 0.4

var blitz_active: bool = false
var blitz_windup_timer: float = 0.0
const BLITZ_WINDUP: float = 0.25
var current_blitz_count: int = 0
var is_blitzing: bool = false
var blitz_target: Vector2 = Vector2.ZERO

var swarm_telegraphing: bool = false
var swarm_telegraph_timer: float = 0.0
var swarm_warning_label: Label = null
var swarm_warning_tween: Tween = null
var active_swarm_bats: Array[Node] = []

# base_speed is inherited from EnemyBase

func _setup_elite() -> void:
	elite_name = "Dreadwing the Eclipsed"
	enemy_type = "bat_elite"

	# Stats - extremely fast and aggressive
	speed = 180.0  # Very fast
	base_speed = speed
	max_health = 480.0  # Lower HP but hard to hit
	attack_damage = blitz_damage
	attack_cooldown = 0.6
	windup_duration = 0.2
	animation_speed = 20.0  # Fast flapping

	# Bat spritesheet: 5 cols x 3 rows
	ROW_IDLE = 0
	ROW_MOVE = 0
	ROW_ATTACK = 0
	ROW_DAMAGE = 1
	ROW_DEATH = 2
	COLS_PER_ROW = 5

	FRAME_COUNTS = {
		0: 5,   # IDLE/MOVE/ATTACK
		1: 5,   # DAMAGE
		2: 5,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - HUGE bat
	if sprite:
		sprite.scale = Vector2(6.0, 6.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "sonic_screech",
			"range": screech_range,
			"cooldown": 5.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "swooping_blitz",
			"range": blitz_range,
			"cooldown": 7.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "summon_swarm",
			"range": swarm_range,
			"cooldown": 15.0,
			"priority": 7
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"sonic_screech":
			_start_sonic_screech()
		"swooping_blitz":
			_start_swooping_blitz()
		"summon_swarm":
			_start_summon_swarm()

# ============================================
# SONIC SCREECH
# ============================================

func _start_sonic_screech() -> void:
	screech_active = true
	screech_windup_timer = SCREECH_WINDUP
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	# Show screech cone indicator
	_show_screech_indicator(dir)

func _show_screech_indicator(direction: Vector2) -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1
	indicator.rotation = direction.angle()

	# Create cone shape using polygon
	var polygon = Polygon2D.new()
	var half_angle = deg_to_rad(screech_cone_angle / 2.0)
	var points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(screech_range, 0).rotated(-half_angle),
		Vector2(screech_range, 0).rotated(half_angle)
	])
	polygon.polygon = points
	polygon.color = Color(0.5, 0.2, 0.8, 0.3)
	indicator.add_child(polygon)

	get_parent().add_child(indicator)

	# Pulse and remove
	var tween = create_tween()
	tween.tween_property(polygon, "color:a", 0.6, SCREECH_WINDUP * 0.8)
	tween.tween_property(polygon, "color:a", 0.0, 0.15)
	tween.tween_callback(indicator.queue_free)

func _execute_sonic_screech() -> void:
	hide_warning()

	if not player or not is_instance_valid(player):
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	# Check if player is in cone
	if distance <= screech_range:
		var facing = Vector2.RIGHT
		if sprite and sprite.flip_h:
			facing = Vector2.LEFT

		# Calculate angle to player
		var angle_to_player = abs(facing.angle_to(direction))
		var half_cone = deg_to_rad(screech_cone_angle / 2.0)

		if angle_to_player <= half_cone:
			if player.has_method("take_damage"):
				player.take_damage(screech_damage)
				_on_elite_attack_hit(screech_damage)

			# Brief stun/slow effect
			if player.has_method("apply_slow"):
				player.apply_slow(0.3, 1.0)

	# Visual screech wave
	_spawn_screech_wave()

	if JuiceManager:
		JuiceManager.shake_small()

	# Play screech sound if available
	if SoundManager and SoundManager.has_method("play_enemy_screech"):
		SoundManager.play_enemy_screech()

func _spawn_screech_wave() -> void:
	var wave = Node2D.new()
	wave.global_position = global_position
	wave.z_index = 10

	var facing_dir = Vector2.RIGHT
	if sprite and sprite.flip_h:
		facing_dir = Vector2.LEFT
	wave.rotation = facing_dir.angle()

	var visual = ColorRect.new()
	visual.size = Vector2(30, 80)
	visual.position = Vector2(0, -40)
	visual.color = Color(0.5, 0.2, 0.8, 0.8)
	wave.add_child(visual)

	get_parent().add_child(wave)

	# Expand outward
	var tween = create_tween()
	tween.tween_property(visual, "size:x", screech_range, 0.2)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.3)
	tween.tween_callback(wave.queue_free)

# ============================================
# SWOOPING BLITZ
# ============================================

func _start_swooping_blitz() -> void:
	blitz_active = true
	current_blitz_count = 0
	show_warning()
	_execute_single_blitz()

func _execute_single_blitz() -> void:
	if not player or not is_instance_valid(player) or is_dying:
		blitz_active = false
		hide_warning()
		return

	current_blitz_count += 1
	is_blitzing = true

	# Lock target position
	blitz_target = player.global_position

	# Brief pause before dive
	blitz_windup_timer = BLITZ_WINDUP

func _perform_blitz_dive() -> void:
	if is_dying:
		return

	var direction = (blitz_target - global_position).normalized()
	var distance = global_position.distance_to(blitz_target)

	# Tween to target
	var dive_time = distance / blitz_speed
	var tween = create_tween()
	tween.tween_property(self, "global_position", blitz_target, dive_time)
	tween.tween_callback(_on_blitz_complete)

	# Update facing
	if sprite:
		sprite.flip_h = direction.x < 0

func _on_blitz_complete() -> void:
	is_blitzing = false

	# Check for damage at landing
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= 60:
			if player.has_method("take_damage"):
				player.take_damage(blitz_damage)
				_on_elite_attack_hit(blitz_damage)

	if JuiceManager:
		JuiceManager.shake_small()

	# More blitzes to do?
	if current_blitz_count < blitz_count and not is_dying:
		# Short delay between blitzes
		await get_tree().create_timer(0.3).timeout
		if not is_dying:
			_execute_single_blitz()
	else:
		blitz_active = false
		hide_warning()
		can_attack = false

# ============================================
# SUMMON SWARM (Special Attack)
# ============================================

func _start_summon_swarm() -> void:
	show_warning()
	is_using_special = true

	swarm_telegraphing = true
	swarm_telegraph_timer = swarm_telegraph_time
	special_timer = swarm_telegraph_time + 0.5

	_show_swarm_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_summon_swarm() -> void:
	swarm_telegraphing = false
	_hide_swarm_warning()

	# Clean up any existing swarm
	for bat in active_swarm_bats:
		if is_instance_valid(bat):
			bat.queue_free()
	active_swarm_bats.clear()

	# Spawn mini bats in a circle
	for i in range(swarm_count):
		var angle = (TAU / swarm_count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 80
		_spawn_swarm_bat(global_position + offset, i)

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_swarm_bat(spawn_pos: Vector2, index: int) -> void:
	# Use mini bat scene or create simple one
	var bat_scene = mini_bat_scene
	if bat_scene == null:
		bat_scene = load("res://scenes/enemy_bat.tscn")

	if bat_scene:
		var bat = bat_scene.instantiate()
		bat.global_position = spawn_pos
		get_parent().add_child(bat)

		# Make it a weaker swarm bat
		if bat.has_method("_on_ready"):
			bat._on_ready()

		bat.max_health = 15.0
		bat.current_health = 15.0
		bat.attack_damage = 5.0
		bat.speed = 120.0

		# Visual distinction - darker and smaller
		if bat.has_node("Sprite"):
			var bat_sprite = bat.get_node("Sprite")
			bat_sprite.modulate = Color(0.5, 0.3, 0.6, 1.0)
			bat_sprite.scale = Vector2(1.8, 1.8)
		elif bat.has_node("Sprite2D"):
			var bat_sprite = bat.get_node("Sprite2D")
			bat_sprite.modulate = Color(0.5, 0.3, 0.6, 1.0)
			bat_sprite.scale = Vector2(1.8, 1.8)

		active_swarm_bats.append(bat)

func _show_swarm_warning() -> void:
	if swarm_warning_label == null:
		swarm_warning_label = Label.new()
		swarm_warning_label.text = "SWARM!"
		swarm_warning_label.add_theme_font_size_override("font_size", 18)
		swarm_warning_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.8, 1.0))
		swarm_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		swarm_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		swarm_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		swarm_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		swarm_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			swarm_warning_label.add_theme_font_override("font", pixel_font)

		add_child(swarm_warning_label)

	swarm_warning_label.position = Vector2(-35, -100)
	swarm_warning_label.visible = true

	if swarm_warning_tween and swarm_warning_tween.is_valid():
		swarm_warning_tween.kill()

	swarm_warning_tween = create_tween().set_loops()
	swarm_warning_tween.tween_property(swarm_warning_label, "modulate:a", 0.5, 0.12)
	swarm_warning_tween.tween_property(swarm_warning_label, "modulate:a", 1.0, 0.12)

func _hide_swarm_warning() -> void:
	if swarm_warning_tween and swarm_warning_tween.is_valid():
		swarm_warning_tween.kill()
		swarm_warning_tween = null
	if swarm_warning_label:
		swarm_warning_label.visible = false

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle screech windup
	if screech_active:
		screech_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 5)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if screech_windup_timer <= 0:
			_execute_sonic_screech()
			screech_active = false
			can_attack = false
		return

	# Handle blitz windup
	if blitz_active and not is_blitzing:
		blitz_windup_timer -= delta
		if blitz_windup_timer <= 0:
			_perform_blitz_dive()
		return

	# Handle blitz movement
	if is_blitzing:
		# Animation during blitz
		var dir = (blitz_target - global_position).normalized()
		animation_frame += animation_speed * 1.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 5)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if swarm_telegraphing:
		swarm_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 5)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Pulsing effect
		if sprite:
			var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.015) * 0.1
			sprite.scale = Vector2(6.0, 6.0) * pulse

		if swarm_telegraph_timer <= 0:
			if sprite:
				sprite.scale = Vector2(6.0, 6.0)
			_execute_summon_swarm()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_swarm()

func _end_swarm() -> void:
	swarm_telegraphing = false
	hide_warning()
	_hide_swarm_warning()
	if sprite:
		sprite.scale = Vector2(6.0, 6.0)

func die() -> void:
	_end_swarm()
	blitz_active = false
	is_blitzing = false

	# Kill swarm bats when elite dies
	for bat in active_swarm_bats:
		if is_instance_valid(bat) and bat.has_method("take_damage"):
			bat.take_damage(bat.max_health)
	active_swarm_bats.clear()

	super.die()
