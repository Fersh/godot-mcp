extends BossBase

# Lizardfolk King Boss - "The Swamp Tyrant"
# Inspired by Murlocs (WoW), Hydra (Hades), K'ril Tsutsaroth
# Attacks: Claw Swipe, Taunt (debuff), Tail Sweep (360), Poison Spit (DOT)
# Tier: Hell (16x Minotaur power)

@export var poison_projectile_scene: PackedScene

# Attack damage values (16x Minotaur base)
@export var claw_damage: float = 352.0  # 22 * 16
@export var tail_damage: float = 280.0
@export var poison_damage: float = 50.0  # Initial hit
@export var poison_dot_damage: float = 30.0  # Per tick
@export var poison_dot_duration: float = 4.0
@export var poison_dot_interval: float = 0.5

# Attack ranges
@export var claw_range: float = 120.0
@export var tail_sweep_radius: float = 180.0
@export var poison_range: float = 350.0

# Spritesheet config: 128x64 frames, 8 cols x 6 rows
const SPRITE_COLS: int = 8
const SPRITE_ROWS: int = 6

# Animation rows
const ANIM_IDLE: int = 0
const ANIM_TAUNT: int = 1
const ANIM_MOVE: int = 2
const ANIM_ATTACK: int = 3
const ANIM_DAMAGE: int = 4
const ANIM_DEATH: int = 5

# Frame counts per animation
const FRAMES = {
	0: 8,   # Idle
	1: 8,   # Taunt
	2: 8,   # Move
	3: 8,   # Attack
	4: 5,   # Damage
	5: 8,   # Death
}

# Attack state
var current_attack_type: int = 0
var attack_windup_timer: float = 0.0
const WINDUP_DURATION: float = 0.6  # Fast and deadly
var is_attack_animating: bool = false

# Intimidation debuff (from taunt)
var player_intimidated: bool = false
var intimidation_timer: float = 0.0
const INTIMIDATION_DURATION: float = 5.0
const INTIMIDATION_DAMAGE_TAKEN_BONUS: float = 0.25  # Player takes 25% more damage

# Cold Blooded regeneration
const REGEN_AMOUNT: float = 50.0  # HP per second
const REGEN_DELAY: float = 3.0  # Seconds after taking damage before regen starts
var regen_cooldown: float = 0.0

# Pending attack tracking
var pending_attack_name: String = ""

