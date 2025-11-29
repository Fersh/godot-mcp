extends EliteBase

# Cyclops Elite - Large one-eyed brute with three attack types:
# 1. Stomp - Close range AOE ground slam
# 2. Rock Throw - Ranged projectile attack
# 3. Laser Beam - Targeted line attack from eye

@export var rock_projectile_scene: PackedScene
@export var laser_beam_scene: PackedScene

# Attack-specific stats
@export var stomp_damage: float = 18.0  # Reduced from 30
@export var stomp_range: float = 80.0
@export var stomp_aoe_radius: float = 100.0

@export var rock_damage: float = 22.5  # Reduced 25% from 30
@export var rock_range: float = 300.0
@export var rock_speed: float = 150.0  # Slower, easier to dodge

@export var laser_damage: float = 10.0  # Per tick - reduced further
@export var laser_range: float = 300.0  # Reduced 25% from 400
@export var laser_duration: float = 2.0
@export var laser_tick_rate: float = 0.25
@export var laser_telegraph_time: float = 1.0  # Telegraph duration before beam fires

# Animation rows for Cyclops spritesheet (15 cols x 20 rows, 64x64 per frame)
var ROW_GUARD: int = 7
var ROW_LASER: int = 9  # Beam is at row 9
var ROW_STOMP: int = 3
var ROW_THROW: int = 4

# Laser beam state
var laser_active: bool = false
var laser_timer: float = 0.0
var laser_tick_timer: float = 0.0
var laser_target_pos: Vector2 = Vector2.ZERO
var laser_line: Line2D = null
var current_laser_direction: Vector2 = Vector2.ZERO
var laser_telegraphing: bool = false
var laser_telegraph_timer: float = 0.0
var beam_warning_label: Label = null
var beam_warning_tween: Tween = null

# Stomp state
var stomp_active: bool = false
var stomp_windup_timer: float = 0.0
const STOMP_WINDUP: float = 0.6

# Throw state
var throw_active: bool = false
var throw_windup_timer: float = 0.0
const THROW_WINDUP: float = 0.6  # Increased to give more warning time
var rock_target_pos: Vector2 = Vector2.ZERO
var rock_landing_indicator: Node2D = null
var rock_indicator_tween: Tween = null

func _setup_elite() -> void:
	elite_name = "One Eyed Monster"
	enemy_type = "cyclops"

	# Cyclops stats - elite, slower, hits hard
	speed = 48.5  # Slower than most enemies (reduced 20%)
	max_health = 675.0  # Reduced 10% from 750
	attack_damage = stomp_damage
	attack_cooldown = 1.0
	windup_duration = 0.5
	animation_speed = 8.0

	# Cyclops spritesheet: 15 cols x 20 rows
	ROW_IDLE = 0
	ROW_MOVE = 1
	ROW_ATTACK = 3  # Stomp
	ROW_DAMAGE = 5
	ROW_DEATH = 6
	ROW_GUARD = 7
	ROW_LASER = 9  # Beam is at row 9
	ROW_STOMP = 3
	ROW_THROW = 4
	COLS_PER_ROW = 15

	FRAME_COUNTS = {
		0: 15,  # IDLE
		1: 12,  # MOVE
		2: 7,
		3: 13,  # STOMP
		4: 3,   # THROW
		5: 5,   # DAMAGE
		6: 9,   # DEATH
		7: 4,   # GUARD
		8: 6,
		9: 4,   # LASER/BEAM (reduced further - frames 5-8 were empty)
	}

	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

	# Define available attacks with priorities
	available_attacks = [
		{
			"type": AttackType.MELEE,
			"name": "stomp",
			"range": stomp_range,
			"cooldown": 3.0,
			"priority": 5
		},
		{
			"type": AttackType.RANGED,
			"name": "rock_throw",
			"range": rock_range,
			"cooldown": 4.0,
			"priority": 4
		},
		{
			"type": AttackType.SPECIAL,
			"name": "laser_beam",
			"range": laser_range,
			"cooldown": 8.0,
			"priority": 6
		}
	]

func _execute_attack(attack: Dictionary) -> void:
	match attack.name:
		"stomp":
			_start_stomp()
		"rock_throw":
			_start_rock_throw()
		"laser_beam":
			_start_laser_beam()

func _start_stomp() -> void:
	stomp_active = true
	stomp_windup_timer = STOMP_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
	update_animation(0, ROW_STOMP, dir)
	animation_frame = 0

func _start_rock_throw() -> void:
	throw_active = true
	throw_windup_timer = THROW_WINDUP
	var dir = Vector2.ZERO
	if player and is_instance_valid(player):
		dir = (player.global_position - global_position).normalized()
		rock_target_pos = player.global_position
		_show_rock_landing_indicator()
	update_animation(0, ROW_THROW, dir)
	animation_frame = 0

