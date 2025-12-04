extends BossBase

# Elder Dragon Boss - "WORLD ENDER"
# THE FINAL BOSS - Inspired by Deathwing (WoW), Hades, Diablo himself
# Attacks: Claw Strike, Fire Breath (cone), Tail Sweep, Wing Buffet, Rain of Fire
# Has PHASE TRANSITIONS at 66% and 33% HP
# Tier: Thanksgiving Dinner (64x Minotaur power) - THE ULTIMATE CHALLENGE

# Attack damage values (64x Minotaur base - MASSIVE)
@export var claw_damage: float = 1400.0  # 22 * 64
@export var breath_damage: float = 800.0  # Per tick in cone
@export var tail_damage: float = 1200.0
@export var buffet_damage: float = 600.0
@export var fire_rain_damage: float = 400.0  # Per meteor

# Attack ranges
@export var claw_range: float = 160.0
@export var breath_range: float = 350.0
@export var breath_cone_angle: float = 60.0  # Degrees
@export var tail_sweep_radius: float = 250.0
@export var buffet_range: float = 300.0
@export var fire_rain_radius: float = 500.0

# Breath attack settings
var breath_duration: float = 2.0
var is_breathing: bool = false
var breath_timer: float = 0.0
var breath_tick_interval: float = 0.2
var breath_tick_timer: float = 0.0

# Phase system
enum Phase { ONE, TWO, THREE }
var current_phase: Phase = Phase.ONE
const PHASE_TWO_THRESHOLD: float = 0.66
const PHASE_THREE_THRESHOLD: float = 0.33

# Phase 2 buff: faster attacks
const PHASE_TWO_SPEED_MULT: float = 1.3
const PHASE_TWO_COOLDOWN_MULT: float = 0.7

# Phase 3 buff: even faster, double fire rain
const PHASE_THREE_SPEED_MULT: float = 1.6
const PHASE_THREE_COOLDOWN_MULT: float = 0.5
const PHASE_THREE_DAMAGE_MULT: float = 1.25

# Wing buffet knockback
const BUFFET_KNOCKBACK: float = 400.0

# Attack effect textures
var breath_texture: Texture2D = null
var wing_texture: Texture2D = null

# Spritesheet config: 192x96 frames, 7 cols x 8 rows
const SPRITE_COLS: int = 7
const SPRITE_ROWS: int = 8

# Animation rows (estimated from sprite sheet)
const ANIM_IDLE: int = 0
const ANIM_MOVE: int = 1
const ANIM_ATTACK1: int = 2   # Claw/bite
const ANIM_ATTACK2: int = 3   # Breath
const ANIM_ATTACK3: int = 4   # Tail/wing
const ANIM_DAMAGE: int = 5
const ANIM_DEATH: int = 6
const ANIM_ROAR: int = 7      # Phase transition roar

