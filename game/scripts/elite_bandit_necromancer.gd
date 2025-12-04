extends EliteBase

# Elite Bandit Necromancer - "Lich King Mortanius"
# A powerful undead summoner with devastating dark magic
# Inspired by WoW Kel'Thuzad and Diablo Skeleton King
#
# Three attack types:
# 1. Shadow Bolt - Fast dark magic projectile
# 2. Raise Dead - Summons 3-4 undead minions
# 3. Army of the Damned - Summons many weak undead that explode on death
#
# Bandit Necromancer Sprite Sheet: 8 cols x 6 rows, 32x32 per frame
# Row 0: Idle (8 frames)
# Row 1: Move (8 frames)
# Row 2: Cast 1 (8 frames) - Summon
# Row 3: Cast 2 (8 frames) - Attack spell
# Row 4: Damaged (4 frames)
# Row 5: Death (8 frames)

@export var spell_projectile_scene: PackedScene
@export var skeleton_scene: PackedScene
@export var ghoul_scene: PackedScene

# Attack-specific stats
@export var shadow_bolt_damage: float = 18.0
@export var shadow_bolt_range: float = 280.0
@export var shadow_bolt_speed: float = 160.0

@export var raise_dead_count: int = 4
@export var raise_dead_range: float = 250.0

@export var army_count: int = 10
@export var army_telegraph_time: float = 1.5
@export var army_range: float = 300.0
@export var army_explosion_damage: float = 15.0
@export var army_explosion_radius: float = 60.0

# Animation rows
var ROW_SUMMON: int = 2
var ROW_CAST: int = 3

# Attack states
var shadow_bolt_active: bool = false
var shadow_bolt_windup_timer: float = 0.0
const SHADOW_BOLT_WINDUP: float = 0.4

var raise_dead_active: bool = false
var raise_dead_windup_timer: float = 0.0
const RAISE_DEAD_WINDUP: float = 0.7

var army_active: bool = false
var army_telegraphing: bool = false
var army_telegraph_timer: float = 0.0
var army_warning_label: Label = null
var army_warning_tween: Tween = null
var army_minions: Array[Node] = []

# Track active summons
var active_summons: Array[Node] = []
const MAX_SUMMONS: int = 8

# Preferred range - stay back and summon
var preferred_range: float = 200.0

func _setup_elite() -> void:
	elite_name = "Lich King Mortanius"
	enemy_type = "bandit_necromancer_elite"

	# Stats - fragile caster, relies on summons
	speed = 45.0  # Slow
	max_health = 480.0  # Lower HP
	attack_damage = shadow_bolt_damage
	attack_cooldown = 1.2
	windup_duration = 0.5
	animation_speed = 9.0

	# Bandit Necromancer spritesheet: 8 cols x 6 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_SUMMON = 2
	ROW_CAST = 3
	ROW_ATTACK = 3
	ROW_DAMAGE = 4
	ROW_DEATH = 5
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 8,   # IDLE
		1: 8,   # MOVE
		2: 8,   # SUMMON
		3: 8,   # CAST
		4: 4,   # DAMAGED
		5: 8,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up for elite size
	if sprite:
		sprite.scale = Vector2(3.8, 3.8)
		# Dark purple necromancer tint
		sprite.modulate = Color(0.85, 0.75, 0.95, 1.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.RANGED,
			"name": "shadow_bolt",
			"range": shadow_bolt_range,
			"cooldown": 2.5,
			"priority": 4
		},
		{
			"type": AttackType.RANGED,
			"name": "raise_dead",
			"range": raise_dead_range,
			"cooldown": 8.0,
			"priority": 6
		},
		{
			"type": AttackType.SPECIAL,
			"name": "army_of_the_damned",
			"range": army_range,
			"cooldown": 20.0,
			"priority": 7
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"shadow_bolt":
			_start_shadow_bolt()
		"raise_dead":
			_start_raise_dead()
		"army_of_the_damned":
			_start_army_of_the_damned()

# Override behavior for kiting
func _process_behavior(delta: float) -> void:
	# Clean up dead summons
	_cleanup_summons()

	if is_using_special:
		_process_special_attack(delta)
		return

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		var distance = direction.length()
		var dir_normalized = direction.normalized()

		# Maintain safe distance
		if distance < preferred_range * 0.5:
			velocity = -dir_normalized * speed * 1.3
			move_and_slide()
			update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance < preferred_range:
			velocity = -dir_normalized * speed * 0.6
			move_and_slide()

			var best_attack = _select_best_attack(distance)
			if not best_attack.is_empty() and can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_MOVE, -dir_normalized)
		elif distance > shadow_bolt_range:
			velocity = dir_normalized * speed
			move_and_slide()
			update_animation(delta, ROW_MOVE, dir_normalized)
		else:
			velocity = Vector2.ZERO

			var best_attack = _select_best_attack(distance)
			if not best_attack.is_empty() and can_attack and attack_cooldowns[best_attack.name] <= 0:
				current_attack = best_attack
				_start_elite_attack(best_attack)
			else:
				update_animation(delta, ROW_IDLE, dir_normalized)
	else:
		velocity = Vector2.ZERO
		update_animation(delta, ROW_IDLE, Vector2.ZERO)

