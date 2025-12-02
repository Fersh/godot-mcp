extends EliteBase

# Elite Imp - "Infernal Intern" - A demonic menace trying to prove itself
# Three attack types:
# 1. Fire Bolt - Fast triple-shot ranged projectile
# 2. Inferno - Creates fire patches on the ground in a pattern
# 3. Blink Strike - Teleports behind player and attacks
#
# Imp Sprite Sheet: 8 cols x 16 rows
# Row 0: Idle (4 frames)
# Row 2: Move (8 frames)
# Row 6: Attack (8 frames)
# Row 12: Damage (4 frames)
# Row 14: Death (6 frames)

@export var fire_projectile_scene: PackedScene

# Attack-specific stats
@export var fire_bolt_damage: float = 12.0
@export var fire_bolt_range: float = 320.0
@export var fire_bolt_speed: float = 220.0
@export var fire_bolt_count: int = 3

@export var inferno_damage: float = 8.0
@export var inferno_range: float = 280.0
@export var inferno_patch_count: int = 5
@export var inferno_telegraph_time: float = 1.0
@export var inferno_duration: float = 3.0

@export var blink_strike_damage: float = 20.0
@export var blink_strike_range: float = 350.0
@export var blink_strike_telegraph_time: float = 0.6

# Preferred range for ranged combat
var preferred_range: float = 200.0

# Attack state
var fire_bolt_active: bool = false
var fire_bolt_windup_timer: float = 0.0
var bolts_fired: int = 0
const FIRE_BOLT_WINDUP: float = 0.3
const BOLT_INTERVAL: float = 0.15

var inferno_telegraphing: bool = false
var inferno_telegraph_timer: float = 0.0
var inferno_warning_label: Label = null
var inferno_warning_tween: Tween = null
var inferno_indicators: Array[Node2D] = []
var inferno_indicator_tweens: Array[Tween] = []
var inferno_target_positions: Array[Vector2] = []

var blink_strike_active: bool = false
var blink_strike_telegraphing: bool = false
var blink_strike_telegraph_timer: float = 0.0
var blink_target_pos: Vector2 = Vector2.ZERO
var blink_strike_warning_label: Label = null
var blink_strike_warning_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "Infernal Intern"
	enemy_type = "imp_elite"

	# Stats - glass cannon
	speed = 60.0
	max_health = 500.0  # Low HP for glass cannon
	attack_damage = fire_bolt_damage
	attack_cooldown = 1.0
	windup_duration = 0.4
	animation_speed = 10.0

	# Imp spritesheet: 8 cols x 16 rows
	ROW_IDLE = 0
	ROW_MOVE = 2
	ROW_ATTACK = 6
	ROW_DAMAGE = 12
	ROW_DEATH = 14
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		2: 8,   # MOVE
		6: 8,   # ATTACK
		12: 4,  # DAMAGE
		14: 6,  # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up the sprite for elite size
	if sprite:
		sprite.scale = Vector2(3.0, 3.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.RANGED,
			"name": "fire_bolt",
			"range": fire_bolt_range,
			"cooldown": 3.0,
			"priority": 5
		},
		{
			"type": AttackType.SPECIAL,
			"name": "inferno",
			"range": inferno_range,
			"cooldown": 10.0,
			"priority": 4
		},
		{
			"type": AttackType.MELEE,
			"name": "blink_strike",
			"range": blink_strike_range,
			"cooldown": 8.0,
			"priority": 6
		}
	]

# Override behavior for ranged combat - maintain distance
func _process_behavior(delta: float) -> void:
	if is_using_special or blink_strike_active or blink_strike_telegraphing:
		_process_special_attack(delta)
		return

	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position)
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Select best attack based on distance and cooldowns
		var best_attack = _select_best_attack(distance)

		if best_attack.is_empty():
			# No attack available, maintain preferred range
			if distance < preferred_range * 0.7:
				velocity = -dir_normalized * speed
				move_and_slide()
				update_animation(delta, ROW_MOVE, -dir_normalized)
			elif distance > preferred_range * 1.3:
				velocity = dir_normalized * speed
				move_and_slide()
				update_animation(delta, ROW_MOVE, dir_normalized)
			else:
				velocity = Vector2.ZERO
				update_animation(delta, ROW_IDLE, dir_normalized)
		elif distance > best_attack.range:
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			velocity = Vector2.ZERO
			if can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_IDLE, dir_normalized)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"fire_bolt":
			_start_fire_bolt()
		"inferno":
			_start_inferno()
		"blink_strike":
			_start_blink_strike()

