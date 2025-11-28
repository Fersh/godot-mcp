extends EliteBase

# Cyclops Elite - Large one-eyed brute with three attack types:
# 1. Stomp - Close range AOE ground slam
# 2. Rock Throw - Ranged projectile attack
# 3. Laser Beam - Targeted line attack from eye

@export var rock_projectile_scene: PackedScene
@export var laser_beam_scene: PackedScene

# Attack-specific stats
@export var stomp_damage: float = 30.0  # Reduced from 40
@export var stomp_range: float = 80.0
@export var stomp_aoe_radius: float = 100.0

@export var rock_damage: float = 22.5  # Reduced 25% from 30
@export var rock_range: float = 300.0
@export var rock_speed: float = 150.0  # Slower, easier to dodge

@export var laser_damage: float = 15.0  # Per tick - reduced 25% from 20
@export var laser_range: float = 300.0  # Reduced 25% from 400
@export var laser_duration: float = 2.0
@export var laser_tick_rate: float = 0.25

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

# Stomp state
var stomp_active: bool = false
var stomp_windup_timer: float = 0.0
const STOMP_WINDUP: float = 0.6

# Throw state
var throw_active: bool = false
var throw_windup_timer: float = 0.0
const THROW_WINDUP: float = 0.4

func _setup_elite() -> void:
	elite_name = "Cyclops"
	enemy_type = "cyclops"

	# Cyclops stats - 37.5x health (elite!), slower, hits hard
	speed = 60.0  # Slower than most enemies
	max_health = 750.0  # 50% more health
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
	update_animation(0, ROW_THROW, dir)
	animation_frame = 0

func _start_laser_beam() -> void:
	show_warning()
	is_using_special = true
	laser_active = true
	laser_timer = laser_duration
	laser_tick_timer = 0.0
	special_timer = laser_duration + 0.5  # Extra time for animation

	if player and is_instance_valid(player):
		current_laser_direction = (player.global_position - global_position).normalized()
		laser_target_pos = player.global_position

	# Use attack animation (stomp) during eye beam, not laser pose
	var dir = current_laser_direction
	update_animation(0, ROW_ATTACK, dir)
	animation_frame = 0

	# Create laser visual
	_create_laser_line()

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
		laser_line.add_point(Vector2.ZERO)  # Start at cyclops
		var end_point = current_laser_direction * laser_range
		laser_line.add_point(end_point)

		# Pulse effect
		var pulse = 0.7 + sin(Time.get_ticks_msec() * 0.02) * 0.3
		laser_line.default_color = Color(1.0, 0.2 * pulse, 0.2 * pulse, 0.9)
		laser_line.width = 6.0 + pulse * 4.0

	# Deal damage on tick
	if laser_tick_timer <= 0:
		laser_tick_timer = laser_tick_rate
		_laser_damage_check()

	# Animate attack pose during laser - loop the attack animation
	var dir = current_laser_direction
	animation_frame += animation_speed * 0.5 * delta
	var max_frames = FRAME_COUNTS.get(ROW_ATTACK, 13)
	# Loop the attack animation
	if animation_frame >= max_frames:
		animation_frame = 0.0
	var clamped_frame = clampi(int(animation_frame), 0, max_frames - 1)
	sprite.frame = ROW_ATTACK * COLS_PER_ROW + clamped_frame
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
	hide_warning()
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
	if rock_projectile_scene == null or player == null or not is_instance_valid(player):
		return

	var projectile = rock_projectile_scene.instantiate()
	projectile.global_position = global_position + Vector2(0, -20)  # Throw from above head

	var direction = (player.global_position - global_position).normalized()
	projectile.direction = direction
	projectile.speed = rock_speed
	projectile.damage = rock_damage

	get_parent().add_child(projectile)

# Override to handle cleanup
func die() -> void:
	_end_laser()
	super.die()
