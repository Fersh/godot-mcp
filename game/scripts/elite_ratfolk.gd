extends EliteBase

# Elite Ratfolk - "Rat Daddy" - King of the vermin horde
# Three attack types:
# 1. Frenzy Bite - Rapid multi-hit melee attack
# 2. Plague Spit - Ranged poison projectile
# 3. Swarm Call - Summons temporary mini ratfolk minions
#
# Ratfolk Sprite Sheet: 12 cols x 5 rows (64x32 per frame)
# Row 0: Idle (4 frames)
# Row 1: Move (8 frames)
# Row 2: Attack (12 frames)
# Row 3: Damage (4 frames)
# Row 4: Death (5 frames)

@export var ratfolk_minion_scene: PackedScene

# Attack-specific stats
@export var frenzy_bite_damage: float = 8.0
@export var frenzy_bite_hits: int = 4
@export var frenzy_bite_range: float = 70.0

@export var plague_spit_damage: float = 12.0
@export var plague_spit_range: float = 280.0
@export var plague_spit_speed: float = 200.0
@export var poison_duration: float = 4.0
@export var poison_damage_per_tick: float = 3.0

@export var swarm_count: int = 4
@export var swarm_telegraph_time: float = 1.2
@export var swarm_range: float = 250.0

# Attack state
var frenzy_active: bool = false
var frenzy_windup_timer: float = 0.0
var frenzy_hit_count: int = 0
var frenzy_hit_timer: float = 0.0
const FRENZY_WINDUP: float = 0.3
const FRENZY_HIT_INTERVAL: float = 0.15

var plague_spit_active: bool = false
var plague_spit_windup_timer: float = 0.0
const PLAGUE_SPIT_WINDUP: float = 0.4

var swarm_telegraphing: bool = false
var swarm_telegraph_timer: float = 0.0
var swarm_warning_label: Label = null
var swarm_warning_tween: Tween = null

# Projectile scene for plague spit
@export var projectile_scene: PackedScene