func _show_rock_landing_indicator() -> void:
	_clear_rock_landing_indicator()

	rock_landing_indicator = Node2D.new()
	rock_landing_indicator.global_position = rock_target_pos
	rock_landing_indicator.z_index = 5

	# Create warning circle
	var circle = ColorRect.new()
	circle.size = Vector2(60, 60)
	circle.position = Vector2(-30, -30)
	circle.color = Color(0.6, 0.4, 0.2, 0.5)  # Brown/rock color, semi-transparent
	rock_landing_indicator.add_child(circle)

	get_parent().add_child(rock_landing_indicator)

	# Kill existing tween if any
	if rock_indicator_tween and rock_indicator_tween.is_valid():
		rock_indicator_tween.kill()

	# Pulsing animation for indicator - store tween to kill later
	rock_indicator_tween = create_tween().set_loops()
	rock_indicator_tween.tween_property(circle, "color:a", 0.2, 0.15)
	rock_indicator_tween.tween_property(circle, "color:a", 0.6, 0.15)

func _clear_rock_landing_indicator() -> void:
	# Kill the pulsing tween to prevent infinite loop
	if rock_indicator_tween and rock_indicator_tween.is_valid():
		rock_indicator_tween.kill()
		rock_indicator_tween = null

	if rock_landing_indicator and is_instance_valid(rock_landing_indicator):
		rock_landing_indicator.queue_free()
	rock_landing_indicator = null

func _start_laser_beam() -> void:
	show_warning()
	is_using_special = true

	# Start telegraph phase - show "BEAM!" warning
	laser_telegraphing = true
	laser_telegraph_timer = laser_telegraph_time
	special_timer = laser_telegraph_time + laser_duration + 0.5  # Telegraph + beam + extra time

	if player and is_instance_valid(player):
		current_laser_direction = (player.global_position - global_position).normalized()
		laser_target_pos = player.global_position

	# Show BEAM! warning above head
	_show_beam_warning()

	# Use laser/beam animation during telegraph
	var dir = current_laser_direction
	update_animation(0, ROW_LASER, dir)
	animation_frame = 0

func _activate_laser() -> void:
	# Called after telegraph finishes
	laser_telegraphing = false
	laser_active = true
	laser_timer = laser_duration
	laser_tick_timer = 0.0

	# Hide warning label
	_hide_beam_warning()

	# Create laser visual
	_create_laser_line()

func _show_beam_warning() -> void:
	if beam_warning_label == null:
		beam_warning_label = Label.new()
		beam_warning_label.text = "BEAM!"
		beam_warning_label.add_theme_font_size_override("font_size", 16)
		beam_warning_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
		beam_warning_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		beam_warning_label.add_theme_constant_override("shadow_offset_x", 2)
		beam_warning_label.add_theme_constant_override("shadow_offset_y", 2)
		beam_warning_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		beam_warning_label.z_index = 100

		# Load pixel font if available
		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			beam_warning_label.add_theme_font_override("font", pixel_font)

		add_child(beam_warning_label)

	beam_warning_label.position = Vector2(-30, -80)  # Above the cyclops head
	beam_warning_label.visible = true

	# Kill existing tween if any
	if beam_warning_tween and beam_warning_tween.is_valid():
		beam_warning_tween.kill()

	# Pulsing animation - store tween to kill later
	beam_warning_tween = create_tween().set_loops()
	beam_warning_tween.tween_property(beam_warning_label, "modulate:a", 0.5, 0.15)
	beam_warning_tween.tween_property(beam_warning_label, "modulate:a", 1.0, 0.15)

func _hide_beam_warning() -> void:
	# Kill the pulsing tween to prevent infinite loop
	if beam_warning_tween and beam_warning_tween.is_valid():
		beam_warning_tween.kill()
		beam_warning_tween = null
	if beam_warning_label:
		beam_warning_label.visible = false

func _create_laser_line() -> void:
	if laser_line == null:
		laser_line = Line2D.new()
		laser_line.width = 8.0
		laser_line.default_color = Color(1.0, 0.2, 0.2, 0.8)
		laser_line.z_index = 10
		add_child(laser_line)

	laser_line.clear_points()
	laser_line.visible = true

func _physics_process(delta: float) -> void:
	# Handle stomp windup
	if stomp_active:
		stomp_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		# Animate stomp
		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_STOMP, 7)
		sprite.frame = ROW_STOMP * COLS_PER_ROW + int(animation_frame) % max_frames

		if stomp_windup_timer <= 0:
			_execute_stomp()
			stomp_active = false
			can_attack = false
		return

	# Handle throw windup
	if throw_active:
		throw_windup_timer -= delta
		var dir = Vector2.ZERO
		if player and is_instance_valid(player):
			dir = (player.global_position - global_position).normalized()

		# Animate throw
		animation_frame += animation_speed * delta
		var max_frames = FRAME_COUNTS.get(ROW_THROW, 9)
		sprite.frame = ROW_THROW * COLS_PER_ROW + int(animation_frame) % max_frames

		if throw_windup_timer <= 0:
			_execute_rock_throw()
			throw_active = false
			can_attack = false
		return

	super._physics_process(delta)

