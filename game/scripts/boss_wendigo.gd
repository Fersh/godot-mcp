extends BossBase

# Wendigo Boss - "The Hunger"
# Inspired by The Butcher (Diablo), Theseus (Hades), Bloodborne beasts
# Attacks: Slash (with effect), Howl (buff/fear), Pounce (charge), Ravage (multi-hit)
# Tier: Inferno (32x Minotaur power)

# Attack damage values (32x Minotaur base)
@export var slash_damage: float = 704.0  # 22 * 32
@export var pounce_damage: float = 900.0
@export var ravage_damage: float = 200.0  # Per hit

# Attack ranges
@export var slash_range: float = 130.0
@export var pounce_range: float = 400.0
@export var howl_radius: float = 300.0

# Pounce settings
@export var pounce_speed: float = 800.0
var is_pouncing: bool = false
var pounce_target: Vector2 = Vector2.ZERO

# Ravage settings (multi-hit frenzy)
@export var ravage_hits: int = 6
var ravage_hit_count: int = 0
var ravage_timer: float = 0.0
const RAVAGE_INTERVAL: float = 0.12
var is_ravaging: bool = false

# Ravenous passive - heal on hit
const RAVENOUS_HEAL_PERCENT: float = 0.05  # 5% of damage dealt

# Howl buff
var howl_active: bool = false
var howl_timer: float = 0.0
const HOWL_DURATION: float = 10.0
const HOWL_SPEED_BONUS: float = 0.5
const HOWL_DAMAGE_BONUS: float = 0.3

# Slash effect texture
var slash_texture: Texture2D = null

# Spritesheet config: 64x64 frames, 8 cols x 6 rows
const SPRITE_COLS: int = 8
const SPRITE_ROWS: int = 6

# Animation rows
const ANIM_IDLE: int = 0      # Also used for movement (4 frames)
const ANIM_DROOL: int = 1     # Idle drool (4 frames)
const ANIM_ATTACK: int = 2    # Attack/slash (8 frames)
const ANIM_HOWL: int = 3      # Howl (8 frames)
const ANIM_DAMAGE: int = 4    # Damaged (4 frames)
const ANIM_DEATH: int = 5     # Death (8 frames)

