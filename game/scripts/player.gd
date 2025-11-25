extends CharacterBody2D

@export var speed: float = 400.0

var touch_start_pos: Vector2 = Vector2.ZERO
var touch_current_pos: Vector2 = Vector2.ZERO
var is_touching: bool = false

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

func _physics_process(_delta: float) -> void:
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