func _start_fire_bolt() -> void:
	fire_bolt_active = true
	fire_bolt_windup_timer = FIRE_BOLT_WINDUP
	bolts_fired = 0
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_inferno() -> void:
	show_warning()
	is_using_special = true

	inferno_telegraphing = true
	inferno_telegraph_timer = inferno_telegraph_time
	special_timer = inferno_telegraph_time + inferno_duration + 0.5

	# Generate target positions in a pattern around player
	inferno_target_positions.clear()
	if player and is_instance_valid(player):
		var center = player.global_position
		for i in range(inferno_patch_count):
			var angle = (TAU / inferno_patch_count) * i
			var distance = randf_range(40, 120)
			var offset = Vector2(cos(angle), sin(angle)) * distance
			inferno_target_positions.append(center + offset)

	_show_inferno_warning()
	_show_inferno_indicators()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_blink_strike() -> void:
	show_warning()
	blink_strike_telegraphing = true
	blink_strike_telegraph_timer = blink_strike_telegraph_time

	# Target position behind player
	if player and is_instance_valid(player):
		var player_facing = Vector2.RIGHT  # Default
		if player.has_method("get_facing_direction"):
			player_facing = player.get_facing_direction()
		elif "velocity" in player and player.velocity.length() > 0:
			player_facing = player.velocity.normalized()

		# Teleport behind the player
		blink_target_pos = player.global_position - player_facing * 60

	_show_blink_strike_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_inferno() -> void:
	inferno_telegraphing = false
	_hide_inferno_warning()
	_clear_inferno_indicators()

	# Spawn fire patches at each target position
	for pos in inferno_target_positions:
		_spawn_fire_patch(pos)

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_fire_patch(pos: Vector2) -> void:
	var patch = Node2D.new()
	patch.global_position = pos
	patch.z_index = -1

	var visual = ColorRect.new()
	visual.size = Vector2(50, 50)
	visual.position = Vector2(-25, -25)
	visual.color = Color(1.0, 0.4, 0.1, 0.7)
	patch.add_child(visual)

	get_parent().add_child(patch)

	# Pulsing fire effect
	var pulse_tween = create_tween().set_loops()
	pulse_tween.tween_property(visual, "color:a", 0.4, 0.2)
	pulse_tween.tween_property(visual, "color:a", 0.8, 0.2)

	# Damage check timer
	var damage_interval = 0.5
	var time_elapsed = 0.0

	# Create a script for the fire patch damage
	var damage_timer = Timer.new()
	damage_timer.wait_time = damage_interval
	damage_timer.autostart = true
	patch.add_child(damage_timer)

	damage_timer.timeout.connect(func():
		if player and is_instance_valid(player):
			var dist = player.global_position.distance_to(pos)
			if dist < 35:  # In fire
				if player.has_method("take_damage"):
					player.take_damage(inferno_damage)
	)

	# Remove after duration
	var remove_timer = get_tree().create_timer(inferno_duration)
	remove_timer.timeout.connect(func():
		if pulse_tween and pulse_tween.is_valid():
			pulse_tween.kill()
		if is_instance_valid(patch):
			patch.queue_free()
	)

func _execute_blink_strike() -> void:
	blink_strike_telegraphing = false
	_hide_blink_strike_warning()
	hide_warning()

	# Teleport to target position
	global_position = blink_target_pos

	# Visual effect - brief flash
	if sprite:
		sprite.modulate = Color(1.5, 0.5, 0.5)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1, 1, 1), 0.2)

	# Immediate melee attack
	blink_strike_active = true
	_execute_blink_melee()

func _execute_blink_melee() -> void:
	blink_strike_active = false
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= 80:  # Close melee range after blink
			if player.has_method("take_damage"):
				player.take_damage(blink_strike_damage)
				_on_elite_attack_hit(blink_strike_damage)

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _show_inferno_warning() -> void:
	if inferno_warning_label == null:
		inferno_warning_label = Label.new()
		inferno_warning_label.text = "INFERNO!"
		inferno_warning_label.add_theme_font_size_override("font_size", 14)
		inferno_warning_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.1, 1.0))
		inferno_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		inferno_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		inferno_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		inferno_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		inferno_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			inferno_warning_label.add_theme_font_override("font", pixel_font)

		add_child(inferno_warning_label)

	inferno_warning_label.position = Vector2(-40, -80)
	inferno_warning_label.visible = true

	if inferno_warning_tween and inferno_warning_tween.is_valid():
		inferno_warning_tween.kill()

	inferno_warning_tween = create_tween().set_loops()
	inferno_warning_tween.tween_property(inferno_warning_label, "modulate:a", 0.5, 0.12)
	inferno_warning_tween.tween_property(inferno_warning_label, "modulate:a", 1.0, 0.12)

func _hide_inferno_warning() -> void:
	if inferno_warning_tween and inferno_warning_tween.is_valid():
		inferno_warning_tween.kill()
		inferno_warning_tween = null
	if inferno_warning_label:
		inferno_warning_label.visible = false

