extends EliteBase

# Elite Intellect Devourer - "The Mind Ripper"
# A massive brain creature that assaults the player's abilities
# Inspired by Hades Asterius and WoW C'thun
#
# Three attack types:
# 1. Psychic Claw - Melee with ability drain
# 2. Mind Blast - Ranged cone that confuses movement controls
# 3. Brain Drain - Special channel that steals HP and silences
#
# Intellect Devourer Sprite Sheet: 8 cols x 6 rows, 32x32 per frame
# Row 0: Idle (4 frames)
# Row 1: Movement (8 frames)
# Row 2: Attack (6 frames)
# Row 3: Intellect Devour (8 frames) - Special
# Row 4: Damage (4 frames)
# Row 5: Death (4 frames)

# Attack-specific stats
@export var claw_damage: float = 22.0
@export var claw_range: float = 70.0
@export var claw_silence_duration: float = 2.0

@export var mind_blast_damage: float = 15.0
@export var mind_blast_range: float = 200.0
@export var mind_blast_cone_angle: float = 50.0
@export var confusion_duration: float = 3.0

@export var brain_drain_damage: float = 8.0  # Per second
@export var brain_drain_heal: float = 6.0  # Per second
@export var brain_drain_range: float = 180.0
@export var brain_drain_telegraph_time: float = 1.0
@export var brain_drain_duration: float = 4.0
@export var brain_drain_silence_duration: float = 3.0

# Animation rows
var ROW_DEVOUR: int = 3

# Attack states
var claw_active: bool = false
var claw_windup_timer: float = 0.0
const CLAW_WINDUP: float = 0.35

var mind_blast_active: bool = false
var mind_blast_windup_timer: float = 0.0
const MIND_BLAST_WINDUP: float = 0.5

var brain_drain_active: bool = false
var brain_drain_channeling: bool = false
var brain_drain_telegraphing: bool = false
var brain_drain_telegraph_timer: float = 0.0
var brain_drain_channel_timer: float = 0.0
var brain_drain_line: Line2D = null
var brain_drain_warning_label: Label = null
var brain_drain_warning_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "The Mind Ripper"
	enemy_type = "intellect_devourer_elite"

	# Stats - fast, disruptive, moderate tankiness
	speed = 72.0  # Fast
	max_health = 620.0
	attack_damage = claw_damage
	attack_cooldown = 0.9
	windup_duration = 0.35
	animation_speed = 11.0

	# Intellect Devourer spritesheet: 8 cols x 6 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DEVOUR = 3
	ROW_DAMAGE = 4
	ROW_DEATH = 5
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 6,   # ATTACK
		3: 8,   # DEVOUR
		4: 4,   # DAMAGE
		5: 4,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size - big brain monster
	if sprite:
		sprite.scale = Vector2(4.0, 4.0)
		# Eerie pink/purple tint
		sprite.modulate = Color(1.0, 0.85, 0.95, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "psychic_claw",
			"range": claw_range,
			"cooldown": 3.0,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "mind_blast",
			"range": mind_blast_range,
			"cooldown": 6.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "brain_drain",
			"range": brain_drain_range,
			"cooldown": 14.0,
			"priority": 7
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"psychic_claw":
			_start_psychic_claw()
		"mind_blast":
			_start_mind_blast()
		"brain_drain":
			_start_brain_drain()

# ============================================
# PSYCHIC CLAW
# ============================================

func _start_psychic_claw() -> void:
	claw_active = true
	claw_windup_timer = CLAW_WINDUP

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_psychic_claw() -> void:
	if not player or not is_instance_valid(player):
		return

	var dist = global_position.distance_to(player.global_position)
	if dist <= claw_range:
		if player.has_method("take_damage"):
			player.take_damage(claw_damage)
			_on_elite_attack_hit(claw_damage)

		# Apply silence/ability drain
		_apply_silence_to_player(claw_silence_duration)

	# Visual claw effect
	_spawn_claw_effect()

func _spawn_claw_effect() -> void:
	var dir = Vector2.RIGHT
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()

	var claw = Node2D.new()
	claw.global_position = global_position + dir * 40
	claw.z_index = 5

	var visual = ColorRect.new()
	visual.size = Vector2(40, 40)
	visual.position = Vector2(-20, -20)
	visual.color = Color(0.8, 0.4, 0.9, 0.8)
	claw.add_child(visual)

	get_parent().add_child(claw)

	var tween = create_tween()
	tween.tween_property(visual, "color:a", 0.0, 0.25)
	tween.tween_callback(claw.queue_free)

func _apply_silence_to_player(duration: float) -> void:
	if not player or not is_instance_valid(player):
		return

	if player.has_method("disable_abilities"):
		player.disable_abilities(duration)
	elif player.has_method("apply_silence"):
		player.apply_silence(duration)
	elif player.has_method("apply_status_effect"):
		player.apply_status_effect("silence", duration, 0)
	elif player.has_method("increase_cooldowns"):
		player.increase_cooldowns(2.0)

# ============================================
# MIND BLAST
# ============================================

func _start_mind_blast() -> void:
	mind_blast_active = true
	mind_blast_windup_timer = MIND_BLAST_WINDUP
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_DEVOUR, dir)
	animation_frame = 0

	# Show cone indicator
	_show_mind_blast_indicator(dir)