func _cleanup_summons() -> void:
	var alive = active_summons.filter(func(s): return is_instance_valid(s) and not s.is_dying)
	active_summons = alive

# ============================================
# SHADOW BOLT
# ============================================

func _start_shadow_bolt() -> void:
	shadow_bolt_active = true
	shadow_bolt_windup_timer = SHADOW_BOLT_WINDUP

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_CAST, dir)
	animation_frame = 0

func _execute_shadow_bolt() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Create shadow bolt
	var proj_scene = spell_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 25

		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = shadow_bolt_speed
		if "damage" in proj:
			proj.damage = shadow_bolt_damage

		# Dark purple shadow color
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(0.5, 0.2, 0.7)
			proj.get_node("Sprite2D").scale = Vector2(1.3, 1.3)
		elif proj.has_node("Sprite"):
			proj.get_node("Sprite").modulate = Color(0.5, 0.2, 0.7)
			proj.get_node("Sprite").scale = Vector2(1.3, 1.3)

		get_parent().add_child(proj)

# ============================================
# RAISE DEAD
# ============================================

func _start_raise_dead() -> void:
	raise_dead_active = true
	raise_dead_windup_timer = RAISE_DEAD_WINDUP
	show_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_SUMMON, dir)
	animation_frame = 0

func _execute_raise_dead() -> void:
	hide_warning()

	# Clear old summons if at cap
	while active_summons.size() >= MAX_SUMMONS:
		var oldest = active_summons.pop_front()
		if is_instance_valid(oldest) and oldest.has_method("take_damage"):
			oldest.take_damage(oldest.max_health)

	# Summon undead around the necromancer
	for i in range(raise_dead_count):
		var angle = (TAU / raise_dead_count) * i + randf_range(-0.3, 0.3)
		var offset = Vector2(cos(angle), sin(angle)) * (60 + randf() * 40)
		_spawn_undead_minion(global_position + offset)

	if JuiceManager:
		JuiceManager.shake_small()

func _spawn_undead_minion(spawn_pos: Vector2) -> void:
	# Randomly choose skeleton or ghoul
	var scene = skeleton_scene if randf() > 0.5 else ghoul_scene
	if scene == null:
		scene = load("res://scenes/enemy_skeleton.tscn")
	if scene == null:
		scene = load("res://scenes/enemy_ghoul.tscn")

	if scene:
		var minion = scene.instantiate()
		minion.global_position = spawn_pos
		get_parent().add_child(minion)

		# Make summoned minions weaker
		if minion.has_method("_on_ready"):
			minion._on_ready()

		minion.max_health *= 0.4
		minion.current_health = minion.max_health
		minion.attack_damage *= 0.5

		# Visual distinction - purple necromantic tint
		if minion.has_node("Sprite"):
			minion.get_node("Sprite").modulate = Color(0.6, 0.5, 0.8, 1.0)
		elif minion.has_node("Sprite2D"):
			minion.get_node("Sprite2D").modulate = Color(0.6, 0.5, 0.8, 1.0)

		active_summons.append(minion)

# ============================================
# ARMY OF THE DAMNED (Special Attack)
# ============================================

func _start_army_of_the_damned() -> void:
	show_warning()
	is_using_special = true

	army_telegraphing = true
	army_telegraph_timer = army_telegraph_time
	special_timer = army_telegraph_time + 3.0

	_show_army_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_SUMMON, dir)
	animation_frame = 0

func _execute_army_of_the_damned() -> void:
	army_telegraphing = false
	army_active = true
	_hide_army_warning()

	# Spawn army of exploding minions
	for i in range(army_count):
		var angle = (TAU / army_count) * i + randf_range(-0.2, 0.2)
		var radius = 80 + randf() * 60
		var offset = Vector2(cos(angle), sin(angle)) * radius
		_spawn_exploding_minion(global_position + offset, i * 0.1)

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_exploding_minion(spawn_pos: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay).timeout

	if is_dying:
		return

	# Create simple exploding ghost
	var minion = CharacterBody2D.new()
	minion.global_position = spawn_pos
	minion.collision_layer = 4
	minion.collision_mask = 0
	minion.set_meta("is_exploding_minion", true)
	minion.set_meta("explosion_damage", army_explosion_damage)
	minion.set_meta("explosion_radius", army_explosion_radius)

	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.5, 0.3, 0.6, 0.8)
	visual.name = "Visual"
	minion.add_child(visual)

	get_parent().add_child(minion)
	army_minions.append(minion)

	# Chase player and explode on contact or after time
	_process_exploding_minion(minion)

