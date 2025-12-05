extends Node2D

# Blade Rush - T2 Dash with multiple slashing attacks during movement

var pixel_size := 4
var duration := 0.5
var elapsed := 0.0

# Dash blur
var dash_progress := 0.0
var dash_length := 80.0

# Slash marks along path
var slashes := []
var num_slashes := 4

# Speed particles
var speed_particles := []
var num_particles := 16

# Blade gleams
var gleams := []

func _ready() -> void:
	# Initialize slashes along dash path
	for i in range(num_slashes):
		var x_pos = (i + 1) * dash_length / (num_slashes + 1) - dash_length / 2
		slashes.append({
			"pos": Vector2(x_pos, randf_range(-10, 10)),
			"angle": randf_range(-PI/4, PI/4),
			"progress": 0.0,
			"trigger_time": 0.05 + i * 0.08,
			"length": randf_range(30, 45)
		})
		# Add gleam for each slash
		gleams.append({
			"pos": Vector2(x_pos, randf_range(-5, 5)),
			"alpha": 0.0,
			"trigger_time": 0.05 + i * 0.08
		})

	# Initialize speed particles
	for i in range(num_particles):
		speed_particles.append({
			"pos": Vector2(randf_range(-40, 40), randf_range(-15, 15)),
			"velocity": Vector2(randf_range(-200, -100), 0),
			"alpha": 0.7,
			"length": randf_range(15, 30)
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Dash moves across
	dash_progress = ease(progress, 0.2)

	# Update slashes
	for slash in slashes:
		if elapsed > slash.trigger_time:
			var slash_age = elapsed - slash.trigger_time
			if slash_age < 0.1:
				slash.progress = slash_age / 0.1
			else:
				slash.progress = max(0, 1.0 - (slash_age - 0.1) / 0.15)

	# Update gleams
	for gleam in gleams:
		if elapsed > gleam.trigger_time:
			var gleam_age = elapsed - gleam.trigger_time
			if gleam_age < 0.05:
				gleam.alpha = gleam_age / 0.05
			else:
				gleam.alpha = max(0, 1.0 - (gleam_age - 0.05) / 0.1)

	# Update speed particles
	for p in speed_particles:
		p.pos += p.velocity * delta
		p.alpha = max(0, 0.7 - progress)

	queue_redraw()

func _draw() -> void:
	# Draw speed particles (horizontal blur lines)
	for p in speed_particles:
		if p.alpha > 0:
			var color = Color(0.8, 0.85, 0.95, p.alpha * 0.5)
			_draw_pixel_line(p.pos, p.pos + Vector2(p.length, 0), color)

	# Draw dash trail
	var trail_alpha = 0.6 * (1.0 - elapsed / duration)
	var trail_color = Color(0.7, 0.75, 0.9, trail_alpha)
	var trail_start = Vector2(-dash_length / 2, 0)
	var trail_end = Vector2(-dash_length / 2 + dash_progress * dash_length, 0)
	for y_off in range(-2, 3):
		_draw_pixel_line(trail_start + Vector2(0, y_off * pixel_size), trail_end + Vector2(0, y_off * pixel_size), trail_color)

	# Draw slashes
	for slash in slashes:
		if slash.progress > 0:
			var color = Color(1.0, 0.95, 0.9, slash.progress * 0.9)
			var half_len = slash.length * slash.progress / 2
			var dir = Vector2(cos(slash.angle), sin(slash.angle))
			var start = slash.pos - dir * half_len
			var end = slash.pos + dir * half_len
			_draw_pixel_line(start, end, color)
			# Edge highlight
			var highlight = Color(1.0, 1.0, 1.0, slash.progress * 0.6)
			_draw_pixel_line(start + Vector2(0, -pixel_size), end + Vector2(0, -pixel_size), highlight)

	# Draw gleams (bright flash at slash point)
	for gleam in gleams:
		if gleam.alpha > 0:
			var color = Color(1.0, 1.0, 1.0, gleam.alpha)
			_draw_pixel_circle(gleam.pos, 8, color)

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
