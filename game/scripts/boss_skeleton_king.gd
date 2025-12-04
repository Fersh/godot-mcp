extends BossBase

# Skeleton King Boss - "The Fallen Monarch"
# Inspired by Leoric from Diablo 3
# Attacks: Melee swing, Command (buff), Leap Attack (AOE), Summon Skeletons
# Tier: Easy (2x Minotaur power)

@export var skeleton_scene: PackedScene  # For summoning minions
@export var leap_effect_scene: PackedScene  # Ground slam visual

# Attack damage values (2x Minotaur base)
@export var melee_damage: float = 44.0  # 22 * 2
@export var leap_damage: float = 100.0  # 50 * 2
@export var summon_count: int = 8

# Attack ranges
@export var melee_range: float = 100.0
@export var leap_range: float = 250.0  # Can leap from further away
@export var leap_aoe_radius: float = 180.0
@export var summon_range: float = 400.0  # Summons when player is far

# Spritesheet config: 96x96 frames, 9 cols x 7 rows
const SPRITE_COLS: int = 9
const SPRITE_ROWS: int = 7

# Animation rows
const ANIM_IDLE: int = 0
const ANIM_MOVE: int = 1
const ANIM_ATTACK: int = 2
const ANIM_COMMAND: int = 3
const ANIM_LEAP: int = 4
const ANIM_DAMAGE: int = 5
const ANIM_DEATH: int = 6

# Frame counts per animation
const FRAMES = {
	0: 4,   # Idle
	1: 9,   # Move
	2: 8,   # Attack
	3: 7,   # Command (summon)
	4: 9,   # Leap Attack
	5: 4,   # Damage
	6: 9,   # Death
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.9  # Slightly longer for dramatic effect
var is_attack_animating: bool = false

# Leap attack state
var is_leaping: bool = false
var leap_target: Vector2 = Vector2.ZERO
var leap_speed: float = 600.0
var leap_height: float = 100.0
var leap_progress: float = 0.0

# Leap animation sprite (separate spritesheet)
var leap_sprite: Sprite2D = null

# Summon cooldown tracking
var summon_cooldown_timer: float = 0.0
const SUMMON_COOLDOWN: float = 15.0

func _setup_boss() -> void:
	boss_name = "SkeletonKing"
	display_name = "THE FALLEN MONARCH"
	elite_name = "Skeleton King"
	enemy_type = "skeleton_king"

	# Boss stats (2x Minotaur: 1336.5 HP, 84 speed)
	speed = 100.0  # Slightly faster
	max_health = 2673.0  # 1336.5 * 2
	attack_damage = melee_damage
	base_damage = melee_damage
	attack_cooldown = 3.5
	windup_duration = WINDUP_DURATION
	animation_speed = 10.0

	# Rewards (2x Minotaur)
	xp_multiplier = 40.0
	coin_multiplier = 50.0
	guaranteed_drop = true

	# Enrage settings
	enrage_threshold = 0.25  # Enrages at 25% HP
	enrage_damage_bonus = 0.30  # +30% damage
	enrage_size_bonus = 0.12  # +12% size

	# Taunt settings
	taunt_on_spawn = true
	taunt_count = 2
	taunt_speed_multiplier = 1.3

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_MOVE
	ROW_ATTACK = ANIM_ATTACK
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_COMMAND  # Use command as taunt
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_COMMAND]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "leap",
			"range": leap_range,
			"cooldown": 8.0,
			"priority": 3  # High priority
		},
		{
			"type": AttackType.SPECIAL,
			"name": "summon",
			"range": summon_range,
			"cooldown": SUMMON_COOLDOWN,
			"priority": 2  # Highest priority when available
		},
		{
			"type": AttackType.MELEE,
			"name": "melee",
			"range": melee_range,
			"cooldown": 2.0,
			"priority": 8
		}
	]

	# Setup leap sprite if needed
	_setup_leap_sprite()