func _show_inferno_indicators() -> void:
	_clear_inferno_indicators()

	for pos in inferno_target_positions:
		var indicator = Node2D.new()
		indicator.global_position = pos
		indicator.z_index = 5

		var circle = ColorRect.new()
		circle.size = Vector2(50, 50)
		circle.position = Vector2(-25, -25)
		circle.color = Color(1.0, 0.4, 0.1, 0.4)
		indicator.add_child(circle)

		get_parent().add_child(indicator)
		inferno_indicators.append(indicator)

		var tween = create_tween().set_loops()
		tween.tween_property(circle, "color:a", 0.2, 0.15)
		tween.tween_property(circle, "color:a", 0.5, 0.15)
		inferno_indicator_tweens.append(tween)

func _clear_inferno_indicators() -> void:
	for tween in inferno_indicator_tweens:
		if tween and tween.is_valid():
			tween.kill()
	inferno_indicator_tweens.clear()

	for indicator in inferno_indicators:
		if is_instance_valid(indicator):
			indicator.queue_free()
	inferno_indicators.clear()

func _show_blink_strike_warning() -> void:
	if blink_strike_warning_label == null:
		blink_strike_warning_label = Label.new()
		blink_strike_warning_label.text = "BLINK!"
		blink_strike_warning_label.add_theme_font_size_override("font_size", 14)
		blink_strike_warning_label.add_theme_color_override("font_color", Color(0.8, 0.3, 1.0, 1.0))
		blink_strike_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		blink_strike_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		blink_strike_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		blink_strike_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		blink_strike_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			blink_strike_warning_label.add_theme_font_override("font", pixel_font)

		add_child(blink_strike_warning_label)

	blink_strike_warning_label.position = Vector2(-30, -80)
	blink_strike_warning_label.visible = true

	if blink_strike_warning_tween and blink_strike_warning_tween.is_valid():
		blink_strike_warning_tween.kill()

	blink_strike_warning_tween = create_tween().set_loops()
	blink_strike_warning_tween.tween_property(blink_strike_warning_label, "modulate:a", 0.5, 0.1)
	blink_strike_warning_tween.tween_property(blink_strike_warning_label, "modulate:a", 1.0, 0.1)

func _hide_blink_strike_warning() -> void:
	if blink_strike_warning_tween and blink_strike_warning_tween.is_valid():
		blink_strike_warning_tween.kill()
		blink_strike_warning_tween = null
	if blink_strike_warning_label:
		blink_strike_warning_label.visible = false

func _physics_process(delta: float) -> void:
	# Handle fire bolt
	if fire_bolt_active:
		fire_bolt_windup_timer -= delta

		if fire_bolt_windup_timer <= 0 and bolts_fired < fire_bolt_count:
			_execute_fire_bolt()
			bolts_fired += 1
			fire_bolt_windup_timer = BOLT_INTERVAL

		if bolts_fired >= fire_bolt_count:
			fire_bolt_active = false
			can_attack = false

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 8)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames
		if dir.x != 0:
			sprite.flip_h = dir.x < 0
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	# Handle inferno telegraph
	if inferno_telegraphing:
		inferno_telegraph_timer -= delta

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

		if inferno_telegraph_timer <= 0:
			_execute_inferno()
		return

	# Handle blink strike telegraph
	if blink_strike_telegraphing:
		blink_strike_telegraph_timer -= delta

		# Flicker effect during telegraph
		if sprite:
			sprite.modulate.a = 0.5 + sin(Time.get_ticks_msec() * 0.03) * 0.5

		if blink_strike_telegraph_timer <= 0:
			if sprite:
				sprite.modulate.a = 1.0
			_execute_blink_strike()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_inferno()

func _end_inferno() -> void:
	inferno_telegraphing = false
	hide_warning()
	_hide_inferno_warning()
	_clear_inferno_indicators()

func _execute_fire_bolt() -> void:
	if not player or not is_instance_valid(player):
		return

	# Calculate direction with slight spread for triple shot
	var base_direction = (player.global_position - global_position).normalized()
	var spread_angles = [-0.15, 0.0, 0.15]
	var spread_angle = spread_angles[bolts_fired % 3]
	var direction = base_direction.rotated(spread_angle)

	# Use fire projectile scene or fall back to enemy projectile
	var proj_scene = fire_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 30
		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = fire_bolt_speed
		if "damage" in proj:
			proj.damage = fire_bolt_damage

		# Fire-colored tint
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(1.0, 0.5, 0.2)

		get_parent().add_child(proj)

func die() -> void:
	_end_inferno()
	_hide_blink_strike_warning()
	super.die()
