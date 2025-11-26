extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

const JOYSTICK_RADIUS := 80.0
const KNOB_RADIUS := 35.0
const DEADZONE := 0.15
const TRANSPARENCY := 0.5

var is_active: bool = false
var touch_index: int = -1
var current_direction: Vector2 = Vector2.ZERO
var knob_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	modulate.a = TRANSPARENCY
	mouse_filter = Control.MOUSE_FILTER_IGNORE

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

	# Update knob visual position
	knob_offset = delta
	queue_redraw()

	# Calculate direction with deadzone
	if distance > DEADZONE * JOYSTICK_RADIUS:
		current_direction = delta.normalized()
	else:
		current_direction = Vector2.ZERO

	emit_signal("direction_changed", current_direction)

func _reset() -> void:
	is_active = false
	touch_index = -1
	current_direction = Vector2.ZERO
	knob_offset = Vector2.ZERO
	queue_redraw()
	emit_signal("direction_changed", Vector2.ZERO)

func get_direction() -> Vector2:
	return current_direction