func _setup_boss() -> void:
	boss_name = "LizardfolkKing"
	display_name = "THE SWAMP TYRANT"
	elite_name = "Lizardfolk King"
	enemy_type = "lizardfolk_king"

	# Boss stats (16x Minotaur: 1336.5 HP, 84 speed)
	speed = 130.0  # Very fast
	max_health = 21384.0  # 1336.5 * 16
	attack_damage = claw_damage
	base_damage = claw_damage
	attack_cooldown = 2.5
	windup_duration = WINDUP_DURATION
	animation_speed = 14.0  # Fast animations

	# Rewards (16x)
	xp_multiplier = 320.0
	coin_multiplier = 400.0
	guaranteed_drop = true

	# Enrage settings
	enrage_threshold = 0.30
	enrage_damage_bonus = 0.45
	enrage_size_bonus = 0.18

	# Taunt settings
	taunt_on_spawn = true
	taunt_count = 1
	taunt_speed_multiplier = 1.2

	# Animation setup
	ROW_IDLE = ANIM_IDLE
	ROW_MOVE = ANIM_MOVE
	ROW_ATTACK = ANIM_ATTACK
	ROW_DAMAGE = ANIM_DAMAGE
	ROW_DEATH = ANIM_DEATH
	ROW_TAUNT = ANIM_TAUNT
	COLS_PER_ROW = SPRITE_COLS
	FRAMES_TAUNT = FRAMES[ANIM_TAUNT]

	FRAME_COUNTS = FRAMES.duplicate()

	current_health = max_health
	if health_bar:
		health_bar.visible = false

	# Define available attacks
	available_attacks = [
		{
			"type": AttackType.SPECIAL,
			"name": "intimidate",
			"range": 300.0,
			"cooldown": 15.0,
			"priority": 2
		},
		{
			"type": AttackType.SPECIAL,
			"name": "tail_sweep",
			"range": tail_sweep_radius,
			"cooldown": 7.0,
			"priority": 4
		},
		{
			"type": AttackType.RANGED,
			"name": "poison_spit",
			"range": poison_range,
			"cooldown": 4.0,
			"priority": 5
		},
		{
			"type": AttackType.MELEE,
			"name": "claw_swipe",
			"range": claw_range,
			"cooldown": 1.5,
			"priority": 8
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"intimidate":
			_start_intimidate()
		"tail_sweep":
			_start_tail_sweep()
		"poison_spit":
			_start_poison_spit()
		"claw_swipe":
			_start_claw_swipe()

func _start_intimidate() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 1.5
	current_attack_type = ANIM_TAUNT
	animation_frame = 0.0
	current_row = ANIM_TAUNT

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_tail_sweep() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	show_warning()

func _start_poison_spit() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.7
	current_attack_type = ANIM_ATTACK
	animation_frame = 0.0
	current_row = ANIM_ATTACK

	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		sprite.flip_h = dir.x < 0

func _start_claw_swipe() -> void:
	is_winding_up = true
	attack_windup_timer = WINDUP_DURATION * 0.5  # Very fast
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

	# Cold Blooded regeneration
	if regen_cooldown > 0:
		regen_cooldown -= delta
	elif current_health < max_health and not is_enraged:
		current_health = minf(current_health + REGEN_AMOUNT * delta, max_health)
		emit_signal("boss_health_changed", current_health, max_health)

	# Handle attack windup
	if is_winding_up:
		_process_windup(delta)
		return

	if is_attack_animating:
		return

	super._physics_process(delta)

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
		"intimidate":
			_execute_intimidate()
		"tail_sweep":
			_execute_tail_sweep()
		"poison_spit":
			_execute_poison_spit()
		"claw_swipe":
			_execute_claw_swipe()

	_play_attack_followthrough()

func _execute_intimidate() -> void:
	# Apply debuff to player
	player_intimidated = true
	intimidation_timer = INTIMIDATION_DURATION

	# Visual: green miasma effect
	_spawn_intimidation_effect()

	# Roar visual
	if JuiceManager:
		JuiceManager.shake_medium()
		JuiceManager.chromatic_pulse(0.5)

	if HapticManager:
		HapticManager.medium()

	can_attack = false

func _spawn_intimidation_effect() -> void:
	# Create expanding green wave
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	var wave = Line2D.new()
	wave.width = 8.0
	wave.default_color = Color(0.2, 0.8, 0.3, 0.8)
	wave.z_index = -1

	var points: Array[Vector2] = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 50)
	wave.points = points

	effect.add_child(wave)

	var tween = effect.create_tween()
	tween.tween_property(effect, "scale", Vector2(6.0, 6.0), 0.5)
	tween.parallel().tween_property(wave, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func _execute_tail_sweep() -> void:
	# 360 degree attack
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= tail_sweep_radius:
			var damage = tail_damage
			if player_intimidated:
				damage *= (1.0 + INTIMIDATION_DAMAGE_TAKEN_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	_spawn_tail_sweep_effect()

	if JuiceManager:
		JuiceManager.shake_large()
		JuiceManager.hitstop_small()

	can_attack = false

func _spawn_tail_sweep_effect() -> void:
	var effect = Node2D.new()
	effect.global_position = global_position
	get_parent().add_child(effect)

	# Spinning arc effect
	var arc = Line2D.new()
	arc.width = 15.0
	arc.default_color = Color(0.3, 0.7, 0.3, 0.9)
	arc.z_index = -1

	var points: Array[Vector2] = []
	var segments = 32
	for i in range(segments + 1):
		var angle = (float(i) / segments) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * tail_sweep_radius)
	arc.points = points

	effect.add_child(arc)

	# Spin and fade
	var tween = effect.create_tween()
	tween.tween_property(effect, "rotation", TAU, 0.3)
	tween.parallel().tween_property(arc, "modulate:a", 0.0, 0.4)
	tween.tween_callback(effect.queue_free)

func _execute_poison_spit() -> void:
	if player and is_instance_valid(player):
		var dir = (player.global_position - global_position).normalized()
		_spawn_poison_projectile(dir)

	if JuiceManager:
		JuiceManager.shake_small()

	can_attack = false

func _spawn_poison_projectile(direction: Vector2) -> void:
	var projectile = Area2D.new()
	projectile.global_position = global_position + direction * 40
	projectile.collision_layer = 0
	projectile.collision_mask = 1

	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 20.0
	collision.shape = shape
	projectile.add_child(collision)

	# Green poison blob sprite
	var blob = Node2D.new()
	projectile.add_child(blob)

	# Draw a simple blob
	var circle = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(8):
		var angle = (float(i) / 8) * TAU
		var radius = 15.0 + randf_range(-3, 3)
		points.append(Vector2(cos(angle), sin(angle)) * radius)
	circle.polygon = points
	circle.color = Color(0.3, 0.9, 0.2, 0.9)
	blob.add_child(circle)

	get_parent().add_child(projectile)

	# Movement toward player
	var target = player.global_position if player and is_instance_valid(player) else global_position + direction * 300
	var move_tween = projectile.create_tween()
	move_tween.tween_property(projectile, "global_position", target, 0.5)
	move_tween.tween_callback(func(): _poison_explode(projectile))

	projectile.body_entered.connect(_on_poison_hit.bind(projectile))

func _on_poison_hit(body: Node2D, projectile: Area2D) -> void:
	if body == player:
		_poison_explode(projectile)

func _poison_explode(projectile: Area2D) -> void:
	if not is_instance_valid(projectile):
		return

	var hit_pos = projectile.global_position

	# Initial damage
	if player and is_instance_valid(player):
		var dist = hit_pos.distance_to(player.global_position)
		if dist <= 60:
			var damage = poison_damage
			if player_intimidated:
				damage *= (1.0 + INTIMIDATION_DAMAGE_TAKEN_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

			# Apply poison DOT
			_apply_poison_dot()

	# Explosion effect
	var effect = Node2D.new()
	effect.global_position = hit_pos
	get_parent().add_child(effect)

	var splash = Polygon2D.new()
	var points: PackedVector2Array = []
	for i in range(12):
		var angle = (float(i) / 12) * TAU
		points.append(Vector2(cos(angle), sin(angle)) * 40)
	splash.polygon = points
	splash.color = Color(0.3, 0.9, 0.2, 0.7)
	effect.add_child(splash)

	var tween = effect.create_tween()
	tween.tween_property(effect, "scale", Vector2(1.5, 1.5), 0.3)
	tween.parallel().tween_property(splash, "color:a", 0.0, 0.3)
	tween.tween_callback(effect.queue_free)

	projectile.queue_free()

func _apply_poison_dot() -> void:
	# Create a timer-based DOT on the player
	if not player or not is_instance_valid(player):
		return

	var dot_timer = Timer.new()
	dot_timer.wait_time = poison_dot_interval
	dot_timer.one_shot = false
	get_tree().root.add_child(dot_timer)

	var ticks_remaining = int(poison_dot_duration / poison_dot_interval)

	dot_timer.timeout.connect(func():
		if player and is_instance_valid(player) and player.has_method("take_damage"):
			var damage = poison_dot_damage
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			player.take_damage(damage)

		ticks_remaining -= 1
		if ticks_remaining <= 0:
			dot_timer.stop()
			dot_timer.queue_free()
	)

	dot_timer.start()

func _execute_claw_swipe() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= claw_range:
			var damage = claw_damage
			if player_intimidated:
				damage *= (1.0 + INTIMIDATION_DAMAGE_TAKEN_BONUS)
			if is_enraged:
				damage *= (1.0 + enrage_damage_bonus)
			if player.has_method("take_damage"):
				player.take_damage(damage)

	if JuiceManager:
		JuiceManager.shake_medium()

	can_attack = false

# Override take_damage for regen cooldown
func take_damage(amount: float, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)
	regen_cooldown = REGEN_DELAY  # Reset regen timer when hit

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