# Frame counts per animation
const FRAMES = {
	0: 7,   # Idle
	1: 7,   # Move
	2: 7,   # Attack1
	3: 7,   # Attack2 (breath)
	4: 7,   # Attack3 (tail/wing)
	5: 4,   # Damage
	6: 7,   # Death
	7: 7,   # Roar
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.8
var is_attack_animating: bool = false

# Phase transition state
var is_transitioning: bool = false
var transition_timer: float = 0.0
const TRANSITION_DURATION: float = 2.0

# Pending attack tracking
var pending_attack_name: String = ""

# Breath effect node
var breath_effect: Node2D = null

func _setup_boss() -> void:
	boss_name = "ElderDragon"
	display_name = "WORLD ENDER"
	elite_name = "Elder Dragon"
	enemy_type = "elder_dragon"

	# Boss stats (64x Minotaur: 1336.5 HP, 84 speed) - THE FINAL BOSS
	speed = 100.0  # Massive but still threatening
	max_health = 85536.0  # 1336.5 * 64
	attack_damage = claw_damage
	base_damage = claw_damage
	attack_cooldown = 3.0
	windup_duration = WINDUP_DURATION
	animation_speed = 10.0

	# Rewards (64x) - MASSIVE REWARDS
	xp_multiplier = 1280.0
	coin_multiplier = 1600.0
	guaranteed_drop = true

	# Enrage settings - DEVASTATING when enraged
	enrage_threshold = 0.15  # Late enrage but terrifying
	enrage_damage_bonus = 0.60
	enrage_size_bonus = 0.25

	# Taunt settings - epic roar on spawn
	taunt_on_spawn = true
	taunt_count = 2
	taunt_speed_multiplier = 0.8  # Slow, menacing roar

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_MOVE
	ROW_ATTACK = ANIM_ATTACK1
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_ROAR
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_ROAR]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false

	# Load attack effect textures
	breath_texture = load("res://assets/sprites/Elder Dragon Attack1 Sprites.png")
	wing_texture = load("res://assets/sprites/Elder Dragon Attack2 Sprites.png")

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "fire_rain",
			"range": 9999.0,
			"cooldown": 15.0,
			"priority": 2
		},
		{
			"type": AttackType.SPECIAL,
			"name": "fire_breath",
			"range": breath_range,
			"cooldown": 8.0,
			"priority": 3
		},
		{
			"type": AttackType.SPECIAL,
			"name": "wing_buffet",
			"range": buffet_range,
			"cooldown": 10.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "tail_sweep",
			"range": tail_sweep_radius,
			"cooldown": 6.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "claw_strike",
			"range": claw_range,
			"cooldown": 2.0,
			"priority": 8
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"fire_rain":
			_start_fire_rain()
		"fire_breath":
			_start_fire_breath()
		"wing_buffet":
			_start_wing_buffet()
		"tail_sweep":
			_start_tail_sweep()
		"claw_strike":
			_start_claw_strike()

func _start_fire_rain() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 1.5
	current_attack_type = ANIM_ROAR  # Roar before rain
	animation_frame = 0.0
	current_row = ANIM_ROAR

	show_warning()

	if JuiceManager:
		JuiceManager.shake_small()

func _start_fire_breath() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION
	current_attack_type = ANIM_ATTACK2
	animation_frame = 0.0
	current_row = ANIM_ATTACK2

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

	show_warning()

func _start_wing_buffet() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.8
	current_attack_type = ANIM_ATTACK3
	animation_frame = 0.0
	current_row = ANIM_ATTACK3

	show_warning()

func _start_tail_sweep() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.7
	current_attack_type = ANIM_ATTACK3
	animation_frame = 0.0
	current_row = ANIM_ATTACK3

	show_warning()

func _start_claw_strike() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.5
	current_attack_type = ANIM_ATTACK1
	animation_frame = 0.0
	current_row = ANIM_ATTACK1

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return

	# Handle phase transition
	if is_transitioning:
		_process_phase_transition(delta)
		return

	# Check for phase transitions
	_check_phase_transition()

	# Handle breath attack
	if is_breathing:
		_process_breath(delta)
		return

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	if is_attack_animating:
		return

	super._physics_process(delta)

func _check_phase_transition() -> void:
	var hp_percent = current_health / max_health

	if current_phase == Phase.ONE and hp_percent <= PHASE_TWO_THRESHOLD:
		_begin_phase_transition(Phase.TWO)
	elif current_phase == Phase.TWO and hp_percent <= PHASE_THREE_THRESHOLD:
		_begin_phase_transition(Phase.THREE)

func _begin_phase_transition(new_phase: Phase) -> void:
	current_phase = new_phase
	is_transitioning = true
	transition_timer = TRANSITION_DURATION
	velocity = Vector2.ZERO

	# Play roar animation
	current_row = ANIM_ROAR
	animation_frame = 0.0

	# Phase effects
	match new_phase:
		Phase.TWO:
			_apply_phase_two()
		Phase.THREE:
			_apply_phase_three()

	# Epic screen effects
	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.chromatic_pulse(1.0)
		JuiceManager.hitstop_large()

	if HapticManager:
		HapticManager.heavy()

func _apply_phase_two() -> void:
	# Faster and more aggressive
	speed *= PHASE_TWO_SPEED_MULT
	animation_speed *= PHASE_TWO_SPEED_MULT

	# Reduce cooldowns
	for attack in available_attacks:
		attack.cooldown *= PHASE_TWO_COOLDOWN_MULT

	# Visual change - orange glow
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.4, 1.0, 0.7, 1.0), 0.5)

