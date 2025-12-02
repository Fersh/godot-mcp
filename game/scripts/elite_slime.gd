extends EliteBase

# Elite Slime - "Blobulous the Magnificent" - The goopiest boi
# Three attack types:
# 1. Body Slam - Heavy melee AOE with knockback
# 2. Acid Spit - Ranged acid projectile that leaves damaging puddle
# 3. Mitosis - Splits into smaller slimes that attack independently
#
# Slime Sprite Sheet: 8 cols x 4 rows
# Row 0: Idle (4 frames)
# Row 1: Move (same as idle)
# Row 2: Attack (4 frames)
# Row 3: Death (4 frames)

@export var acid_projectile_scene: PackedScene
@export var mini_slime_scene: PackedScene

# Attack-specific stats
@export var body_slam_damage: float = 25.0
@export var body_slam_range: float = 100.0
@export var body_slam_aoe_radius: float = 130.0
@export var body_slam_knockback: float = 250.0

@export var acid_spit_damage: float = 15.0
@export var acid_spit_range: float = 260.0
@export var acid_spit_speed: float = 120.0
@export var acid_puddle_damage: float = 5.0
@export var acid_puddle_duration: float = 3.0

@export var mitosis_count: int = 3
@export var mitosis_telegraph_time: float = 1.5
@export var mitosis_range: float = 200.0

# Attack state
var body_slam_active: bool = false
var body_slam_windup_timer: float = 0.0
const BODY_SLAM_WINDUP: float = 0.8

var acid_spit_active: bool = false
var acid_spit_windup_timer: float = 0.0
const ACID_SPIT_WINDUP: float = 0.6

var mitosis_telegraphing: bool = false
var mitosis_telegraph_timer: float = 0.0
var mitosis_warning_label: Label = null
var mitosis_warning_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "Blobulous the Magnificent"
	enemy_type = "slime_elite"

	# Stats - slowest but tankiest
	speed = 35.0  # Very slow
	max_health = 900.0  # Tankiest elite
	attack_damage = body_slam_damage
	attack_cooldown = 1.2
	windup_duration = 0.7
	animation_speed = 6.0  # Slow bouncy animations

	# Slime spritesheet: 8 cols x 4 rows
	ROW_IDLE = 0
	ROW_MOVE = 0  # Same as idle for slime
	ROW_ATTACK = 2
	ROW_DAMAGE = 2
	ROW_DEATH = 3
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,  # IDLE
		1: 4,  # MOVE (same)
		2: 4,  # ATTACK
		3: 4,  # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up the sprite for elite size - BIG slime
	if sprite:
		sprite.scale = Vector2(5.0, 5.0)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "body_slam",
			"range": body_slam_range,
			"cooldown": 4.0,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "acid_spit",
			"range": acid_spit_range,
			"cooldown": 5.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "mitosis",
			"range": mitosis_range,
			"cooldown": 18.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"body_slam":
			_start_body_slam()
		"acid_spit":
			_start_acid_spit()
		"mitosis":
			_start_mitosis()

func _start_body_slam() -> void:
	body_slam_active = true
	body_slam_windup_timer = BODY_SLAM_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_acid_spit() -> void:
	acid_spit_active = true
	acid_spit_windup_timer = ACID_SPIT_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_mitosis() -> void:
	show_warning()
	is_using_special = true

	mitosis_telegraphing = true
	mitosis_telegraph_timer = mitosis_telegraph_time
	special_timer = mitosis_telegraph_time + 0.5

	_show_mitosis_warning()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_mitosis() -> void:
	mitosis_telegraphing = false
	_hide_mitosis_warning()

	# Spawn mini slimes around the elite
	for i in range(mitosis_count):
		var angle = (TAU / mitosis_count) * i + randf_range(-0.3, 0.3)
		var offset = Vector2(cos(angle), sin(angle)) * 100
		_spawn_mini_slime(global_position + offset)

	# Visual "split" effect - briefly shrink then return
	if sprite:
		var original_scale = sprite.scale
		var shrink_scale = original_scale * 0.7
		var tween = create_tween()
		tween.tween_property(sprite, "scale", shrink_scale, 0.1)
		tween.tween_property(sprite, "scale", original_scale, 0.3)

	if JuiceManager:
		JuiceManager.shake_medium()

func _spawn_mini_slime(spawn_pos: Vector2) -> void:
	# Try to use mini slime scene, fallback to regular slime
	var slime_scene = mini_slime_scene
	if slime_scene == null:
		slime_scene = load("res://scenes/enemy_slime.tscn")

	if slime_scene:
		var minion = slime_scene.instantiate()
		minion.global_position = spawn_pos
		get_parent().add_child(minion)

		# Make it a weaker "mini" version
		if minion.has_method("_on_ready"):
			minion._on_ready()
		minion.max_health = 25.0
		minion.current_health = 25.0
		minion.attack_damage = 6.0
		minion.speed = 50.0

		# Make them visually distinct - smaller and slightly transparent
		if minion.has_node("Sprite"):
			var minion_sprite = minion.get_node("Sprite")
			minion_sprite.modulate = Color(0.7, 1.0, 0.7, 0.9)
			minion_sprite.scale = Vector2(1.5, 1.5)

