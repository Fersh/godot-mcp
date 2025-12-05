extends Node2D

# Cleave Executioner - T2 Cleave with blood splatter and heavier impact

var pixel_size := 4
var duration := 0.5
var elapsed := 0.0

# Main arc slash (wider and heavier than T1)
var arc_progress := 0.0
var arc_width := 100.0
var arc_angle_span := PI * 0.8

# Blood splatter particles
var blood_particles := []
var num_blood := 14

# Heavy impact sparks
var sparks := []
var num_sparks := 10

# Trail segments
var trail_segments := []

func _ready() -> void:
	# Initialize blood particles
	for i in range(num_blood):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		blood_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 60),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(80, 160),
			"size": randi_range(1, 3) * pixel_size,
			"alpha": 1.0,
			"gravity": randf_range(150, 300)
		})

	# Initialize sparks
	for i in range(num_sparks):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		sparks.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 250),
			"alpha": 1.0
		})

	# Initialize trail
	for i in range(8):
		trail_segments.append({
			"alpha": 0.0,
			"angle": 0.0
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Arc sweeps quickly
	arc_progress = ease(min(progress * 2.5, 1.0), 0.2)

	# Update trail
	for i in range(trail_segments.size()):
		var delay = i * 0.02
		if elapsed > delay:
			var t = (elapsed - delay) / 0.15
			trail_segments[i].alpha = max(0, 1.0 - t)
			trail_segments[i].angle = -arc_angle_span/2 + arc_progress * arc_angle_span * (1.0 - float(i) / trail_segments.size())

	# Update blood
	for blood in blood_particles:
		blood.velocity.y += blood.gravity * delta
		blood.pos += blood.velocity * delta
		blood.alpha = max(0, 1.0 - progress * 1.2)

	# Update sparks
	for spark in sparks:
		spark.velocity *= 0.92
		spark.pos += spark.velocity * delta
		spark.alpha = max(0, 1.0 - progress * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw trail (red tinted)
	for seg in trail_segments:
		if seg.alpha > 0:
			var color = Color(0.8, 0.2, 0.2, seg.alpha * 0.4)
			var angle = seg.angle - PI/2
			for r in range(int(arc_width / pixel_size)):
				var radius = 30 + r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw main arc (dark red edge, bright core)
	if arc_progress > 0:
		var current_angle = -arc_angle_span/2 + arc_progress * arc_angle_span - PI/2

		# Draw arc sweep
		var steps = int(arc_angle_span * arc_progress * 20)
		for i in range(steps):
			var t = float(i) / max(steps, 1)
			var angle = -arc_angle_span/2 - PI/2 + t * arc_angle_span * arc_progress
			var fade = 1.0 - (float(i) / steps) * 0.5

			# Outer edge (dark red)
			var outer_color = Color(0.6, 0.1, 0.1, fade * 0.8)
			for r in range(3):
				var radius = arc_width - r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), outer_color)

			# Core (bright)
			var core_color = Color(1.0, 0.8, 0.7, fade)
			for r in range(2):
				var radius = 40 + r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), core_color)

	# Draw blood particles (dark red)
	for blood in blood_particles:
		if blood.alpha > 0:
			var color = Color(0.7, 0.1, 0.1, blood.alpha)
			var pos = (blood.pos / pixel_size).floor() * pixel_size
			var size = Vector2(blood.size, blood.size)
			draw_rect(Rect2(pos - size/2, size), color)

	# Draw sparks (orange/yellow)
	for spark in sparks:
		if spark.alpha > 0:
			var color = Color(1.0, 0.7, 0.3, spark.alpha)
			var pos = (spark.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
