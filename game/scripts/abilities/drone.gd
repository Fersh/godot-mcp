extends Node2D

var drone_index: int = 0
var target_offset: Vector2 = Vector2(-50, -50)
var follow_speed: float = 200.0
var fire_range: float = 300.0
var fire_cooldown: float = 2.4
var fire_timer: float = 0.0
var damage: float = 5.4  # 80% increase from 3.0

# Animation state
var blink_timer: float = 0.0
var blink_interval: float = 3.0  # Blink every 3 seconds
var is_blinking: bool = false
var blink_duration: float = 0.15
var eyebrow_anger: float = 0.0  # 0 = neutral, 1 = angry (when shooting)
var hover_offset: float = 0.0
var current_target: Node2D = null

@onready var player: Node2D = null

func _ready() -> void:
	# Add to minions group for summon tracking
	add_to_group("minions")

	player = get_tree().get_first_node_in_group("player")

	# Offset based on index
	match drone_index % 4:
		0: target_offset = Vector2(-50, -50)
		1: target_offset = Vector2(50, -50)
		2: target_offset = Vector2(-50, 50)
		3: target_offset = Vector2(50, 50)

	if player:
		global_position = player.global_position + target_offset

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# Follow player with offset
	var target_pos = player.global_position + target_offset
	global_position = global_position.move_toward(target_pos, follow_speed * delta)

	# Hover animation
	hover_offset = sin(Time.get_ticks_msec() / 200.0) * 2.0

	# Blink logic
	blink_timer += delta
	if is_blinking:
		if blink_timer >= blink_duration:
			is_blinking = false
			blink_timer = 0.0
			blink_interval = randf_range(2.0, 4.0)  # Randomize next blink
	else:
		if blink_timer >= blink_interval:
			is_blinking = true
			blink_timer = 0.0

	# Eyebrow anger decay
	eyebrow_anger = move_toward(eyebrow_anger, 0.0, delta * 2.0)

	# Find current target for look direction
	current_target = find_closest_enemy()

	# Try to shoot
	fire_timer += delta
	if fire_timer >= fire_cooldown:
		try_fire()

	queue_redraw()

func find_closest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = fire_range
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy
	return closest

func try_fire() -> void:
	var closest = find_closest_enemy()
	if closest:
		fire_timer = 0.0
		eyebrow_anger = 1.0  # Get angry when shooting
		fire_at(closest)

func fire_at(target: Node2D) -> void:
	# Create a simple projectile line
	var line = Line2D.new()
	line.add_point(global_position)
	line.add_point(target.global_position)
	line.width = 2.0
	line.default_color = Color(1.0, 0.8, 0.3, 1.0)
	get_parent().add_child(line)

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# Try to draw aggro from the enemy we attacked
	if target.has_method("draw_aggro"):
		target.draw_aggro(self)

	# Fade out line
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

func _draw() -> void:
	var p = 2.0  # Pixel size
	var y_off = hover_offset  # Bobbing motion

	# Colors
	var body_dark = Color(0.35, 0.4, 0.5, 1.0)
	var body_light = Color(0.55, 0.6, 0.7, 1.0)
	var body_highlight = Color(0.7, 0.75, 0.85, 1.0)
	var eye_white = Color(0.95, 0.95, 0.95, 1.0)
	var eye_pupil = Color(0.1, 0.1, 0.15, 1.0)
	var eyebrow_color = Color(0.25, 0.25, 0.3, 1.0)

	# Body - rounded robot shape (10x8 pixels, scaled by p)
	# Row 1 (top) - 6 pixels centered
	draw_rect(Rect2(-3 * p, -4 * p + y_off, 6 * p, p), body_dark)
	# Row 2 - 8 pixels
	draw_rect(Rect2(-4 * p, -3 * p + y_off, 8 * p, p), body_light)
	# Row 3-5 - full 10 pixels wide (main body)
	draw_rect(Rect2(-5 * p, -2 * p + y_off, 10 * p, p), body_light)
	draw_rect(Rect2(-5 * p, -1 * p + y_off, 10 * p, p), body_light)
	draw_rect(Rect2(-5 * p, 0 + y_off, 10 * p, p), body_light)
	# Row 6-7 - 8 pixels
	draw_rect(Rect2(-4 * p, 1 * p + y_off, 8 * p, p), body_light)
	draw_rect(Rect2(-4 * p, 2 * p + y_off, 8 * p, p), body_dark)
	# Row 8 (bottom) - 6 pixels centered
	draw_rect(Rect2(-3 * p, 3 * p + y_off, 6 * p, p), body_dark)

	# Highlight on top-left
	draw_rect(Rect2(-3 * p, -3 * p + y_off, 2 * p, p), body_highlight)
	draw_rect(Rect2(-4 * p, -2 * p + y_off, p, 2 * p), body_highlight)

	# Calculate eye offset based on target direction
	var look_offset = Vector2.ZERO
	if current_target and is_instance_valid(current_target):
		var dir = (current_target.global_position - global_position).normalized()
		look_offset = dir * p * 0.5

	# Eyes - white background (2x3 pixels each)
	var left_eye_x = -3 * p
	var right_eye_x = 1 * p
	var eye_y = -1 * p + y_off

	if is_blinking:
		# Closed eyes - just a line
		draw_rect(Rect2(left_eye_x, eye_y + p, 2 * p, p), eye_pupil)
		draw_rect(Rect2(right_eye_x, eye_y + p, 2 * p, p), eye_pupil)
	else:
		# Open eyes
		draw_rect(Rect2(left_eye_x, eye_y, 2 * p, 3 * p), eye_white)
		draw_rect(Rect2(right_eye_x, eye_y, 2 * p, 3 * p), eye_white)

		# Pupils (1x2 pixels, offset by look direction)
		var pupil_off_x = clamp(look_offset.x, -p * 0.5, p * 0.5)
		var pupil_off_y = clamp(look_offset.y, -p * 0.5, p * 0.5)
		draw_rect(Rect2(left_eye_x + p * 0.5 + pupil_off_x, eye_y + p * 0.5 + pupil_off_y, p, 2 * p), eye_pupil)
		draw_rect(Rect2(right_eye_x + p * 0.5 + pupil_off_x, eye_y + p * 0.5 + pupil_off_y, p, 2 * p), eye_pupil)

	# Eyebrows - animate based on anger
	var brow_y = -2.5 * p + y_off
	var anger_offset = eyebrow_anger * p  # How much inner edge drops when angry

	# Left eyebrow (angled when angry: inner edge lower)
	draw_line(
		Vector2(left_eye_x - p * 0.5, brow_y),
		Vector2(left_eye_x + 2.5 * p, brow_y + anger_offset),
		eyebrow_color, p
	)
	# Right eyebrow (mirrored)
	draw_line(
		Vector2(right_eye_x + 2.5 * p, brow_y),
		Vector2(right_eye_x - p * 0.5, brow_y + anger_offset),
		eyebrow_color, p
	)

	# Antenna/sensor on top
	draw_rect(Rect2(-p * 0.5, -5.5 * p + y_off, p, 2 * p), body_dark)
	draw_rect(Rect2(-p, -6 * p + y_off, 2 * p, p), Color(0.3, 0.8, 0.4, 1.0))  # Green light

	# Hover glow effect underneath
	var glow_alpha = 0.3 + sin(Time.get_ticks_msec() / 100.0) * 0.1
	draw_rect(Rect2(-3 * p, 4 * p + y_off, 6 * p, p), Color(0.4, 0.7, 1.0, glow_alpha))