func _apply_phase_three() -> void:
	# MAXIMUM AGGRESSION
	speed *= PHASE_THREE_SPEED_MULT / PHASE_TWO_SPEED_MULT
	animation_speed *= PHASE_THREE_SPEED_MULT / PHASE_TWO_SPEED_MULT
	attack_damage = base_damage * PHASE_THREE_DAMAGE_MULT

	# Further reduce cooldowns
	for attack in available_attacks:
		attack.cooldown *= PHASE_THREE_COOLDOWN_MULT / PHASE_TWO_COOLDOWN_MULT

	# Visual change - intense red/orange glow
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.6, 0.8, 0.6, 1.0), 0.5)

func _process_phase_transition(delta: float) -> void:
	transition_timer -= delta

	# Animate roar
	animation_frame += animation_speed * 0.8 * delta
	var max_frames = FRAMES[ANIM_ROAR]
	if animation_frame >= max_frames:
		animation_frame = 0.0

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ANIM_ROAR * COLS_PER_ROW + frame_index

	# Continuous screen shake during transition
	if JuiceManager and int(transition_timer * 10) % 3 == 0:
		JuiceManager.shake_small()

	if transition_timer <= 0:
		is_transitioning = false
		can_attack = true

func _process_windup(delta: float) -> void:
	attack_windup_timer -= delta

	animation_frame += animation_speed * 0.5 * delta
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var windup_frames = int(max_frames * 0.4)

	if animation_frame > windup_frames:
		animation_frame = float(windup_frames)

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

	if attack_windup_timer <= 0:
		is_winding_up = false
		_execute_current_attack()

func _select_attack() -> Dictionary:
	var attack = super._select_attack()
	if attack.size() > 0:
		pending_attack_name = attack.get("name", "")
	return attack

func _execute_current_attack() -> void:
	hide_warning()

	match pending_attack_name:
		"fire_rain":
			_execute_fire_rain()
		"fire_breath":
			_begin_fire_breath()
		"wing_buffet":
			_execute_wing_buffet()
		"tail_sweep":
			_execute_tail_sweep()
		"claw_strike":
			_execute_claw_strike()

func _execute_fire_rain() -> void:
	# Spawn multiple fire meteors
	var meteor_count = 8 if current_phase == Phase.THREE else 5

	for i in range(meteor_count):
		var delay = i * 0.3  # Staggered meteors
		var timer = get_tree().create_timer(delay)
		timer.timeout.connect(_spawn_fire_meteor)

	if JuiceManager:
		JuiceManager.shake_large()

	can_attack = false
	_play_attack_followthrough()

func _spawn_fire_meteor() -> void:
	if not player or not is_instance_valid(player):
		return

	# Target near player with some randomness
	var target_pos = player.global_position + Vector2(
		randf_range(-150, 150),
		randf_range(-150, 150)
	)

	# Warning circle
	var warning = Node2D.new()
	warning.global_position = target_pos
	get_parent().add_child(warning)

	var circle = Line2D.new()
	circle.width = 4.0
	circle.default_color = Color(1.0, 0.3, 0.1, 0.8)
	circle.z_index = -1

	var points: Array[Vector2] = []
	var segments = 24
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 80)
	circle.points = points

	warning.add_child(circle)

	# Grow warning
	var warn_tween = warning.create_tween()
	warn_tween.tween_property(circle, "scale", Vector2(1.2, 1.2), 0.8)

	# Impact after delay
	var impact_timer = get_tree().create_timer(1.0)
	impact_timer.timeout.connect(_fire_meteor_impact.bind(target_pos, warning))

