extends Control
class_name VirtualJoystick

signal direction_changed(direction: Vector2)

const JOYSTICK_RADIUS := 80.0
const KNOB_RADIUS := 35.0
const DEADZONE := 0.15
const TRANSPARENCY_IDLE := 0.25  # More transparent when not being used
const TRANSPARENCY_ACTIVE := 0.6  # More visible when pressed
const SMOOTHING_ACCEL := 8.0  # Smooth ease into movement
const SMOOTHING_DECEL := 50.0  # Quick response when stopping or changing direction

# Absolute direction mode - direction based on screen position, not joystick-relative
const USE_ABSOLUTE_DIRECTION := true
const ABSOLUTE_DEADZONE_RADIUS := 40.0  # Deadzone radius for absolute mode

var is_active: bool = false
var touch_index: int = -1
var current_direction: Vector2 = Vector2.ZERO
var target_direction: Vector2 = Vector2.ZERO  # Raw input direction
var knob_offset: Vector2 = Vector2.ZERO
var target_knob_offset: Vector2 = Vector2.ZERO  # Raw knob position
var touch_start_pos: Vector2 = Vector2.ZERO  # Where the touch started (for absolute direction)

func _ready() -> void:
	modulate.a = TRANSPARENCY_IDLE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(true)

func _process(delta: float) -> void:
	# Determine smoothing based on whether we're accelerating or decelerating
	var target_magnitude = target_direction.length()
	var current_magnitude = current_direction.length()

	# Use fast smoothing when:
	# - Stopping (target is zero/near-zero)
	# - Changing direction significantly while moving
	var is_stopping = target_magnitude < 0.1
	var is_changing_direction = current_magnitude > 0.1 and target_magnitude > 0.1 and current_direction.dot(target_direction) < 0.7

	var direction_smoothing: float
	if is_stopping:
		# Immediate stop when released
		current_direction = Vector2.ZERO
		direction_smoothing = SMOOTHING_DECEL
	elif is_changing_direction:
		# Quick response when changing direction while moving
		direction_smoothing = SMOOTHING_DECEL
	else:
		# Smooth ease into movement when starting or continuing same direction
		direction_smoothing = SMOOTHING_ACCEL

	# Smoothly interpolate knob position (visual only - always smooth)
	var knob_smoothing = SMOOTHING_DECEL if is_stopping else SMOOTHING_ACCEL * 1.5
	knob_offset = knob_offset.lerp(target_knob_offset, knob_smoothing * delta)

	# Apply direction smoothing (skip if already set to zero above)
	if not is_stopping:
		current_direction = current_direction.lerp(target_direction, direction_smoothing * delta)

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

	# Exclude top HUD area (portrait, health bars, etc.) - approximately top 120px
	const HUD_EXCLUSION_HEIGHT := 120.0
	const HUD_EXCLUSION_WIDTH := 320.0  # Left side HUD width

	if event is InputEventScreenTouch:
		# Only respond to left half of screen, excluding HUD area at top-left
		var in_left_half = event.position.x < viewport_size.x / 2
		var in_hud_area = event.position.x < HUD_EXCLUSION_WIDTH and event.position.y < HUD_EXCLUSION_HEIGHT

		if in_left_half and not in_hud_area:
			if event.pressed and not is_active:
				is_active = true
				touch_index = event.index
				touch_start_pos = event.position  # Store where touch started for absolute direction
				modulate.a = TRANSPARENCY_ACTIVE  # Make more visible when touched
				_update_knob(event.position)
			elif not event.pressed and event.index == touch_index:
				_reset()
		elif not event.pressed and event.index == touch_index:
			# Always allow release even if finger moved to HUD area
			_reset()

	elif event is InputEventScreenDrag:
		if event.index == touch_index and is_active:
			_update_knob(event.position)

func _update_knob(touch_pos: Vector2) -> void:
	# Calculate movement direction
	if USE_ABSOLUTE_DIRECTION:
		# Absolute direction mode: direction is based on movement from touch start position
		# This means if you move left from where you started touching, character moves left
		var direction_delta = touch_pos - touch_start_pos
		var direction_distance = direction_delta.length()

		# Use a deadzone for absolute direction
		if direction_distance > ABSOLUTE_DEADZONE_RADIUS:
			target_direction = direction_delta.normalized()
			# Visual knob reflects movement direction, scaled to joystick radius
			var knob_magnitude = clamp(direction_distance / 150.0, 0.0, 1.0) * JOYSTICK_RADIUS
			target_knob_offset = target_direction * knob_magnitude
		else:
			target_direction = Vector2.ZERO
			target_knob_offset = Vector2.ZERO
	else:
		# Relative direction mode: direction based on joystick position
		var visual_delta = touch_pos - global_position
		var visual_distance = visual_delta.length()

		# Clamp knob to joystick radius for visual
		if visual_distance > JOYSTICK_RADIUS:
			visual_delta = visual_delta.normalized() * JOYSTICK_RADIUS

		target_knob_offset = visual_delta

		if visual_distance > DEADZONE * JOYSTICK_RADIUS:
			target_direction = visual_delta.normalized()
		else:
			target_direction = Vector2.ZERO

func _reset() -> void:
	is_active = false
	touch_index = -1
	target_direction = Vector2.ZERO
	target_knob_offset = Vector2.ZERO
	# Fade back to idle transparency
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", TRANSPARENCY_IDLE, 0.2)
	# Don't instantly reset - let smoothing bring it back to center

func get_direction() -> Vector2:
	return current_direction