# Frame counts per animation
const FRAMES = {
	0: 4,   # Idle/Move
	1: 4,   # Drool
	2: 8,   # Attack
	3: 8,   # Howl
	4: 4,   # Damage
	5: 8,   # Death
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.5  # Very fast and aggressive
var is_attack_animating: bool = false

# Pending attack tracking
var pending_attack_name: String = ""

func _setup_boss() -> void:
	boss_name = "Wendigo"
	display_name = "THE HUNGER"
	elite_name = "Wendigo"
	enemy_type = "wendigo"

	# Boss stats (32x Minotaur: 1336.5 HP, 84 speed)
	speed = 150.0  # Very fast predator
	max_health = 42768.0  # 1336.5 * 32
	attack_damage = slash_damage
	base_damage = slash_damage
	attack_cooldown = 2.0
	windup_duration = WINDUP_DURATION
	animation_speed = 16.0  # Fast, frantic animations

	# Rewards (32x)
	xp_multiplier = 640.0
	coin_multiplier = 800.0
	guaranteed_drop = true

	# Enrage settings - becomes even more feral
	enrage_threshold = 0.35  # Early enrage
	enrage_damage_bonus = 0.50
	enrage_size_bonus = 0.20

	# Taunt settings - howl on spawn
	taunt_on_spawn = true
	taunt_count = 1
	taunt_speed_multiplier = 1.0

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_IDLE  # Same as idle
	ROW_ATTACK = ANIM_ATTACK
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_HOWL
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_HOWL]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false

	# Load slash texture
	slash_texture = load("res://assets/sprites/Slash.png")

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "howl",
			"range": 9999.0,
			"cooldown": 18.0,
			"priority": 2
		},
		{
			"type": AttackType.SPECIAL,
			"name": "pounce",
			"range": pounce_range,
			"cooldown": 6.0,
			"priority": 3
		},
		{
			"type": AttackType.SPECIAL,
			"name": "ravage",
			"range": slash_range + 20,
			"cooldown": 8.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "slash",
			"range": slash_range,
			"cooldown": 1.2,
			"priority": 8
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"howl":
			_start_howl()
		"pounce":
			_start_pounce()
		"ravage":
			_start_ravage()
		"slash":
			_start_slash()

func _start_howl() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.5
	current_attack_type = ANIM_HOWL
	animation_frame = 0.0
	current_row = ANIM_HOWL

func _start_pounce() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.3  # Quick pounce
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	# Store target
	if player and is_instance_valid(player):
		pounce_target = player.global_position
		var dir = (pounce_target - global_position).normalized()
		sprite.flip_h = dir.x < 0

	show_warning()

func _start_ravage() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.4
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK
	ravage_hit_count = 0

	show_warning()

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_slash() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.4
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return

	# Update howl buff
	if howl_active:
		howl_timer -= delta
		if howl_timer <= 0:
			_end_howl()

	# Handle pounce
	if is_pouncing:
		_process_pounce(delta)
		return

	# Handle ravage
	if is_ravaging:
		_process_ravage(delta)
		return

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	if is_attack_animating:
		return

	super._physics_process(delta)

func _process_windup(delta: float) -> void:
	attack_windup_timer -= delta

	animation_frame += animation_speed * 0.6 * delta
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var windup_frames = int(max_frames * 0.3)

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
		"howl":
			_execute_howl()
		"pounce":
			_begin_pounce()
		"ravage":
			_begin_ravage()
		"slash":
			_execute_slash()

func _execute_howl() -> void:
	howl_active = true
	howl_timer = HOWL_DURATION

	# Boost stats
	speed *= (1.0 + HOWL_SPEED_BONUS)
	attack_damage = base_damage * (1.0 + HOWL_DAMAGE_BONUS)
	if is_enraged:
		attack_damage *= (1.0 + enrage_damage_bonus)

	# Visual - red aura
	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.5, 0.8, 0.8, 1.0), 0.2)

	# Howl effect
	_spawn_howl_effect()

	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.chromatic_pulse(0.7)

	if HapticManager:
		HapticManager.heavy()

	can_attack = false
	_play_attack_followthrough()

func _spawn_howl_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Multiple expanding rings
	for i in range(3):
		var ring = Line2D.new()
		ring.width = 6.0 - i * 1.5
		ring.default_color = Color(0.9, 0.3, 0.3, 0.8 - i * 0.2)
		ring.z_index = -1

		var points: Array[Vector2] = []
		var segments = 24
		var base_radius = 30.0 + i * 20
		for j in range(segments + 1):
			var angle = (float(j) / segments) * TAU
			points.append(Vector2(cos(angle), sin(angle)) * base_radius)
		ring.points = points

		effect.add_child(ring)

		var tween = ring.create_tween()
		tween.tween_property(ring, "scale", Vector2(10.0, 10.0), 0.6 + i * 0.1)
		tween.parallel().tween_property(ring, "modulate:a", 0.0, 0.6 + i * 0.1)

	var cleanup_timer = get_tree().create_timer(1.0)
	cleanup_timer.timeout.connect(effect.queue_free)

func _end_howl() -> void:
	howl_active = false
	speed = 150.0
	attack_damage = base_damage
	if is_enraged:
		attack_damage *= (1.0 + enrage_damage_bonus)

	if sprite:
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.3)

func _begin_pounce() -> void:
	is_pouncing = true

	# Calculate pounce direction
	if player and is_instance_valid(player):
		pounce_target = player.global_position

	var direction = (pounce_target - global_position).normalized()
	velocity = direction * pounce_speed

	sprite.flip_h = direction.x < 0

