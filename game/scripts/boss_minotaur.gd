extends BossBase

# Minotaur Boss - First boss enemy
# Attacks: AOE Slam (attack1), Melee swings (attack2-4)
# Enrages at 20% HP

@export var slam_effect_scene: PackedScene  # Ground slam AOE visual

# Attack damage values
@export var slam_damage: float = 50.0  # AOE attack
@export var melee_damage: float = 22.0  # Regular melee (reduced further)

# Attack ranges (slightly longer due to size)
@export var slam_range: float = 100.0
@export var slam_aoe_radius: float = 150.0
@export var melee_range: float = 90.0

# Spritesheet config: 96x96 frames, 10 cols x 20 rows (10 right + 10 left facing rows)
const SPRITE_COLS: int = 10
const SPRITE_ROWS: int = 20

# Animation rows (right-facing, top half of sheet)
const ANIM_IDLE: int = 0
const ANIM_MOVE: int = 1
const ANIM_TAUNT: int = 2
const ANIM_ATTACK1: int = 3  # AOE slam
const ANIM_ATTACK2: int = 4
const ANIM_ATTACK3: int = 5
const ANIM_ATTACK4: int = 6
const ANIM_DAMAGE: int = 7
const ANIM_DAMAGE2: int = 8
const ANIM_DEATH: int = 9

# Frame counts per animation (max 10 per row)
const FRAMES = {
	0: 5,   # Idle
	1: 8,   # Move
	2: 5,   # Taunt
	3: 10,  # Attack 1 (AOE)
	4: 6,   # Attack 2
	5: 6,   # Attack 3
	6: 10,  # Attack 4
	7: 3,   # Damage
	8: 3,   # Damage 2
	9: 6,   # Death
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.8  # Big windup for impactful attacks
var is_attack_animating: bool = false  # Prevents conflicting animation updates

# Attack rows for random selection
var melee_attack_rows: Array[int] = [ANIM_ATTACK2, ANIM_ATTACK3, ANIM_ATTACK4]

# Direction tracking - use row offset instead of flip_h
# Left-facing rows are offset by 10 (rows 10-19)
const LEFT_FACING_OFFSET: int = 10
var facing_left: bool = false

func _setup_boss() -> void:
	boss_name = "Minotaur"
	display_name = "BULLSH*T"
	elite_name = "Minotaur"
	enemy_type = "minotaur"

	# Boss stats
	speed = 84.0  # Reduced 20% from 103.5
	max_health = 1336.5  # 1215 + 10%
	attack_damage = melee_damage
	base_damage = melee_damage
	attack_cooldown = 4.0  # 3-5s range
	windup_duration = WINDUP_DURATION
	animation_speed = 10.0

	# Rewards
	xp_multiplier = 20.0
	coin_multiplier = 25.0
	guaranteed_drop = true

	# Enrage settings
	enrage_threshold = 0.20
	enrage_damage_bonus = 0.25
	enrage_size_bonus = 0.10

	# Taunt settings
	taunt_on_spawn = true
	taunt_count = 2
	taunt_speed_multiplier = 1.5

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_MOVE
	ROW_ATTACK = ANIM_ATTACK1
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_TAUNT
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_TAUNT]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false  # Boss uses bottom screen health bar

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "slam",
			"range": slam_range,
			"cooldown": 6.0,
			"priority": 4
		},
		{
			"type": AttackType.MELEE,
			"name": "melee",
			"range": melee_range,
			"cooldown": 1.5,
			"priority": 8
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"slam":
			_start_slam_attack()
		"melee":
			_start_melee_attack()

func _start_slam_attack() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION
	current_attack_type = ANIM_ATTACK1
	animation_frame = 0.0
	current_row = ANIM_ATTACK1

	# Show warning for AOE
	show_warning()

	# Face player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		facing_left = dir.x < 0

func _start_melee_attack() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.7  # Slightly faster for melee
	# Random melee attack animation
	current_attack_type = melee_attack_rows[randi() % melee_attack_rows.size()]
	animation_frame = 0.0
	current_row = current_attack_type

	# Face player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		facing_left = dir.x < 0

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	# Skip parent behavior during attack follow-through (tween handles animation)
	if is_attack_animating:
		return

	super._physics_process(delta)

func _process_windup(delta: float) -> void:
	attack_windup_timer -= delta

	# Animate windup (first half of attack animation, slower)
	animation_frame += animation_speed * 0.5 * delta
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var windup_frames = int(max_frames * 0.4)  # Only show first 40% during windup

	if animation_frame > windup_frames:
		animation_frame = float(windup_frames)

	# Use left-facing rows when facing left
	var actual_row = _get_actual_row(current_attack_type)
	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = actual_row * COLS_PER_ROW + frame_index

	# Face player during windup
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		facing_left = dir.x < 0

	if attack_windup_timer <= 0:
		is_winding_up = false
		_execute_current_attack()

func _execute_current_attack() -> void:
	hide_warning()

	if current_attack_type == ANIM_ATTACK1:
		_execute_slam()
	else:
		_execute_melee()

	# Play rest of attack animation
	_play_attack_followthrough()

func _execute_slam() -> void:
	# AOE damage
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= slam_aoe_radius:
			var damage = slam_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	# Spawn ground effect
	_spawn_slam_effect()

	# Big screen shake
	if JuiceManager:
		JuiceManager.shake_large()

	can_attack = false

func _execute_melee() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= melee_range:
			var damage = melee_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	# Medium screen shake
	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _spawn_slam_effect() -> void:
	# Create a ground slam visual effect
	if slam_effect_scene:
		var effect = slam_effect_scene.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)
	else:
		# Fallback: simple expanding circle effect
		_create_simple_slam_effect()