func _setup_leap_sprite() -> void:
	# Create a secondary sprite for the leap animation overlay
	leap_sprite = Sprite2D.new()
	leap_sprite.visible = false
	leap_sprite.z_index = 1  # Above main sprite
	add_child(leap_sprite)

	# Load leap animation texture
	var leap_texture = load("res://assets/sprites/Skeleton King Leap Animation 96x128.png")
	if leap_texture:
		leap_sprite.texture = leap_texture
		leap_sprite.hframes = 9  # 9 frames in the leap animation
		leap_sprite.vframes = 1
		leap_sprite.centered = true

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"leap":
			_start_leap_attack()
		"summon":
			_start_summon()
		"melee":
			_start_melee_attack()

func _start_leap_attack() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.5  # Quick windup for leap
	current_attack_type = ANIM_LEAP
	animation_frame = 0.0
	current_row = ANIM_LEAP

	# Store target position
	if player and is_instance_valid(player):
		leap_target = player.global_position

	# Show warning
	show_warning()

	# Face player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_summon() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 1.2  # Longer windup for summon
	current_attack_type = ANIM_COMMAND
	animation_frame = 0.0
	current_row = ANIM_COMMAND

	# Face player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

	# Screen effect
	if JuiceManager:
		JuiceManager.shake_small()

func _start_melee_attack() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.7
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	# Face player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return

	# Handle leap movement
	if is_leaping:
		_process_leap(delta)
		return

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	# Skip parent behavior during attack follow-through
	if is_attack_animating:
		return

	super._physics_process(delta)

func _process_windup(delta: float) -> void:
	attack_windup_timer -= delta

	# Animate windup
	animation_frame += animation_speed * 0.5 * delta
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var windup_frames = int(max_frames * 0.4)

	if animation_frame > windup_frames:
		animation_frame = float(windup_frames)

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

	# Face player during windup
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

	if attack_windup_timer <= 0:
		is_winding_up = false
		_execute_current_attack()

func _execute_current_attack() -> void:
	hide_warning()

	match current_attack_type:
		ANIM_LEAP:
			_begin_leap()
		ANIM_COMMAND:
			_execute_summon()
		ANIM_ATTACK:
			_execute_melee()

	# Play rest of attack animation (except for leap which has its own handling)
	if current_attack_type != ANIM_LEAP:
		_play_attack_followthrough()

func _begin_leap() -> void:
	is_leaping = true
	leap_progress = 0.0

	# Show leap sprite, hide main sprite during leap
	if leap_sprite:
		leap_sprite.visible = true
		leap_sprite.frame = 0

	# Calculate leap duration based on distance
	var distance = global_position.distance_to(leap_target)
	var leap_duration = distance / leap_speed

	# Create tween for leap movement
	var tween = create_tween()
	tween.set_parallel(true)

	# Horizontal movement
	tween.tween_property(self, "global_position", leap_target, leap_duration).set_ease(Tween.EASE_IN_OUT)

	# Vertical arc (using a separate property)
	tween.tween_method(_update_leap_height, 0.0, 1.0, leap_duration)

	# Animate leap sprite
	tween.tween_method(_update_leap_frame, 0.0, 8.0, leap_duration)

	tween.chain().tween_callback(_on_leap_land)

func _update_leap_height(progress: float) -> void:
	leap_progress = progress
	# Parabolic arc
	var height = sin(progress * PI) * leap_height
	if sprite:
		sprite.position.y = -height
	if leap_sprite:
		leap_sprite.position.y = -height

func _update_leap_frame(frame: float) -> void:
	if leap_sprite:
		leap_sprite.frame = clampi(int(frame), 0, 8)

func _process_leap(delta: float) -> void:
	# Leap is handled by tween, just update sprite facing
	if player and is_instance_valid(player):
		var dir = (leap_target - global_position).normalized()
		sprite.flip_h = dir.x < 0
		if leap_sprite:
			leap_sprite.flip_h = dir.x < 0