func _show_mind_blast_indicator(direction: Vector2) -> void:
	var indicator = Node2D.new()
	indicator.global_position = global_position
	indicator.z_index = -1
	indicator.rotation = direction.angle()

	var half_angle = deg_to_rad(mind_blast_cone_angle / 2.0)
	var polygon = Polygon2D.new()
	var points = PackedVector2Array([
		Vector2.ZERO,
		Vector2(mind_blast_range, 0).rotated(-half_angle),
		Vector2(mind_blast_range, 0).rotated(half_angle)
	])
	polygon.polygon = points
	polygon.color = Color(0.7, 0.3, 0.8, 0.3)
	indicator.add_child(polygon)

	get_parent().add_child(indicator)

	var tween = create_tween()
	tween.tween_property(polygon, "color:a", 0.6, MIND_BLAST_WINDUP * 0.8)
	tween.tween_property(polygon, "color:a", 0.0, 0.15)
	tween.tween_callback(indicator.queue_free)

func _execute_mind_blast() -> void:
	hide_warning()

	if not player or not is_instance_valid(player):
		return

	var to_player = player.global_position - global_position
	var distance = to_player.length()
	var direction = to_player.normalized()

	# Check if player is in cone
	if distance <= mind_blast_range:
		var facing = (player.global_position - global_position).normalized()
		var half_cone = deg_to_rad(mind_blast_cone_angle / 2.0)

		# Since we're facing the player, they're always in the cone if in range
		if player.has_method("take_damage"):
			player.take_damage(mind_blast_damage)
			_on_elite_attack_hit(mind_blast_damage)

		# Apply confusion effect
		_apply_confusion_to_player()

	# Visual blast wave
	_spawn_mind_blast_effect()

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_mind_blast_effect() -> void:
	var dir = Vector2.RIGHT
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()

	var blast = Node2D.new()
	blast.global_position = global_position
	blast.z_index = 5
	blast.rotation = dir.angle()

	var visual = ColorRect.new()
	visual.size = Vector2(20, 60)
	visual.position = Vector2(0, -30)
	visual.color = Color(0.7, 0.3, 0.9, 0.8)
	blast.add_child(visual)

	get_parent().add_child(blast)

	var tween = create_tween()
	tween.tween_property(visual, "size:x", mind_blast_range, 0.15)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.3)
	tween.tween_callback(blast.queue_free)

func _apply_confusion_to_player() -> void:
	if not player or not is_instance_valid(player):
		return

	# Confusion reverses or randomizes movement
	if player.has_method("apply_confusion"):
		player.apply_confusion(confusion_duration)
	elif player.has_method("apply_status_effect"):
		player.apply_status_effect("confusion", confusion_duration, 0)
	else:
		# Fallback: heavy slow
		if player.has_method("apply_slow"):
			player.apply_slow(0.6, confusion_duration)

# ============================================
# BRAIN DRAIN (Special Attack)
# ============================================

func _start_brain_drain() -> void:
	show_warning()
	is_using_special = true

	brain_drain_telegraphing = true
	brain_drain_telegraph_timer = brain_drain_telegraph_time
	special_timer = brain_drain_telegraph_time + brain_drain_duration + 0.5

	_show_brain_drain_warning()
	_create_drain_line()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_DEVOUR, dir)
	animation_frame = 0

func _create_drain_line() -> void:
	if brain_drain_line == null:
		brain_drain_line = Line2D.new()
		brain_drain_line.width = 8.0
		brain_drain_line.default_color = Color(0.8, 0.3, 0.9, 0.5)
		brain_drain_line.z_index = 10
		add_child(brain_drain_line)

	brain_drain_line.clear_points()
	brain_drain_line.visible = true