func _show_mitosis_warning() -> void:
	if mitosis_warning_label == null:
		mitosis_warning_label = Label.new()
		mitosis_warning_label.text = "MITOSIS!"
		mitosis_warning_label.add_theme_font_size_override("font_size", 14)
		mitosis_warning_label.add_theme_color_override("font_color", Color(0.4, 1.0, 0.4, 1.0))
		mitosis_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		mitosis_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		mitosis_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		mitosis_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		mitosis_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			mitosis_warning_label.add_theme_font_override("font", pixel_font)

		add_child(mitosis_warning_label)

	mitosis_warning_label.position = Vector2(-45, -120)
	mitosis_warning_label.visible = true

	if mitosis_warning_tween and mitosis_warning_tween.is_valid():
		mitosis_warning_tween.kill()

	mitosis_warning_tween = create_tween().set_loops()
	mitosis_warning_tween.tween_property(mitosis_warning_label, "modulate:a", 0.5, 0.2)
	mitosis_warning_tween.tween_property(mitosis_warning_label, "modulate:a", 1.0, 0.2)

func _hide_mitosis_warning() -> void:
	if mitosis_warning_tween and mitosis_warning_tween.is_valid():
		mitosis_warning_tween.kill()
		mitosis_warning_tween = null
	if mitosis_warning_label:
		mitosis_warning_label.visible = false

func _physics_process(delta: float) -> void:
	# Handle body slam windup
	if body_slam_active:
		body_slam_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 4)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if body_slam_windup_timer <= 0:
			_execute_body_slam()
			body_slam_active = false
			can_attack = false
		return

	# Handle acid spit windup
	if acid_spit_active:
		acid_spit_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 4)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if acid_spit_windup_timer <= 0:
			_execute_acid_spit()
			acid_spit_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if mitosis_telegraphing:
		mitosis_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 4)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame

		# Pulsing scale effect during telegraph
		var pulse = 1.0 + sin(Time.get_ticks_msec() * 0.01) * 0.1
		if sprite:
			sprite.scale = Vector2(5.0, 5.0) * pulse

		if mitosis_telegraph_timer <= 0:
			if sprite:
				sprite.scale = Vector2(5.0, 5.0)
			_execute_mitosis()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_mitosis()

func _end_mitosis() -> void:
	mitosis_telegraphing = false
	hide_warning()
	_hide_mitosis_warning()
	if sprite:
		sprite.scale = Vector2(5.0, 5.0)

func _execute_body_slam() -> void:
	# Heavy AOE damage with knockback
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= body_slam_aoe_radius:
			if player.has_method("take_damage"):
				player.take_damage(body_slam_damage)
				_on_elite_attack_hit(body_slam_damage)

			# Knockback player
			if player.has_method("apply_knockback"):
				var knockback_dir = (player.global_position - global_position).normalized()
				player.apply_knockback(knockback_dir * body_slam_knockback)

	if JuiceManager:
		JuiceManager.shake_large()

func _execute_acid_spit() -> void:
	if not player or not is_instance_valid(player):
		return

	var direction = (player.global_position - global_position).normalized()

	# Use existing projectile scene or create acid ball
	var proj_scene = acid_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/enemy_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 50
		if "direction" in proj:
			proj.direction = direction
		if "speed" in proj:
			proj.speed = acid_spit_speed
		if "damage" in proj:
			proj.damage = acid_spit_damage

		# Green acid tint
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(0.3, 1.0, 0.3)

		get_parent().add_child(proj)

		# Spawn acid puddle at target location after delay
		var target_pos = player.global_position
		var puddle_timer = get_tree().create_timer(0.5)
		puddle_timer.timeout.connect(func():
			_spawn_acid_puddle(target_pos)
		)

func _spawn_acid_puddle(pos: Vector2) -> void:
	# Create damaging acid puddle
	var puddle = Node2D.new()
	puddle.global_position = pos
	puddle.z_index = -1

	var visual = ColorRect.new()
	visual.size = Vector2(80, 80)
	visual.position = Vector2(-40, -40)
	visual.color = Color(0.3, 0.8, 0.2, 0.6)
	puddle.add_child(visual)

	get_parent().add_child(puddle)

	# Damage over time area
	var damage_timer = 0.0
	var lifetime = acid_puddle_duration

	# Create a timer for puddle damage
	var damage_check = func(delta: float):
		damage_timer += delta
		if player and is_instance_valid(player):
			var dist = player.global_position.distance_to(pos)
			if dist < 50:  # In puddle
				if player.has_method("take_damage"):
					player.take_damage(acid_puddle_damage * delta * 2)

	# Connect to tree process
	puddle.set_process(true)
	puddle.set_script(GDScript.new())

	# Fade out and remove after duration
	var fade_tween = create_tween()
	fade_tween.tween_interval(acid_puddle_duration - 0.5)
	fade_tween.tween_property(visual, "color:a", 0.0, 0.5)
	fade_tween.tween_callback(puddle.queue_free)

func die() -> void:
	_end_mitosis()
	super.die()
