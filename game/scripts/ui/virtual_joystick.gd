extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

const JOYSTICK_RADIUS := 80.0
const KNOB_RADIUS := 35.0
const DEADZONE := 0.15
const TRANSPARENCY := 0.5
const SMOOTHING := 12.0  # Lower = smoother/slower response

var is_active: bool = false
var touch_index: int = -1
var current_direction: Vector2 = Vector2.ZERO
var target_direction: Vector2 = Vector2.ZERO  # Raw input direction
var knob_offset: Vector2 = Vector2.ZERO
var target_knob_offset: Vector2 = Vector2.ZERO  # Raw knob position

func _ready() -> void:
	modulate.a = TRANSPARENCY
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	# Smoothly interpolate knob position and direction
	knob_offset = knob_offset.lerp(target_knob_offset, SMOOTHING * delta)
	current_direction = current_direction.lerp(target_direction, SMOOTHING * delta)

	# Snap to zero if very close (avoid tiny movements)
	if current_direction.length() < 0.01:
		current_direction = Vector2.ZERO

	queue_redraw()
	emit_signal("direction_changed", current_direction)

func _draw() -> void:
	# Draw outer ring background
	draw_circle(Vector2.ZERO, JOYSTICK_RADIUS, Color(0.15, 0.15, 0.2, 0.6))
	draw_arc(Vector2.ZERO, JOYSTICK_RADIUS, 0, TAU, 64, Color(0.5, 0.5, 0.6, 0.8), 3.0, true)

	# Draw inner knob
	draw_circle(knob_offset, KNOB_RADIUS, Color(0.4, 0.4, 0.5, 0.9))
	draw_arc(knob_offset, KNOB_RADIUS, 0, TAU, 32, Color(0.6, 0.6, 0.7, 1.0), 2.0, true)

func _input(event: InputEvent) -> void:
	var viewport_size = get_viewport().get_visible_rect().size

	if event is InputEventScreenTouch:
		# Only respond to left half of screen
		if event.position.x < viewport_size.x / 2:
			if event.pressed and not is_active:
				is_active = true
				touch_index = event.index
				_update_knob(event.position)
			elif not event.pressed and event.index == touch_index:
				_reset()

	elif event is InputEventScreenDrag:
		if event.index == touch_index and is_active:
			_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	var delta = touch_pos - global_position
	var distance = delta.length()

	# Clamp knob to joystick radius
	if distance > JOYSTICK_RADIUS:
		delta = delta.normalized() * JOYSTICK_RADIUS

	# Set target knob position (smoothing happens in _process)
	target_knob_offset = delta

	# Calculate target direction with deadzone
	if distance > DEADZONE * JOYSTICK_RADIUS:
		target_direction = delta.normalized()
	else:
		target_direction = Vector2.ZERO

func _reset() -> void:
	is_active = false
	touch_index = -1
	target_direction = Vector2.ZERO
	target_knob_offset = Vector2.ZERO
	# Don't instantly reset - let smoothing bring it back to center

func get_direction() -> Vector2:
	return current_direction
