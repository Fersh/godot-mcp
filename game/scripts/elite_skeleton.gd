extends EliteBase

# Elite Skeleton - "Bone Daddy" - Undead warrior supreme
# Three attack types:
# 1. Bone Cleave - Heavy two-handed sword swing
# 2. Bone Throw - Throws bones as projectiles
# 3. Bone Zone - Bones erupt from the ground in AOE around target
#
# Skeleton Sprite Sheet: 10 cols x 10 rows (using first 5 rows)
# Row 0: Idle (10 frames)
# Row 1: Walk (5 frames)
# Row 2: Attack (10 frames)
# Row 3: Damaged (5 frames)
# Row 4: Death (10 frames)

@export var bone_projectile_scene: PackedScene

# Attack-specific stats
@export var bone_cleave_damage: float = 28.0
@export var bone_cleave_range: float = 100.0
@export var bone_cleave_aoe_radius: float = 120.0

@export var bone_throw_damage: float = 20.0
@export var bone_throw_range: float = 300.0
@export var bone_throw_speed: float = 180.0
@export var bone_throw_count: int = 3

@export var bone_zone_damage: float = 18.0
@export var bone_zone_range: float = 280.0
@export var bone_zone_radius: float = 150.0
@export var bone_zone_telegraph_time: float = 1.0

# Attack state
var bone_cleave_active: bool = false
var bone_cleave_windup_timer: float = 0.0
const BONE_CLEAVE_WINDUP: float = 0.7

var bone_throw_active: bool = false
var bone_throw_windup_timer: float = 0.0
const BONE_THROW_WINDUP: float = 0.5
var bones_thrown: int = 0

var bone_zone_telegraphing: bool = false
var bone_zone_telegraph_timer: float = 0.0
var bone_zone_target_pos: Vector2 = Vector2.ZERO
var bone_zone_warning_label: Label = null
var bone_zone_warning_tween: Tween = null
var bone_zone_indicator: Node2D = null
var bone_zone_indicator_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "Bone Daddy"
	enemy_type = "skeleton_elite"

	# Stats - tanky undead warrior
	speed = 65.0
	max_health = 850.0  # Tankier
	attack_damage = bone_cleave_damage
	attack_cooldown = 1.0
	windup_duration = 0.6
	animation_speed = 10.0

	# Skeleton spritesheet: 10 cols x 10 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 2
	ROW_DAMAGE = 3
	ROW_DEATH = 4
	COLS_PER_ROW = 10

	FRAME_COUNTS = {
		0: 10,  # IDLE
		1: 5,   # MOVE/WALK
		2: 10,  # ATTACK
		3: 5,   # DAMAGE
		4: 10,  # DEATH
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Scale up the sprite for elite size
	if sprite:
		sprite.scale = Vector2(3.5, 3.5)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "bone_cleave",
			"range": bone_cleave_range,
			"cooldown": 3.5,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "bone_throw",
			"range": bone_throw_range,
			"cooldown": 5.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "bone_zone",
			"range": bone_zone_range,
			"cooldown": 10.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"bone_cleave":
			_start_bone_cleave()
		"bone_throw":
			_start_bone_throw()
		"bone_zone":
			_start_bone_zone()

func _start_bone_cleave() -> void:
	bone_cleave_active = true
	bone_cleave_windup_timer = BONE_CLEAVE_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_bone_throw() -> void:
	bone_throw_active = true
	bone_throw_windup_timer = BONE_THROW_WINDUP
	bones_thrown = 0
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _start_bone_zone() -> void:
	show_warning()
	is_using_special = true

	bone_zone_telegraphing = true
	bone_zone_telegraph_timer = bone_zone_telegraph_time
	special_timer = bone_zone_telegraph_time + 0.5

	if player and is_instance_valid(player):
		bone_zone_target_pos = player.global_position

	_show_bone_zone_warning()
	_show_bone_zone_indicator()

	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

func _execute_bone_zone() -> void:
	bone_zone_telegraphing = false
	_hide_bone_zone_warning()
	_clear_bone_zone_indicator()

	# Deal AOE damage at target location
	if player and is_instance_valid(player):
		var dist = player.global_position.distance_to(bone_zone_target_pos)
		if dist <= bone_zone_radius:
			if player.has_method("take_damage"):
				player.take_damage(bone_zone_damage)
				_on_elite_attack_hit(bone_zone_damage)

	# Visual effect - bone eruption
	_spawn_bone_eruption_effect()

	if JuiceManager:
		JuiceManager.shake_large()

func _spawn_bone_eruption_effect() -> void:
	# Create visual bone spike effect at target position
	var effect = Node2D.new()
	effect.global_position = bone_zone_target_pos
	effect.z_index = 5

	# Create multiple bone spike indicators
	for i in range(8):
		var spike = ColorRect.new()
		var angle = (TAU / 8) * i
		var distance = randf_range(20, bone_zone_radius * 0.7)
		spike.size = Vector2(10, 30)
		spike.position = Vector2(cos(angle) * distance - 5, sin(angle) * distance - 15)
		spike.rotation = angle + PI/2
		spike.color = Color(0.9, 0.9, 0.8, 0.9)
		effect.add_child(spike)

	get_parent().add_child(effect)

	# Fade out and remove
	var tween = create_tween()
	tween.tween_property(effect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(effect.queue_free)

func _show_bone_zone_warning() -> void:
	if bone_zone_warning_label == null:
		bone_zone_warning_label = Label.new()
		bone_zone_warning_label.text = "BONE ZONE!"
		bone_zone_warning_label.add_theme_font_size_override("font_size", 14)
		bone_zone_warning_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.8, 1.0))
		bone_zone_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		bone_zone_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		bone_zone_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		bone_zone_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bone_zone_warning_label.z_index = 100

		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			bone_zone_warning_label.add_theme_font_override("font", pixel_font)

		add_child(bone_zone_warning_label)

	bone_zone_warning_label.position = Vector2(-50, -100)
	bone_zone_warning_label.visible = true

	if bone_zone_warning_tween and bone_zone_warning_tween.is_valid():
		bone_zone_warning_tween.kill()

	bone_zone_warning_tween = create_tween().set_loops()
	bone_zone_warning_tween.tween_property(bone_zone_warning_label, "modulate:a", 0.5, 0.15)
	bone_zone_warning_tween.tween_property(bone_zone_warning_label, "modulate:a", 1.0, 0.15)