func _process_exploding_minion(minion: Node) -> void:
	var lifetime = 5.0
	var elapsed = 0.0
	var move_speed = 100.0

	while elapsed < lifetime and is_instance_valid(minion):
		var delta = get_process_delta_time()
		elapsed += delta

		if player and is_instance_valid(player):
			var dir = (player.global_position - minion.global_position).normalized()
			minion.velocity = dir * move_speed
			minion.move_and_slide()

			# Check for player collision
			var dist = minion.global_position.distance_to(player.global_position)
			if dist < 25:
				_explode_minion(minion)
				return

		await get_tree().process_frame

	# Explode at end of lifetime
	if is_instance_valid(minion):
		_explode_minion(minion)

func _explode_minion(minion: Node) -> void:
	if not is_instance_valid(minion):
		return

	var pos = minion.global_position
	var damage = minion.get_meta("explosion_damage", army_explosion_damage)
	var radius = minion.get_meta("explosion_radius", army_explosion_radius)

	# Check for player damage
	if player and is_instance_valid(player):
		var dist = player.global_position.distance_to(pos)
		if dist < radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				_on_elite_attack_hit(damage)

	# Visual explosion
	var explosion = Node2D.new()
	explosion.global_position = pos
	explosion.z_index = 5

	var visual = ColorRect.new()
	visual.size = Vector2(20, 20)
	visual.position = Vector2(-10, -10)
	visual.color = Color(0.6, 0.3, 0.7, 1.0)
	explosion.add_child(visual)

	get_parent().add_child(explosion)

	var tween = create_tween()
	tween.tween_property(visual, "size", Vector2(radius * 2, radius * 2), 0.1)
	tween.parallel().tween_property(visual, "position", Vector2(-radius, -radius), 0.1)
	tween.parallel().tween_property(visual, "color:a", 0.0, 0.2)
	tween.tween_callback(explosion.queue_free)

	# Remove minion
	var idx = army_minions.find(minion)
	if idx >= 0:
		army_minions.remove_at(idx)
	minion.queue_free()

func _show_army_warning() -> void:
	if army_warning_label == null:
		army_warning_label = Label.new()
		army_warning_label.text = "ARMY OF THE DAMNED!"
		army_warning_label.add_theme_font_size_override("font_size", 14)
		army_warning_label.add_theme_color_override("font_color", Color(0.6, 0.3, 0.8, 1.0))
		army_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		army_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		army_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		army_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		army_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			army_warning_label.add_theme_font_override("font", pixel_font)

		add_child(army_warning_label)

	army_warning_label.position = Vector2(-85, -80)
	army_warning_label.visible = true

	if army_warning_tween and army_warning_tween.is_valid():
		army_warning_tween.kill()

	army_warning_tween = create_tween().set_loops()
	army_warning_tween.tween_property(army_warning_label, "modulate:a", 0.5, 0.15)
	army_warning_tween.tween_property(army_warning_label, "modulate:a", 1.0, 0.15)

func _hide_army_warning() -> void:
	if army_warning_tween and army_warning_tween.is_valid():
		army_warning_tween.kill()
		army_warning_tween = null
	if army_warning_label:
		army_warning_label.visible = false

# ============================================
# PHYSICS AND SPECIAL PROCESSING
# ============================================

func _physics_process(delta: float) -> void:
	# Handle shadow bolt windup
	if shadow_bolt_active:
		shadow_bolt_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_CAST, 8)
		sprite.frame = ROW_CAST * COLS_PER_ROW + int(animation_frame) % max_frames

		if shadow_bolt_windup_timer <= 0:
			_execute_shadow_bolt()
			shadow_bolt_active = false
			can_attack = false
		return

	# Handle raise dead windup
	if raise_dead_active:
		raise_dead_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_SUMMON, 8)
		sprite.frame = ROW_SUMMON * COLS_PER_ROW + int(animation_frame) % max_frames

		if raise_dead_windup_timer <= 0:
			_execute_raise_dead()
			raise_dead_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if army_telegraphing:
		army_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.6 * delta
		var max_frames = FRAME_COUNTS.get(ROW_SUMMON, 8)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_SUMMON * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Dark pulsing effect
		var pulse = sin(Time.get_ticks_msec() * 0.01) * 0.15
		if sprite:
			sprite.modulate = Color(0.7 + pulse, 0.6 + pulse, 0.9 + pulse, 1.0)

		if army_telegraph_timer <= 0:
			sprite.modulate = Color(0.85, 0.75, 0.95, 1.0)
			_execute_army_of_the_damned()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	army_telegraphing = false
	army_active = false
	hide_warning()
	_hide_army_warning()
	if sprite:
		sprite.modulate = Color(0.85, 0.75, 0.95, 1.0)

func die() -> void:
	_hide_army_warning()

	# Damage all summons when necromancer dies
	for summon in active_summons:
		if is_instance_valid(summon) and summon.has_method("take_damage"):
			summon.take_damage(summon.max_health * 0.5)

	# Explode remaining army minions
	for minion in army_minions:
		if is_instance_valid(minion):
			_explode_minion(minion)

	super.die()