func _create_simple_slam_effect() -> void:
	# Create a simple visual for the slam AOE
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Draw circle that expands and fades
	var circle = _create_slam_circle()
	effect.add_child(circle)

	# Auto-cleanup
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	timer.timeout.connect(effect.queue_free)
	effect.add_child(timer)
	timer.start()

func _create_slam_circle() -> Node2D:
	var circle = Node2D.new()

	# Use a simple Line2D to draw circle
	var line = Line2D.new()
	line.width = 8.0
	line.default_color = Color(1.0, 0.3, 0.2, 0.8)
	line.z_index = -1

	# Create circle points
	var points: Array[Vector2] = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * slam_aoe_radius)
	line.points = points

	circle.add_child(line)

	# Animate expansion and fade
	var tween = circle.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.4)
	tween.parallel().tween_property(circle, "scale", Vector2(1.3, 1.3), 0.4)

	return circle

func _play_attack_followthrough() -> void:
	# Continue animation from where windup left off
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var start_frame = int(max_frames * 0.4)
	animation_frame = start_frame

	# Prevent conflicting animation updates during tween
	is_attack_animating = true

	# Create tween to play through rest of animation
	var tween = create_tween()
	var remaining_frames = max_frames - start_frame
	var duration = remaining_frames / animation_speed

	tween.tween_method(_update_attack_frame, float(start_frame), float(max_frames - 1), duration)
	tween.tween_callback(_on_attack_complete)

func _update_attack_frame(frame: float) -> void:
	var actual_row = _get_actual_row(current_attack_type)
	var max_frames = FRAME_COUNTS.get(current_attack_type, 8)
	var frame_index = clampi(int(frame), 0, max_frames - 1)
	sprite.frame = actual_row * COLS_PER_ROW + frame_index

func _on_attack_complete() -> void:
	is_attack_animating = false  # Allow normal animation updates again
	can_attack = false  # Reset for cooldown system
	current_row = ROW_IDLE

func _process_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 6)

	if animation_frame >= max_frames - 1:
		animation_frame = float(max_frames - 1)
		if not death_processed:
			death_processed = true
			spawn_gold_coin()
			queue_free()

	var actual_row = _get_actual_row(ROW_DEATH)
	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = actual_row * COLS_PER_ROW + frame_index

# Override to use appropriate damage animation
func take_damage(amount: float, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)

	# Brief flash to damage row
	if not is_dying and not is_winding_up and not is_taunting:
		# Quick damage reaction without interrupting current action
		pass

var death_processed: bool = false

# Override update_animation to use left-facing rows instead of flip_h
func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	# Update facing direction but DON'T use flip_h
	if direction.x != 0:
		facing_left = direction.x < 0
		sprite.flip_h = false  # Never flip - use row offset instead

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = fmod(animation_frame, float(max_frames))

	# Use left-facing rows (offset by 10) when facing left
	var actual_row = current_row
	if facing_left:
		actual_row += LEFT_FACING_OFFSET

	# Calculate frame index with bounds checking
	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = actual_row * COLS_PER_ROW + frame_index

func _get_actual_row(base_row: int) -> int:
	"""Get the actual sprite row accounting for facing direction."""
	if facing_left:
		return base_row + LEFT_FACING_OFFSET
	return base_row

# Override taunt processing to use correct row
func _process_taunt(delta: float) -> void:
	animation_frame += animation_speed * taunt_speed_multiplier * delta
	var max_frames = FRAMES_TAUNT

	if animation_frame >= max_frames:
		animation_frame = fmod(animation_frame, float(max_frames))
		taunt_plays_remaining -= 1

		if taunt_plays_remaining <= 0:
			is_taunting = false
			can_attack = true
			return

	var actual_row = _get_actual_row(ROW_TAUNT)
	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = actual_row * COLS_PER_ROW + frame_index