func _process_special_attack(delta: float) -> void:
	# Ensure sprite is always visible during beam attack
	if sprite:
		sprite.visible = true

	# Handle telegraph phase
	if laser_telegraphing:
		laser_telegraph_timer -= delta

		# Track player during telegraph
		if player and is_instance_valid(player):
			current_laser_direction = (player.global_position - global_position).normalized()

		# Use IDLE animation during telegraph (ROW_LASER may have empty frames)
		var dir = current_laser_direction
		animation_frame += animation_speed * 0.3 * delta
		var max_frames = FRAME_COUNTS.get(ROW_IDLE, 15)
		if animation_frame >= max_frames:
			animation_frame = 0.0
		var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
		sprite.frame = ROW_IDLE * COLS_PER_ROW + clamped_frame
		if dir.x != 0:
			sprite.flip_h = dir.x < 0

		# Telegraph finished - activate the laser
		if laser_telegraph_timer <= 0:
			_activate_laser()
		return

	if not laser_active:
		return

	laser_timer -= delta
	laser_tick_timer -= delta

	# Update laser visual to track toward player (slowly)
	if player and is_instance_valid(player):
		var target_dir = (player.global_position - global_position).normalized()
		current_laser_direction = current_laser_direction.lerp(target_dir, delta * 0.5)

	# Update laser line
	if laser_line:
		laser_line.clear_points()
		# Start beam from cyclops eye area (offset upward from center)
		var eye_offset = Vector2(0, -30)
		laser_line.add_point(eye_offset)
		var end_point = eye_offset + current_laser_direction * laser_range
		laser_line.add_point(end_point)

		# Pulse effect
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.02) * 0.3
		laser_line.default_color = Color(1.0, 0.2 * pulse, 0.2 * pulse, 0.9)
		laser_line.width = 6.0 + pulse * 4.0

	# Deal damage on tick
	if laser_tick_timer <= 0:
		laser_tick_timer = laser_tick_rate
		_laser_damage_check()

	# Use IDLE animation during beam firing (ROW_LASER may have empty frames)
	var dir = current_laser_direction
	animation_frame += animation_speed * 0.3 * delta
	var max_frames = FRAME_COUNTS.get(ROW_IDLE, 15)
	if animation_frame >= max_frames:
		animation_frame = 0.0
	var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_IDLE * COLS_PER_ROW + clamped_frame
	if dir.x != 0:
		sprite.flip_h = dir.x < 0

	if laser_timer <= 0:
		_end_laser()

func _laser_damage_check() -> void:
	if player == null or not is_instance_valid(player):
		return

	# Check if player is in the laser line
	var player_pos = player.global_position - global_position
	var laser_end = current_laser_direction * laser_range

	# Calculate distance from player to laser line
	var line_length = laser_end.length()
	var player_proj = player_pos.dot(current_laser_direction)

	# Player must be along the line direction (in front)
	if player_proj < 0 or player_proj > line_length:
		return

	# Calculate perpendicular distance to line
	var closest_point = current_laser_direction * player_proj
	var distance_to_line = (player_pos - closest_point).length()

	# Laser width hit detection
	if distance_to_line < 30.0:
		if player.has_method("take_damage"):
			player.take_damage(laser_damage)

func _end_laser() -> void:
	laser_active = false
	laser_telegraphing = false
	hide_warning()
	_hide_beam_warning()
	if laser_line:
		laser_line.visible = false

func _on_special_complete() -> void:
	super._on_special_complete()
	_end_laser()

func _execute_stomp() -> void:
	# AOE damage around cyclops
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= stomp_aoe_radius:
			if player.has_method("take_damage"):
				player.take_damage(stomp_damage)

	# Screen shake for impact
	if JuiceManager:
		JuiceManager.shake_large()

func _execute_rock_throw() -> void:
	# Clear the landing indicator
	_clear_rock_landing_indicator()

	if rock_projectile_scene == null:
		return

	var projectile = rock_projectile_scene.instantiate()
	projectile.global_position = global_position + Vector2(0, -20)  # Throw from above head

	# Use the locked target position
	projectile.target_position = rock_target_pos
	projectile.has_target = true
	projectile.speed = rock_speed
	projectile.damage = rock_damage

	get_parent().add_child(projectile)

# Override to handle cleanup
func die() -> void:
	_end_laser()
	_clear_rock_landing_indicator()
	super.die()