func _process_pounce(delta: float) -> void:
	# Animate attack during pounce
	animation_frame += animation_speed * 2.0 * delta
	var max_frames = FRAME_COUNTS.get(ANIM_ATTACK, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ANIM_ATTACK * COLS_PER_ROW + frame_index

	# Move toward target
	move_and_slide()

	# Check if reached target or close to player
	var dist_to_target = global_position.distance_to(pounce_target)
	var dist_to_player = 9999.0
	if player and is_instance_valid(player):
		dist_to_player = global_position.distance_to(player.global_position)

	if dist_to_target < 50 or dist_to_player < 80:
		_end_pounce()

func _end_pounce() -> void:
	is_pouncing = false
	velocity = Vector2.ZERO

	# Deal damage if player is close
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= 100:
			var damage = pounce_damage
			if howl_active:
				damage *= (1.0 + HOWL_DAMAGE_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

			# Ravenous heal
			_ravenous_heal(damage)

	# Spawn slash effect
	_spawn_slash_effect()

	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.hitstop_medium()

	if HapticManager:
		HapticManager.heavy()

	can_attack = false
	current_row = ROW_IDLE

func _begin_ravage() -> void:
	is_ravaging = true
	ravage_hit_count = 0
	ravage_timer = 0.0

func _process_ravage(delta: float) -> void:
	ravage_timer += delta

	# Animate rapidly
	animation_frame += animation_speed * 2.5 * delta
	var max_frames = FRAME_COUNTS.get(ANIM_ATTACK, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ANIM_ATTACK * COLS_PER_ROW + frame_index

	# Deal damage at intervals
	if ravage_timer >= RAVAGE_INTERVAL:
		ravage_timer = 0.0
		_ravage_hit()
		ravage_hit_count += 1

		if ravage_hit_count >= ravage_hits:
			_end_ravage()
			return

	# Keep close to player
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		velocity = dir * speed * 0.5
		sprite.flip_h = dir.x < 0
		move_and_slide()

func _ravage_hit() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= slash_range + 30:
			var damage = ravage_damage
			if howl_active:
				damage *= (1.0 + HOWL_DAMAGE_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

			# Ravenous heal
			_ravenous_heal(damage)

			# Spawn slash effect
			_spawn_slash_effect()

			if JuiceManager:
				JuiceManager.shake_small()

func _end_ravage() -> void:
	is_ravaging = false
	velocity = Vector2.ZERO
	can_attack = false
	current_row = ROW_IDLE

	if JuiceManager:
		JuiceManager.shake_medium()

func _execute_slash() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= slash_range:
			var damage = slash_damage
			if howl_active:
				damage *= (1.0 + HOWL_DAMAGE_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

			# Ravenous heal
			_ravenous_heal(damage)

	_spawn_slash_effect()

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false
	_play_attack_followthrough()

func _spawn_slash_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position

	# Position slash in front of Wendigo
	var offset_dir = Vector2.RIGHT if not sprite.flip_h else Vector2.LEFT
	effect.global_position += offset_dir * 50

	get_parent().add_child(effect)

	var slash_sprite = Sprite2D.new()
	if slash_texture:
		slash_sprite.texture = slash_texture
		slash_sprite.hframes = 2  # 2 frames
		slash_sprite.vframes = 1
		slash_sprite.frame = 0
	slash_sprite.scale = Vector2(3.0, 3.0)
	slash_sprite.flip_h = sprite.flip_h
	slash_sprite.modulate = Color(1.0, 0.8, 0.8, 0.9)
	effect.add_child(slash_sprite)

	# Animate slash
	var tween = effect.create_tween()
	tween.tween_property(slash_sprite, "frame", 1, 0.1)
	tween.tween_property(slash_sprite, "modulate:a", 0.0, 0.15)
	tween.tween_callback(effect.queue_free)

func _ravenous_heal(damage_dealt: float) -> void:
	var heal_amount = damage_dealt * RAVENOUS_HEAL_PERCENT
	current_health = minf(current_health + heal_amount, max_health)
	emit_signal("boss_health_changed", current_health, max_health)

func _play_attack_followthrough() -> void:
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var start_frame = int(max_frames * 0.3)
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
	var max_frames = FRAME_COUNTS.get(ROW_DEATH, 8)

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

	if direction.x != 0:
		sprite.flip_h = direction.x < 0

	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 4)
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
