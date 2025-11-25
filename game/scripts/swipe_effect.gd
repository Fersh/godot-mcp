extends Node2D

# Melee swipe arc effect for knight attacks

var direction: Vector2 = Vector2.RIGHT
var arc_angle: float = PI / 2  # 90 degrees (25% of circle)
var arc_radius: float = 80.0
var lifetime: float = 0.25
var timer: float = 0.0

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
	var base_angle = direction.angle()
	var start_angle = base_angle - arc_angle / 2
	var end_angle = base_angle + arc_angle / 2

	# Calculate current sweep position
	var sweep_angle = start_angle + arc_progress * arc_angle

	# Draw the main arc sweep line
	var sweep_alpha = 1.0 - (timer / lifetime)
	var sweep_color = Color(1.0, 1.0, 1.0, sweep_alpha * 0.8)

	# Draw arc outline (multiple lines for thickness)
	var arc_points = 16
	var prev_point = Vector2.ZERO
	for i in range(arc_points + 1):
		var t = float(i) / float(arc_points)
		var current_angle = start_angle + t * arc_angle * arc_progress
		var point = Vector2(cos(current_angle), sin(current_angle)) * arc_radius

		if i > 0:
			var line_alpha = sweep_alpha * (0.5 + 0.5 * t)  # Brighter at the leading edge
			draw_line(prev_point, point, Color(1.0, 1.0, 1.0, line_alpha), 3.0)
		prev_point = point

	# Draw the leading edge (bright slash tip)
	if arc_progress > 0.1:
		var tip_pos = Vector2(cos(sweep_angle), sin(sweep_angle)) * arc_radius
		var tip_inner = Vector2(cos(sweep_angle), sin(sweep_angle)) * (arc_radius * 0.4)
		draw_line(tip_inner, tip_pos, Color(1.0, 1.0, 0.9, sweep_alpha), 4.0)
		# Glow at tip
		draw_circle(tip_pos, 6 * sweep_alpha, Color(1.0, 1.0, 0.8, sweep_alpha * 0.6))

	# Draw trail particles
	for p in trail_particles:
		var age = timer - p.spawn_time
		if age > 0 and p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var pixel_pos = Vector2(round(pos.x), round(pos.y))
			var color = Color(1.0, 1.0, 1.0, p.alpha * 0.7)
			var rect = Rect2(pixel_pos - Vector2(p.size / 2, p.size / 2), Vector2(p.size, p.size))
			draw_rect(rect, color)

	# Draw origin burst
	var burst_alpha = max(0, 1.0 - timer / 0.1) * 0.5
	if burst_alpha > 0:
		draw_circle(Vector2.ZERO, 8, Color(1.0, 1.0, 0.9, burst_alpha))