func _hide_bone_zone_warning() -> void:
	if bone_zone_warning_tween and bone_zone_warning_tween.is_valid():
		bone_zone_warning_tween.kill()
		bone_zone_warning_tween = null
	if bone_zone_warning_label:
		bone_zone_warning_label.visible = false

func _show_bone_zone_indicator() -> void:
	_clear_bone_zone_indicator()

	bone_zone_indicator = Node2D.new()
	bone_zone_indicator.global_position = bone_zone_target_pos
	bone_zone_indicator.z_index = -1

	var circle = ColorRect.new()
	var size = bone_zone_radius * 2
	circle.size = Vector2(size, size)
	circle.position = Vector2(-bone_zone_radius, -bone_zone_radius)
	circle.color = Color(0.9, 0.9, 0.8, 0.3)
	bone_zone_indicator.add_child(circle)

	get_parent().add_child(bone_zone_indicator)

	if bone_zone_indicator_tween and bone_zone_indicator_tween.is_valid():
		bone_zone_indicator_tween.kill()

	bone_zone_indicator_tween = create_tween().set_loops()
	bone_zone_indicator_tween.tween_property(circle, "color:a", 0.15, 0.2)
	bone_zone_indicator_tween.tween_property(circle, "color:a", 0.4, 0.2)

func _clear_bone_zone_indicator() -> void:
	if bone_zone_indicator_tween and bone_zone_indicator_tween.is_valid():
		bone_zone_indicator_tween.kill()
		bone_zone_indicator_tween = null

	if bone_zone_indicator and is_instance_valid(bone_zone_indicator):
		bone_zone_indicator.queue_free()
	bone_zone_indicator = null

func _physics_process(delta: float) -> void:
	# Handle bone cleave windup
	if bone_cleave_active:
		bone_cleave_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 10)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if bone_cleave_windup_timer <= 0:
			_execute_bone_cleave()
			bone_cleave_active = false
			can_attack = false
		return

	# Handle bone throw
	if bone_throw_active:
		bone_throw_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 10)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + int(animation_frame) % max_frames

		if bone_throw_windup_timer <= 0 and bones_thrown < bone_throw_count:
			_execute_bone_throw()
			bones_thrown += 1
			bone_throw_windup_timer = 0.2  # Short delay between throws

		if bones_thrown >= bone_throw_count:
			bone_throw_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	if bone_zone_telegraphing:
		bone_zone_telegraph_timer -= delta

		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		animation_frame += animation_speed * 0.5 * delta
		var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 10)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		if bone_zone_telegraph_timer <= 0:
			_execute_bone_zone()
		return

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_bone_zone()

func _end_bone_zone() -> void:
	bone_zone_telegraphing = false
	hide_warning()
	_hide_bone_zone_warning()
	_clear_bone_zone_indicator()

func _execute_bone_cleave() -> void:
	# Heavy AOE damage around skeleton
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= bone_cleave_aoe_radius:
			if player.has_method("take_damage"):
				player.take_damage(bone_cleave_damage)
				_on_elite_attack_hit(bone_cleave_damage)

	if JuiceManager:
		JuiceManager.shake_large()

func _execute_bone_throw() -> void:
	if not player or not is_instance_valid(player):
		return

	# Calculate direction with slight spread
	var base_direction = (player.global_position - global_position).normalized()
	var spread_angle = randf_range(-0.2, 0.2)
	var direction = base_direction.rotated(spread_angle)

	# Try to use bone projectile scene or fall back to rock projectile
	var proj_scene = bone_projectile_scene
	if proj_scene == null:
		proj_scene = load("res://scenes/rock_projectile.tscn")

	if proj_scene:
		var proj = proj_scene.instantiate()
		proj.global_position = global_position + direction * 40
		if proj.has_method("set"):
			if "direction" in proj:
				proj.direction = direction
			if "speed" in proj:
				proj.speed = bone_throw_speed
			if "damage" in proj:
				proj.damage = bone_throw_damage
			if "target_position" in proj:
				proj.target_position = player.global_position

		# Bone-colored tint
		if proj.has_node("Sprite2D"):
			proj.get_node("Sprite2D").modulate = Color(0.95, 0.95, 0.85)

		get_parent().add_child(proj)

func die() -> void:
	_end_bone_zone()
	super.die()
