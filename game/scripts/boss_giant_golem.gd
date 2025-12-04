extends BossBase

# Giant Golem Boss - "The Ancient Construct"
# Inspired by Stone Golems (Diablo), Earth Elementals (WoW)
# Attacks: Ground Pound (AOE), Rock Throw (ranged), Earthquake, Stone Shield
# Tier: Nightmare (8x Minotaur power)

@export var rock_projectile_scene: PackedScene

# Attack damage values (8x Minotaur base)
@export var pound_damage: float = 200.0  # 50 * 4
@export var rock_damage: float = 150.0
@export var earthquake_damage: float = 40.0  # Per tick

# Attack ranges
@export var pound_range: float = 130.0
@export var pound_aoe_radius: float = 200.0
@export var rock_range: float = 400.0
@export var earthquake_radius: float = 250.0

# Spritesheet config: 96x96 frames, 10 cols x 6 rows
const SPRITE_COLS: int = 10
const SPRITE_ROWS: int = 6

# Animation rows
const ANIM_IDLE: int = 0
const ANIM_ATTACK1: int = 1  # Ground pound
const ANIM_ATTACK2: int = 2  # Rock throw
const ANIM_MOVE: int = 3
const ANIM_DAMAGE: int = 4
const ANIM_DEATH: int = 5