func _on_leap_land() -> void:
	is_leaping = false

	# Reset positions
	if sprite:
		sprite.position.y = 0
	if leap_sprite:
		leap_sprite.visible = false
		leap_sprite.position.y = 0

	# Deal AOE damage
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= leap_aoe_radius:
			var damage = leap_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	# Spawn ground effect
	_spawn_leap_effect()

	# Big screen shake
	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.hitstop_medium()

	# Haptic feedback
	if HapticManager:
		HapticManager.heavy()

	can_attack = false
	_play_attack_followthrough()

func _spawn_leap_effect() -> void:
	if leap_effect_scene:
		var effect = leap_effect_scene.instantiate()
		effect.global_position = global_position
		get_parent().add_child(effect)
	else:
		_create_simple_leap_effect()

func _create_simple_leap_effect() -> void:
	# Create expanding ring effect
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	var line = Line2D.new()
	line.width = 10.0
	line.default_color = Color(0.8, 0.2, 0.8, 0.9)  # Purple/necrotic color
	line.z_index = -1

	var points: Array[Vector2] = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * leap_aoe_radius)
	line.points = points

	effect.add_child(line)

	var tween = effect.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(effect, "scale", Vector2(1.4, 1.4), 0.5)
	tween.tween_callback(effect.queue_free)

func _execute_summon() -> void:
	# Summon skeletons around the boss
	var skeleton_to_spawn = skeleton_scene
	if skeleton_to_spawn == null:
		skeleton_to_spawn = load("res://scenes/enemy_skeleton.tscn")

	if skeleton_to_spawn == null:
		push_warning("Skeleton King: No skeleton scene available for summoning")
		return

	for i in range(summon_count):
		var angle = (float(i) / summon_count) * TAU
		var offset = Vector2(cos(angle), sin(angle)) * randf_range(80, 150)
		var spawn_pos = global_position + offset

		var skeleton = skeleton_to_spawn.instantiate()
		skeleton.global_position = spawn_pos
		get_parent().add_child(skeleton)

		# Small spawn effect
		_spawn_summon_effect(spawn_pos)

	# Screen shake
	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _spawn_summon_effect(pos: Vector2) -> void:
	# Simple purple particle burst
	var effect = Node2D.new()
	effect.global_position = pos
	get_parent().add_child(effect)

	# Create a simple flash
	var flash = Sprite2D.new()
	flash.modulate = Color(0.8, 0.2, 0.8, 0.8)
	effect.add_child(flash)

	var tween = effect.create_tween()
	tween.tween_property(flash, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func _execute_melee() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= melee_range:
			var damage = melee_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _play_attack_followthrough() -> void:
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var start_frame = int(max_frames * 0.4)
	animation_frame = start_frame

	is_attack_animating = true

	var tween = create_tween()
	var remaining_frames = max_frames - start_frame
	var duration = remaining_frames / animation_speed

	tween.tween_method(_update_attack_frame, float(start_frame), float(max_frames - 1), duration)
	tween.tween_callback(_on_attack_complete)

func _update_attack_frame(frame: float) -> void:
	var max_frames = FRAME_COUNTS.get(current_attack_type, 8)
	var frame_index = clampi(int(frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

func _on_attack_complete() -> void:
	is_attack_animating = false
	can_attack = false
	current_row = ROW_IDLE

func _process_death_animation(delta: float) -> void:
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 9)

	if animation_frame >= max_frames - 1:
		animation_frame = float(max_frames - 1)
		if not death_processed:
			death_processed = true
			spawn_gold_coin()
			queue_free()

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_DEATH * COLS_PER_ROW + frame_index

var death_processed: bool = false

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	# Update facing direction using flip_h
	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = fmod(animation_frame, float(max_frames))

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

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

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_TAUNT * COLS_PER_ROW + frame_index
