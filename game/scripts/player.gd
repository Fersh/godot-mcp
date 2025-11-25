extends CharacterBody2D

@export var speed: float = 180.0  # 3 pixels/frame * 60fps
@export var animation_speed: float = 10.0
@export var attack_cooldown: float = 0.592  # ~1.7 attacks per second (50% slower than original)
@export var fire_range: float = 440.0  # 55 frames * 8 pixels/frame
@export var arrow_scene: PackedScene
@export var max_health: float = 25.0

var current_health: float
@onready var health_bar: Node2D = $HealthBar

var touch_start_pos: Vector2 = Vector2.ZERO
var touch_current_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false

# Animation rows (0-indexed)
const ROW_IDLE = 0          # 4 frames
const ROW_MOVE = 1          # 8 frames
const ROW_SHOOT_STRAIGHT = 2 # 8 frames
const ROW_SHOOT_UP = 3      # 8 frames
const ROW_SHOOT_DOWN = 4    # 8 frames
const ROW_DAMAGE = 5        # 4 frames
const ROW_DEATH = 6         # 4 frames
const ROW_JUMP = 7          # 8 frames

const COLS_PER_ROW = 8

const FRAME_COUNTS = {
	ROW_IDLE: 4,
	ROW_MOVE: 8,
	ROW_SHOOT_STRAIGHT: 8,
	ROW_SHOOT_UP: 8,
	ROW_SHOOT_DOWN: 8,
	ROW_DAMAGE: 4,
	ROW_DEATH: 4,
	ROW_JUMP: 8,
}

var current_row: int = ROW_IDLE
var animation_frame: float = 0.0
@onready var sprite: Sprite2D = $Sprite

# Combat
var attack_timer: float = 0.0
var is_attacking: bool = false
var attack_direction: Vector2 = Vector2.RIGHT
var facing_right: bool = true

# XP System
var current_xp: float = 0.0
var xp_to_next_level: float = 10.0
var current_level: int = 1

signal xp_changed(current_xp: float, xp_needed: float, level: int)
signal level_up(new_level: int)
signal health_changed(current_health: float, max_health: float)
signal player_died()

func _ready() -> void:
	current_health = max_health
	if health_bar:
		health_bar.set_health(current_health, max_health)

func take_damage(amount: float) -> void:
	current_health -= amount
	if health_bar:
		health_bar.set_health(current_health, max_health)
	emit_signal("health_changed", current_health, max_health)

	if current_health <= 0:
		emit_signal("player_died")
		# TODO: Handle player death

func _input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touching = true
			touch_start_pos = event.position
			touch_current_pos = event.position
		else:
			is_touching = false
			velocity = Vector2.ZERO
	elif event is InputEventScreenDrag:
		touch_current_pos = event.position

func _physics_process(delta: float) -> void:
	var direction := Vector2.ZERO

	# Touch/drag input for mobile
	if is_touching:
		var touch_delta = touch_current_pos - touch_start_pos
		if touch_delta.length() > 20.0:
			direction = touch_delta.normalized()

	# Keyboard input for testing (Arrow keys + WASD)
	if Input.is_action_pressed("ui_left") or Input.is_key_pressed(KEY_A):
		direction.x -= 1
	if Input.is_action_pressed("ui_right") or Input.is_key_pressed(KEY_D):
		direction.x += 1
	if Input.is_action_pressed("ui_up") or Input.is_key_pressed(KEY_W):
		direction.y -= 1
	if Input.is_action_pressed("ui_down") or Input.is_key_pressed(KEY_S):
		direction.y += 1

	if direction.length() > 0:
		direction = direction.normalized()

	velocity = direction * speed
	move_and_slide()

	# Keep player within arena bounds (2048x2048)
	const ARENA_SIZE = 2048
	const MARGIN = 40
	position.x = clamp(position.x, MARGIN, ARENA_SIZE - MARGIN)
	position.y = clamp(position.y, MARGIN, ARENA_SIZE - MARGIN)

	# Auto-attack
	attack_timer += delta
	if attack_timer >= attack_cooldown:
		try_attack()

	# Update animation
	update_animation(delta, direction)

func try_attack() -> void:
	var closest_enemy = find_closest_enemy()
	if closest_enemy:
		attack_timer = 0.0
		is_attacking = true
		attack_direction = (closest_enemy.global_position - global_position).normalized()

		# Update facing direction
		if attack_direction.x != 0:
			facing_right = attack_direction.x > 0
			sprite.flip_h = not facing_right

		# Spawn arrow
		spawn_arrow()

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = fire_range  # Only consider enemies within fire range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	return closest

func spawn_arrow() -> void:
	if arrow_scene == null:
		return

	var arrow = arrow_scene.instantiate()
	arrow.global_position = global_position
	arrow.direction = attack_direction
	get_parent().add_child(arrow)

func update_animation(delta: float, move_direction: Vector2) -> void:
	var prev_row = current_row
	var target_row: int

	if is_attacking:
		# Choose shoot animation based on attack direction
		var angle = attack_direction.angle()
		if angle > -PI/4 and angle < PI/4:
			# Shooting right (straight)
			target_row = ROW_SHOOT_STRAIGHT
		elif angle >= PI/4 and angle <= 3*PI/4:
			# Shooting down
			target_row = ROW_SHOOT_DOWN
		elif angle <= -PI/4 and angle >= -3*PI/4:
			# Shooting up
			target_row = ROW_SHOOT_UP
		else:
			# Shooting left (straight, sprite flipped)
			target_row = ROW_SHOOT_STRAIGHT

		# Check if attack animation finished
		if animation_frame >= FRAME_COUNTS.get(target_row, 8) - 1:
			is_attacking = false
	elif move_direction.length() > 0:
		target_row = ROW_MOVE
		# Update facing based on movement when not attacking
		if move_direction.x != 0:
			facing_right = move_direction.x > 0
			sprite.flip_h = not facing_right
	else:
		target_row = ROW_IDLE

	current_row = target_row

	# Reset frame when animation changes
	if prev_row != current_row:
		animation_frame = 0.0

	# Advance animation frame
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0
		if is_attacking:
			is_attacking = false

	# Set the sprite frame
	sprite.frame = current_row * COLS_PER_ROW + int(animation_frame)

func add_xp(amount: float) -> void:
	current_xp += amount
	emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

	while current_xp >= xp_to_next_level:
		current_xp -= xp_to_next_level
		current_level += 1
		xp_to_next_level *= 1.5
		emit_signal("level_up", current_level)
		emit_signal("xp_changed", current_xp, xp_to_next_level, current_level)

func give_kill_xp() -> void:
	# Killing enemy gives 10-20% of XP needed
	var xp_gain = xp_to_next_level * randf_range(0.10, 0.20)
	add_xp(xp_gain)
