extends Node2D

# Melee swipe arc effect for knight attacks
# Also supports claw marks for beast attacks

var direction: Vector2 = Vector2.RIGHT
var arc_angle: float = PI / 2  # 90 degrees base, modified by melee_area
var arc_radius: float = 80.0  # Modified by melee_range
var lifetime: float = 0.25
var timer: float = 0.0
var tint_color: Color = Color.WHITE  # Elemental tint
var is_claw_attack: bool = false  # Beast claw marks mode

# Arc animation
var arc_progress: float = 0.0
var arc_speed: float = 8.0  # How fast the arc sweeps

# Trail particles
var trail_particles: Array = []
const TRAIL_COUNT: int = 12

class TrailParticle:
	var angle: float
	var radius: float
	var alpha: float
	var size: float
	var spawn_time: float

func _ready() -> void:
	# Spawn initial trail particles along the arc
	spawn_trail()

func spawn_trail() -> void:
	var start_angle = direction.angle() - arc_angle / 2
	for i in TRAIL_COUNT:
		var p = TrailParticle.new()
		var t = float(i) / float(TRAIL_COUNT - 1)
		p.angle = start_angle + t * arc_angle
		p.radius = arc_radius * randf_range(0.7, 1.0)
		p.alpha = 1.0
		p.size = randf_range(3, 6)
		p.spawn_time = t * 0.1  # Stagger spawn times for sweep effect
		trail_particles.append(p)

func _process(delta: float) -> void:
	timer += delta
	arc_progress = min(timer * arc_speed, 1.0)

	# Update trail particles
	for p in trail_particles:
		var age = timer - p.spawn_time
		if age > 0:
			p.alpha = max(0, 1.0 - age / (lifetime * 0.8))
			p.radius += delta * 40  # Expand outward slightly

	queue_redraw()

	if timer >= lifetime:
		queue_free()

func _draw() -> void:
	if is_claw_attack:
		_draw_claw_marks()
	else:
		_draw_arc_sweep()

func _draw_claw_marks() -> void:
	var sweep_alpha = 1.0 - (timer / lifetime)
	var claw_color = Color(tint_color.r, tint_color.g, tint_color.b, sweep_alpha)

	# Draw 3 parallel claw slash marks
	var base_angle = direction.angle()
	var claw_spread = 0.3  # Angle spread between claws
	var claw_length = arc_radius * arc_progress

	for i in range(3):
		var offset_angle = (i - 1) * claw_spread  # -1, 0, 1 for spread
		var claw_angle = base_angle + offset_angle * 0.4

		# Each claw is a curved slash line
		var start_dist = arc_radius * 0.2
		var end_dist = start_dist + claw_length * 0.8

		# Draw multiple segments for curved claw effect
		var segments = 6
		var prev_point: Vector2
		for j in range(segments + 1):
			var t = float(j) / float(segments)
			# Curve the claw slightly
			var curve_offset = sin(t * PI) * 0.15 * (i - 1)
			var seg_angle = claw_angle + curve_offset
			var seg_dist = lerp(start_dist, end_dist, t)
			var point = Vector2(cos(seg_angle), sin(seg_angle)) * seg_dist

			if j > 0:
				# Thicker at start, thinner at tip
				var thickness = lerp(4.0, 1.5, t)
				var line_alpha = sweep_alpha * lerp(0.6, 1.0, t)
				var line_color = Color(claw_color.r, claw_color.g, claw_color.b, line_alpha)
				draw_line(prev_point, point, line_color, thickness)
			prev_point = point

		# Draw claw tip highlight
		if arc_progress > 0.3:
			var tip_pos = Vector2(cos(claw_angle), sin(claw_angle)) * end_dist
			var tip_color = Color(1.0, 0.9, 0.8, sweep_alpha * 0.8)
			draw_circle(tip_pos, 2.5 * sweep_alpha, tip_color)

	# Draw small blood/impact particles
	for p in trail_particles:
		var age = timer - p.spawn_time
		if age > 0 and p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius * 0.8
			var pixel_pos = Vector2(round(pos.x), round(pos.y))
			# Reddish particles for claw attacks
			var color = Color(1.0, 0.3, 0.2, p.alpha * 0.5)
			var rect = Rect2(pixel_pos - Vector2(p.size / 2, p.size / 2), Vector2(p.size, p.size))
			draw_rect(rect, color)

func _draw_arc_sweep() -> void:
	var base_angle = direction.angle()
	var start_angle = base_angle - arc_angle / 2

	# Calculate current sweep position
	var sweep_angle = start_angle + arc_progress * arc_angle

	# Draw the main arc sweep line
	var sweep_alpha = 1.0 - (timer / lifetime)

	# Draw arc outline (multiple lines for thickness)
	var arc_points = 16
	var prev_point = Vector2.ZERO
	for i in range(arc_points + 1):
		var t = float(i) / float(arc_points)
		var current_angle = start_angle + t * arc_angle * arc_progress
		var point = Vector2(cos(current_angle), sin(current_angle)) * arc_radius

		if i > 0:
			var line_alpha = sweep_alpha * (0.5 + 0.5 * t)  # Brighter at the leading edge
			draw_line(prev_point, point, Color(tint_color.r, tint_color.g, tint_color.b, line_alpha), 3.0)
		prev_point = point

	# Draw the leading edge (bright slash tip)
	if arc_progress > 0.1:
		var tip_pos = Vector2(cos(sweep_angle), sin(sweep_angle)) * arc_radius
		var tip_inner = Vector2(cos(sweep_angle), sin(sweep_angle)) * (arc_radius * 0.4)
		var tip_color = Color(tint_color.r, tint_color.g, min(tint_color.b + 0.1, 1.0), sweep_alpha)
		draw_line(tip_inner, tip_pos, tip_color, 4.0)
		# Glow at tip
		var glow_color = Color(tint_color.r, tint_color.g, min(tint_color.b + 0.1, 1.0), sweep_alpha * 0.6)
		draw_circle(tip_pos, 6 * sweep_alpha, glow_color)

	# Draw trail particles
	for p in trail_particles:
		var age = timer - p.spawn_time
		if age > 0 and p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var pixel_pos = Vector2(round(pos.x), round(pos.y))
			var color = Color(tint_color.r, tint_color.g, tint_color.b, p.alpha * 0.7)
			var rect = Rect2(pixel_pos - Vector2(p.size / 2, p.size / 2), Vector2(p.size, p.size))
			draw_rect(rect, color)

	# Draw origin burst
	var burst_alpha = max(0, 1.0 - timer / 0.1) * 0.5
	if burst_alpha > 0:
		var burst_color = Color(tint_color.r, tint_color.g, min(tint_color.b + 0.1, 1.0), burst_alpha)
		draw_circle(Vector2.ZERO, 8, burst_color)