# Frame counts per animation
const FRAMES = {
	0: 6,   # Idle
	1: 8,   # Attack1 (pound)
	2: 8,   # Attack2 (rock throw)
	3: 8,   # Move
	4: 5,   # Damage
	5: 9,   # Death
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 1.0  # Slow but powerful
var is_attack_animating: bool = false

# Stone Shield state
var stone_shield_active: bool = false
var stone_shield_timer: float = 0.0
const STONE_SHIELD_DURATION: float = 6.0
const STONE_SHIELD_REDUCTION: float = 0.6  # 60% damage reduction

# Earthquake state
var earthquake_zones: Array[Node2D] = []

# Rock Blast sprite for projectiles
var rock_blast_texture: Texture2D = null

func _setup_boss() -> void:
	boss_name = "GiantGolem"
	display_name = "THE ANCIENT CONSTRUCT"
	elite_name = "Giant Golem"
	enemy_type = "giant_golem"

	# Boss stats (8x Minotaur: 1336.5 HP, 84 speed)
	speed = 60.0  # Slow but terrifying
	max_health = 10692.0  # 1336.5 * 8
	attack_damage = pound_damage
	base_damage = pound_damage
	attack_cooldown = 4.0
	windup_duration = WINDUP_DURATION
	animation_speed = 8.0  # Slower animations

	# Rewards (8x)
	xp_multiplier = 160.0
	coin_multiplier = 200.0
	guaranteed_drop = true

	# Enrage settings
	enrage_threshold = 0.25
	enrage_damage_bonus = 0.40  # +40% damage when enraged
	enrage_size_bonus = 0.15

	# Taunt settings
	taunt_on_spawn = true
	taunt_count = 1
	taunt_speed_multiplier = 0.8  # Slow, menacing taunt

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_MOVE
	ROW_ATTACK = ANIM_ATTACK1
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_IDLE  # Use idle as taunt (menacing stance)
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_IDLE]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false

	# Load rock blast texture
	rock_blast_texture = load("res://assets/sprites/Rock Blast Sprite Sheet.png")

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "stone_shield",
			"range": 9999.0,
			"cooldown": 20.0,
			"priority": 2
		},
		{
			"type": AttackType.SPECIAL,
			"name": "earthquake",
			"range": 200.0,
			"cooldown": 12.0,
			"priority": 3
		},
		{
			"type": AttackType.RANGED,
			"name": "rock_throw",
			"range": rock_range,
			"cooldown": 5.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "ground_pound",
			"range": pound_range,
			"cooldown": 3.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	pending_attack_name = attack.name
	match attack.name:
		"stone_shield":
			_start_stone_shield()
		"earthquake":
			_start_earthquake()
		"rock_throw":
			_start_rock_throw()
		"ground_pound":
			_start_ground_pound()

func _start_stone_shield() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.5
	current_attack_type = ANIM_IDLE  # Defensive stance
	animation_frame = 0.0
	current_row = ANIM_IDLE

func _start_earthquake() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 1.2
	current_attack_type = ANIM_ATTACK1
	animation_frame = 0.0
	current_row = ANIM_ATTACK1

	show_warning()

	if JuiceManager:
		JuiceManager.shake_small()

func _start_rock_throw() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.8
	current_attack_type = ANIM_ATTACK2
	animation_frame = 0.0
	current_row = ANIM_ATTACK2

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_ground_pound() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION
	current_attack_type = ANIM_ATTACK1
	animation_frame = 0.0
	current_row = ANIM_ATTACK1

	show_warning()

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _physics_process(delta: float) -> void:
	if is_dying:
		_process_death_animation(delta)
		return

	# Update stone shield
	if stone_shield_active:
		stone_shield_timer -= delta
		if stone_shield_timer <= 0:
			_end_stone_shield()

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	if is_attack_animating:
		return

	super._physics_process(delta)

func _process_windup(delta: float) -> void:
	attack_windup_timer -= delta

	animation_frame += animation_speed * 0.4 * delta  # Slow windup
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var windup_frames = int(max_frames * 0.5)

	if animation_frame > windup_frames:
		animation_frame = float(windup_frames)

	var frame_index = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = current_row * COLS_PER_ROW + frame_index

	if attack_windup_timer <= 0:
		is_winding_up = false
		_execute_current_attack()

var pending_attack_name: String = ""

func _execute_current_attack() -> void:
	hide_warning()

	match pending_attack_name:
		"stone_shield":
			_execute_stone_shield()
		"earthquake":
			_execute_earthquake()
		"rock_throw":
			_execute_rock_throw()
		"ground_pound":
			_execute_ground_pound()

	_play_attack_followthrough()

func _execute_stone_shield() -> void:
	stone_shield_active = true
	stone_shield_timer = STONE_SHIELD_DURATION

	# Visual feedback - rocky/gray overlay
	if sprite:
		sprite.modulate = Color(0.7, 0.7, 0.8, 1.0)

	# Create shield visual
	_spawn_shield_effect()

	if JuiceManager:
		JuiceManager.shake_small()

	can_attack = false

func _spawn_shield_effect() -> void:
	# Create a pulsing rocky aura
	var effect = Node2D.new()
	effect.name = "ShieldEffect"
	add_child(effect)

	var circle = Line2D.new()
	circle.width = 15.0
	circle.default_color = Color(0.5, 0.5, 0.6, 0.6)
	circle.z_index = -1

	var points: Array[Vector2] = []
	var segments = 24
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 80)
	circle.points = points

	effect.add_child(circle)

	# Pulse animation
	var tween = create_tween().set_loops()
	tween.tween_property(effect, "scale", Vector2(1.1, 1.1), 0.5)
	tween.tween_property(effect, "scale", Vector2(0.9, 0.9), 0.5)

func _end_stone_shield() -> void:
	stone_shield_active = false

	if sprite:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

	# Remove shield effect
	var shield = get_node_or_null("ShieldEffect")
	if shield:
		shield.queue_free()

func _execute_earthquake() -> void:
	# Create multiple damage zones
	for i in range(5):
		var angle = randf() * TAU
		var distance = randf_range(50, earthquake_radius)
		var zone_pos = global_position + Vector2(cos(angle), sin(angle)) * distance
		_spawn_earthquake_zone(zone_pos)

	# Central zone
	_spawn_earthquake_zone(global_position)

	if JuiceManager:
		JuiceManager.shake_large()

	if HapticManager:
		HapticManager.heavy()

	can_attack = false