func _execute_brain_drain() -> void:
	brain_drain_telegraphing = false
	brain_drain_channeling = true
	brain_drain_channel_timer = brain_drain_duration
	_hide_brain_drain_warning()

	# Apply silence at start of channel
	_apply_silence_to_player(brain_drain_silence_duration)

	if JuiceManager:
		JuiceManager.shake_small()

func _process_brain_drain_channel(delta: float) -> void:
	if not player or not is_instance_valid(player):
		_end_brain_drain()
		return

	brain_drain_channel_timer -= delta

	var direction = (player.global_position - global_position).normalized()
	var distance = global_position.distance_to(player.global_position)

	# Update drain line
	if brain_drain_line:
		brain_drain_line.clear_points()
		brain_drain_line.add_point(Vector2.ZERO)
		brain_drain_line.add_point(direction * min(distance, brain_drain_range))

		# Pulsing purple effect
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.015) * 0.3
		brain_drain_line.default_color = Color(0.8, 0.3 * pulse, 0.9, 0.7 + pulse * 0.3)
		brain_drain_line.width = 6.0 + pulse * 4.0

	# Deal damage and heal if in range
	if distance <= brain_drain_range:
		if player.has_method("take_damage"):
			player.take_damage(brain_drain_damage * delta)

		# Heal self
		current_health = min(current_health + brain_drain_heal * delta, max_health)
		elite_health_changed.emit(current_health, max_health)
	else:
		# Player escaped - continue channeling but no effect
		brain_drain_line.default_color.a = 0.3

	# Animation during channel
	animation_frame += animation_speed * 0.5 * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEVOUR, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0
	var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_DEVOUR * COLS_PER_ROW + clamped_frame

	if brain_drain_channel_timer <= 0:
		_end_brain_drain()

func _show_brain_drain_warning() -> void:
	if brain_drain_warning_label == null:
		brain_drain_warning_label = Label.new()
		brain_drain_warning_label.text = "BRAIN DRAIN!"
		brain_drain_warning_label.add_theme_font_size_override("font_size", 16)
		brain_drain_warning_label.add_theme_color_override("font_color", Color(0.8, 0.4, 0.9, 1.0))
		brain_drain_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		brain_drain_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		brain_drain_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		brain_drain_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		brain_drain_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			brain_drain_warning_label.add_theme_font_override("font", pixel_font)

		add_child(brain_drain_warning_label)

	brain_drain_warning_label.position = Vector2(-55, -85)
	brain_drain_warning_label.visible = true

	if brain_drain_warning_tween and brain_drain_warning_tween.is_valid():
		brain_drain_warning_tween.kill()

	brain_drain_warning_tween = create_tween().set_loops()
	brain_drain_warning_tween.tween_property(brain_drain_warning_label, "modulate:a", 0.5, 0.12)
	brain_drain_warning_tween.tween_property(brain_drain_warning_label, "modulate:a", 1.0, 0.12)

func _hide_brain_drain_warning() -> void:
	if brain_drain_warning_tween and brain_drain_warning_tween.is_valid():
		brain_drain_warning_tween.kill()
		brain_drain_warning_tween = null
	if brain_drain_warning_label:
		brain_drain_warning_label.visible = false

func _end_brain_drain() -> void:
	brain_drain_telegraphing = false
	brain_drain_channeling = false
	hide_warning()
	_hide_brain_drain_warning()
	if brain_drain_line:
		brain_drain_line.visible = false

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle claw windup
	if claw_active:
		claw_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 6)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if claw_windup_timer <= 0:
			_execute_psychic_claw()
			claw_active = false
			can_attack = false
		return

	# Handle mind blast windup
	if mind_blast_active:
		mind_blast_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_DEVOUR, 8)
		sprite.frame = ROW_DEVOUR * COLS_PER_ROW + int(animation_frame) % max_frames

		if mind_blast_windup_timer <= 0:
			_execute_mind_blast()
			mind_blast_active = false
			can_attack = false
		return

	# Handle brain drain channel
	if brain_drain_channeling:
		_process_brain_drain_channel(delta)
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if brain_drain_telegraphing:
		brain_drain_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

			# Update targeting line during telegraph
			if brain_drain_line:
				brain_drain_line.clear_points()
				brain_drain_line.add_point(Vector2.ZERO)
				brain_drain_line.add_point(dir * brain_drain_range)
				brain_drain_line.default_color = Color(0.8, 0.3, 0.9, 0.4)

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_DEVOUR, 8)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_DEVOUR * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		if brain_drain_telegraph_timer <= 0:
			_execute_brain_drain()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_brain_drain()

func die() -> void:
	_end_brain_drain()
	super.die()