func _fire_meteor_impact(pos: Vector2, warning: Node2D) -> void:
	if is_instance_valid(warning):
		warning.queue_free()

	# Damage player if in range
	if player and is_instance_valid(player):
		var dist = pos.distance_to(player.global_position)
		if dist <= 100:
			var damage = fire_rain_damage
			if current_phase == Phase.THREE:
				damage *= PHASE_THREE_DAMAGE_MULT
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	# Explosion effect
	var explosion = Node2D.new()
	explosion.global_position = pos
	get_parent().add_child(explosion)

	var blast = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(16):
		var angle = (float(i) / 16) * TAU
		var radius = 60.0 + randf_range(-10, 10)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	blast.polygon = points
	blast.color = Color(1.0, 0.5, 0.1, 0.9)
	explosion.add_child(blast)

	var tween = explosion.create_tween()
	tween.tween_property(explosion, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(blast, "color:a", 0.0, 0.3)
	tween.tween_callback(explosion.queue_free)

	if JuiceManager:
		JuiceManager.shake_medium()

func _begin_fire_breath() -> void:
	is_breathing = true
	breath_timer = breath_duration
	breath_tick_timer = 0.0

	# Create breath effect
	_spawn_breath_effect()

	can_attack = false

func _spawn_breath_effect() -> void:
	breath_effect = Node2D.new()
	breath_effect.z_index = 10
	add_child(breath_effect)

	# Use breath texture if available
	var breath_sprite = Sprite2D.new()
	if breath_texture:
		breath_sprite.texture = breath_texture
		# Assuming vertical strip of frames
		breath_sprite.vframes = 8  # Estimate based on sprite
		breath_sprite.hframes = 1
		breath_sprite.frame = 0
	breath_sprite.scale = Vector2(4.0, 4.0)
	breath_sprite.rotation = 0 if not sprite.flip_h else PI
	breath_sprite.position = Vector2(100, 0) if not sprite.flip_h else Vector2(-100, 0)
	breath_effect.add_child(breath_sprite)

	# Animate breath sprite
	var anim_tween = breath_sprite.create_tween().set_loops()
	anim_tween.tween_property(breath_sprite, "frame", 7, 0.5)
	anim_tween.tween_property(breath_sprite, "frame", 0, 0.0)

func _process_breath(delta: float) -> void:
	breath_timer -= delta
	breath_tick_timer += delta

	# Animate during breath
	animation_frame += animation_speed * 0.3 * delta
	var max_frames = FRAME_COUNTS.get(ANIM_ATTACK2, 7)
	animation_frame = fmod(animation_frame, float(max_frames))

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ANIM_ATTACK2 * COLS_PER_ROW + frame_index

	# Damage ticks
	if breath_tick_timer >= breath_tick_interval:
		breath_tick_timer = 0.0
		_breath_damage_tick()

	# Update breath effect direction
	if breath_effect and player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

		# Rotate breath toward player
		var breath_sprite = breath_effect.get_child(0) as Sprite2D
		if breath_sprite:
			breath_sprite.rotation = dir.angle()
			breath_sprite.position = dir * 100

	if breath_timer <= 0:
		_end_breath()

func _breath_damage_tick() -> void:
	if not player or not is_instance_valid(player):
		return

	# Check if player is in cone
	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > breath_range:
		return

	# Check angle
	var forward = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	var angle_to_player = rad_to_deg(forward.angle_to(to_player.normalized()))

	if abs(angle_to_player) <= breath_cone_angle / 2:
		var damage = breath_damage
		if current_phase == Phase.THREE:
			damage *= PHASE_THREE_DAMAGE_MULT
		if is_enraged:
			damage *= (1.0 + enrage_damage_bonus)
		if player.has_method("take_damage"):
			player.take_damage(damage)

		if JuiceManager:
			JuiceManager.shake_small()

func _end_breath() -> void:
	is_breathing = false

	if breath_effect:
		breath_effect.queue_free()
		breath_effect = null

	current_row = ROW_IDLE

func _execute_wing_buffet() -> void:
	# AOE knockback attack
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= buffet_range:
			var damage = buffet_damage
			if current_phase == Phase.THREE:
				damage *= PHASE_THREE_DAMAGE_MULT
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

			# Knockback
			var knockback_dir = (player.global_position - global_position).normalized()
			if player.has_method("apply_knockback"):
				player.apply_knockback(knockback_dir * BUFFET_KNOCKBACK)
			elif "velocity" in player:
				player.velocity += knockback_dir * BUFFET_KNOCKBACK

	_spawn_buffet_effect()

	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.hitstop_small()

	can_attack = false
	_play_attack_followthrough()

func _spawn_buffet_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Wing sweep visual
	var sweep = Line2D.new()
	sweep.width = 20.0
	sweep.default_color = Color(0.7, 0.9, 1.0, 0.8)
	sweep.z_index = 5

	var points: Array[Vector2] = []
	for i in range(17):
		var angle = -PI/2 + (float(i) / 16) * PI  # 180 degree arc
		points.append(Vector2(cos(angle), sin(angle)) * buffet_range)
	sweep.points = points

	effect.add_child(sweep)

	var tween = effect.create_tween()
	tween.tween_property(effect, "scale", Vector2(1.3, 1.3), 0.3)
	tween.parallel().tween_property(sweep, "modulate:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

func _execute_tail_sweep() -> void:
	# 360 degree sweep
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= tail_sweep_radius:
			var damage = tail_damage
			if current_phase == Phase.THREE:
				damage *= PHASE_THREE_DAMAGE_MULT
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	_spawn_tail_effect()

	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.hitstop_medium()

	if HapticManager:
		HapticManager.heavy()

	can_attack = false
	_play_attack_followthrough()

func _spawn_tail_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	var sweep = Line2D.new()
	sweep.width = 25.0
	sweep.default_color = Color(0.6, 0.4, 0.8, 0.9)
	sweep.z_index = -1

	var points: Array[Vector2] = []
	for i in range(33):
		var angle = (float(i) / 32) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * tail_sweep_radius)
	sweep.points = points

	effect.add_child(sweep)

	# Spin and fade
	var tween = effect.create_tween()
	tween.tween_property(effect, "rotation", TAU, 0.4)
	tween.parallel().tween_property(sweep, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func _execute_claw_strike() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= claw_range:
			var damage = claw_damage
			if current_phase == Phase.THREE:
				damage *= PHASE_THREE_DAMAGE_MULT
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false
	_play_attack_followthrough()

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
	var max_frames = FRAME_COUNTS.get(current_attack_type, 7)
	var frame_index = clampi(int(frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

func _on_attack_complete() -> void:
	is_attack_animating = false
	can_attack = false
	current_row = ROW_IDLE

func _process_death_animation(delta: float) -> void:
	animation_frame += animation_speed * 0.7 * delta  # Slow, dramatic death
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 7)

	# Screen shake during death
	if JuiceManager and int(animation_frame * 3) % 2 == 0:
		JuiceManager.shake_small()

	if animation_frame >= max_frames - 1:
		animation_frame = float(max_frames - 1)
		if not death_processed:
			death_processed = true
			_epic_death_sequence()

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_DEATH * COLS_PER_ROW + frame_index

func _epic_death_sequence() -> void:
	# MASSIVE rewards and effects for killing the final boss
	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.chromatic_pulse(1.5)
		JuiceManager.hitstop_large()

	if HapticManager:
		HapticManager.heavy()

	# Spawn LOTS of gold
	spawn_gold_coin()

	# Delay before removing
	var timer = get_tree().create_timer(0.5)
	timer.timeout.connect(queue_free)

var death_processed: bool = false

func update_animation(delta: float, new_row: int, direction: Vector2) -> void:
	if current_row != new_row:
		current_row = new_row
		animation_frame = 0.0

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 7)
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

# Override to drop MASSIVE gold
func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	var drop_mult = 1.0
	if CurseEffects:
		drop_mult = CurseEffects.get_gold_drop_multiplier()

	# Final boss drops INSANE amounts of gold
	var coin_count = int(coin_multiplier * 5 * drop_mult)
	for i in range(max(20, coin_count)):
		var coin = gold_coin_scene.instantiate()
		var offset = Vector2(randf_range(-150, 150), randf_range(-150, 150))
		coin.global_position = global_position + offset
		get_parent().add_child(coin)

	if guaranteed_drop:
		_drop_boss_item()
		# Drop a SECOND legendary item for final boss
		_drop_boss_item()
