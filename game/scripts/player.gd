extends CharacterBody2D

@export var speed: float = 400.0
@export var animation_speed: float = 10.0

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

const COLS_PER_ROW = 8  # Spritesheet has 8 columns

# Frame counts per animation
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

func _input(event: InputEvent) -> void:
	# Handle touch input for mobile
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
		if touch_delta.length() > 20.0:  # Dead zone
			direction = touch_delta.normalized()

	# Keyboard input for testing on desktop (Arrow keys + WASD)
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

	# Keep player within screen bounds
	var viewport_size = get_viewport_rect().size
	position.x = clamp(position.x, 40, viewport_size.x - 40)
	position.y = clamp(position.y, 40, viewport_size.y - 40)

	# Update animation
	update_animation(delta, direction)

func update_animation(delta: float, direction: Vector2) -> void:
	var prev_row = current_row

	# Choose animation row based on movement
	if direction.length() > 0:
		current_row = ROW_MOVE
		# Flip sprite based on horizontal direction
		if direction.x != 0:
			sprite.flip_h = direction.x < 0
	else:
		current_row = ROW_IDLE

	# Reset frame when animation changes
	if prev_row != current_row:
		animation_frame = 0.0

	# Advance animation frame
	animation_frame += animation_speed * delta
	var max_frames = FRAME_COUNTS.get(current_row, 8)
	if animation_frame >= max_frames:
		animation_frame = 0.0

	# Set the sprite frame (row * cols_per_row + current_frame)
	sprite.frame = current_row * COLS_PER_ROW + int(animation_frame)