func _spawn_earthquake_zone(pos: Vector2) -> void:
	var zone = Node2D.new()
	zone.global_position = pos
	get_parent().add_child(zone)

	# Warning indicator
	var warning = Line2D.new()
	warning.width = 4.0
	warning.default_color = Color(0.8, 0.4, 0.2, 0.7)
	warning.z_index = -1

	var points: Array[Vector2] = []
	var segments = 20
	var radius = 60.0
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	warning.points = points

	zone.add_child(warning)

	# After delay, deal damage
	var timer = Timer.new()
	timer.wait_time = 0.5
	timer.one_shot = true
	zone.add_child(timer)
	timer.start()
	timer.timeout.connect(_earthquake_hit.bind(zone, radius))

func _earthquake_hit(zone: Node2D, radius: float) -> void:
	if player and is_instance_valid(player):
		var dist = zone.global_position.distance_to(player.global_position)
		if dist <= radius:
			var damage = earthquake_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	# Visual explosion
	var line = zone.get_child(0) as Line2D
	if line:
		line.default_color = Color(1.0, 0.5, 0.2, 1.0)
		var tween = zone.create_tween()
		tween.tween_property(line, "modulate:a", 0.0, 0.3)
		tween.tween_callback(zone.queue_free)

func _execute_rock_throw() -> void:
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		_spawn_rock_projectile(dir)

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

func _spawn_rock_projectile(direction: Vector2) -> void:
	# Create rock projectile
	var rock = Area2D.new()
	rock.global_position = global_position + direction * 50
	rock.collision_layer = 0
	rock.collision_mask = 1  # Hit player

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 25.0
	collision.shape = shape
	rock.add_child(collision)

	# Rock sprite using Rock Blast texture
	var rock_sprite = Sprite2D.new()
	if rock_blast_texture:
		rock_sprite.texture = rock_blast_texture
		rock_sprite.hframes = 4
		rock_sprite.vframes = 1
		rock_sprite.frame = 0
	rock_sprite.scale = Vector2(2.0, 2.0)
	rock.add_child(rock_sprite)

	get_parent().add_child(rock)

	# Animate the rock sprite
	var frame_tween = rock.create_tween().set_loops()
	frame_tween.tween_property(rock_sprite, "frame", 3, 0.3)
	frame_tween.tween_property(rock_sprite, "frame", 0, 0.0)

	# Movement
	var target_pos = global_position + direction * rock_range
	var move_tween = rock.create_tween()
	var travel_time = rock_range / 400.0  # Speed of 400
	move_tween.tween_property(rock, "global_position", target_pos, travel_time)
	move_tween.tween_callback(rock.queue_free)

	# Connect hit detection
	rock.body_entered.connect(_on_rock_hit_player.bind(rock))

func _on_rock_hit_player(body: Node2D, rock: Area2D) -> void:
	if body == player and is_instance_valid(player):
		var damage = rock_damage
		if is_enraged:
			damage *= (1.0 + enrage_damage_bonus)
		if player.has_method("take_damage"):
			player.take_damage(damage)

		if JuiceManager:
			JuiceManager.shake_medium()

		rock.queue_free()

func _execute_ground_pound() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= pound_aoe_radius:
			var damage = pound_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	_spawn_pound_effect()

	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.hitstop_medium()

	if HapticManager:
		HapticManager.heavy()

	can_attack = false

func _spawn_pound_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	var line = Line2D.new()
	line.width = 12.0
	line.default_color = Color(0.6, 0.5, 0.4, 0.9)
	line.z_index = -1

	var points: Array[Vector2] = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * pound_aoe_radius)
	line.points = points

	effect.add_child(line)

	var tween = effect.create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.5)
	tween.parallel().tween_property(effect, "scale", Vector2(1.3, 1.3), 0.5)
	tween.tween_callback(effect.queue_free)

# Override take_damage for stone shield
func take_damage(amount: float, is_crit: bool = false) -> void:
	var actual_damage = amount
	if stone_shield_active:
		actual_damage *= (1.0 - STONE_SHIELD_REDUCTION)
	super.take_damage(actual_damage, is_crit)

func _play_attack_followthrough() -> void:
	var max_frames = FRAME_COUNTS.get(current_attack_type, 5)
	var start_frame = int(max_frames * 0.5)
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