func _setup_elite() -> void:
	elite_name = "Rat Daddy"
	enemy_type = "ratfolk_elite"

	# Stats - fastest elite but fragile
	speed = 95.0  # Fastest elite
	max_health = 550.0  # Lower HP (fragile theme)
	attack_damage = frenzy_bite_damage
	attack_cooldown = 0.8
	windup_duration = 0.3
	animation_speed = 14.0  # Fast animations

	# Ratfolk spritesheet: 12 cols x 5 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 12

	FRAME_COUNTS = {
		0: 4,   # IDLE
		1: 8,   # MOVE
		2: 12,  # ATTACK
		3: 4,   # DAMAGE
		4: 5,   # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up the sprite for elite size
	if sprite:
		sprite.scale = Vector2(4.0, 4.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "frenzy_bite",
			"range": frenzy_bite_range,
			"cooldown": 3.5,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "plague_spit",
			"range": plague_spit_range,
			"cooldown": 4.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "swarm_call",
			"range": swarm_range,
			"cooldown": 15.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"frenzy_bite":
			_start_frenzy_bite()
		"plague_spit":
			_start_plague_spit()
		"swarm_call":
			_start_swarm_call()

func _start_frenzy_bite() -> void:
	frenzy_active = true
	frenzy_windup_timer = FRENZY_WINDUP
	frenzy_hit_count = 0
	frenzy_hit_timer = 0.0
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_plague_spit() -> void:
	plague_spit_active = true
	plague_spit_windup_timer = PLAGUE_SPIT_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_swarm_call() -> void:
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

func _execute_swarm_call() -> void:
	swarm_telegraphing = false
	_hide_swarm_warning()

	# Spawn mini ratfolk around the elite
	for i in range(swarm_count):
		var angle = (TAU / swarm_count) * i
		var offset = Vector2(cos(angle), sin(angle)) * 80
		_spawn_minion(global_position + offset)

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_minion(spawn_pos: Vector2) -> void:
	# Try to use ratfolk minion scene, fallback to creating simple minion
	if ratfolk_minion_scene:
		var minion = ratfolk_minion_scene.instantiate()
		minion.global_position = spawn_pos
		get_parent().add_child(minion)
	else:
		# Create a weaker version using the regular ratfolk scene
		var ratfolk_scene = load("res://scenes/enemy_ratfolk.tscn")
		if ratfolk_scene:
			var minion = ratfolk_scene.instantiate()
			minion.global_position = spawn_pos
			get_parent().add_child(minion)

			# Make it a weaker "swarm" version
			if minion.has_method("_on_ready"):
				minion._on_ready()
			minion.max_health = 6.0
			minion.current_health = 6.0
			minion.attack_damage = 2.0
			minion.speed = 100.0

			# Make them visually distinct - slightly transparent
			if minion.has_node("Sprite"):
				var minion_sprite = minion.get_node("Sprite")
				minion_sprite.modulate = Color(0.8, 1.0, 0.8, 0.85)
				minion_sprite.scale = Vector2(1.2, 1.2)

func _show_swarm_warning() -> void:
	if swarm_warning_label == null:
		swarm_warning_label = Label.new()
		swarm_warning_label.text = "SWARM!"
		swarm_warning_label.add_theme_font_size_override("font_size", 16)
		swarm_warning_label.add_theme_color_override("font_color", Color(0.6, 0.9, 0.3, 1.0))
		swarm_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		swarm_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		swarm_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		swarm_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		swarm_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			swarm_warning_label.add_theme_font_override("font", pixel_font)

		add_child(swarm_warning_label)

	swarm_warning_label.position = Vector2(-35, -90)
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

func _physics_process(delta: float) -> void:
	# Handle frenzy bite
	if frenzy_active:
		frenzy_windup_timer -= delta

		if frenzy_windup_timer <= 0:
			frenzy_hit_timer -= delta
			if frenzy_hit_timer <= 0 and frenzy_hit_count < frenzy_bite_hits:
				_execute_frenzy_hit()
				frenzy_hit_count += 1
				frenzy_hit_timer = FRENZY_HIT_INTERVAL

			if frenzy_hit_count >= frenzy_bite_hits:
				frenzy_active = false
				can_attack = false

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 12)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames
		if dir.x != 0:
			sprite.flip_h = dir.x < 0
		return

	# Handle plague spit windup
	if plague_spit_active:
		plague_spit_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 12)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if plague_spit_windup_timer <= 0:
			_execute_plague_spit()
			plague_spit_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if swarm_telegraphing:
		swarm_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 12)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		if swarm_telegraph_timer <= 0:
			_execute_swarm_call()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_swarm_call()

func _end_swarm_call() -> void:
	swarm_telegraphing = false
	hide_warning()
	_hide_swarm_warning()

func _execute_frenzy_hit() -> void:
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= frenzy_bite_range + 20:  # Slight extra range during frenzy
			if player.has_method("take_damage"):
				player.take_damage(frenzy_bite_damage)
				_on_elite_attack_hit(frenzy_bite_damage)

func _execute_plague_spit() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Use existing enemy projectile if available
	if projectile_scene:
		var proj = projectile_scene.instantiate()
		proj.global_position = global_position + direction * 30
		proj.direction = direction
		proj.speed = plague_spit_speed
		proj.damage = plague_spit_damage
		get_parent().add_child(proj)
	else:
		# Try to load the enemy projectile scene
		var proj_scene = load("res://scenes/enemy_projectile.tscn")
		if proj_scene:
			var proj = proj_scene.instantiate()
			proj.global_position = global_position + direction * 30
			proj.direction = direction
			proj.speed = plague_spit_speed
			proj.damage = plague_spit_damage
			# Add poison effect - greenish tint
			if proj.has_node("Sprite2D"):
				proj.get_node("Sprite2D").modulate = Color(0.5, 1.0, 0.3)
			get_parent().add_child(proj)

	# Apply poison to player on hit (handled via projectile or direct)
	# For now, just track that this was a poison attack

func die() -> void:
	_end_swarm_call()
	super.die()
