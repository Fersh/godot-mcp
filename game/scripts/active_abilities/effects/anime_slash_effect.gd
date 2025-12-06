extends Node2D

# Anime Katana Slash - Classic anime-style slash effect with red/white slashes
# Shows multiple crossing slashes like a character was cut by a katana

var pixel_size := 4
var elapsed := 0.0
var duration := 0.6

# Slash lines - dramatic crossing pattern
var slashes := []
var blood_particles := []

# Flash effect
var flash_alpha := 0.0

# Colors - red/crimson for blood, white for blade flash
const SLASH_COLOR = Color(1.0, 0.2, 0.2, 1.0)  # Bright red
const SLASH_EDGE = Color(1.0, 1.0, 1.0, 1.0)   # White edge
const BLOOD_COLOR = Color(0.8, 0.05, 0.05, 1.0)
const BLOOD_DARK = Color(0.4, 0.02, 0.02, 0.9)
const FLASH_COLOR = Color(1.0, 0.9, 0.9, 1.0)

func _ready() -> void:
	# Create dramatic crossing slashes
	_create_slashes()

	# Spawn initial blood burst
	_spawn_blood_burst()

	await get_tree().create_timer(duration + 0.3).timeout
	queue_free()

func setup(num_hits: int = 3) -> void:
	# More hits = more slashes
	for i in range(num_hits - 1):
		_add_extra_slash()

func _create_slashes() -> void:
	# Main X-cross pattern
	slashes.append({
		"start": Vector2(-40, -40),
		"end": Vector2(40, 40),
		"delay": 0.0,
		"alpha": 0.0,
		"width": 6.0
	})
	slashes.append({
		"start": Vector2(40, -40),
		"end": Vector2(-40, 40),
		"delay": 0.03,
		"alpha": 0.0,
		"width": 6.0
	})
	# Horizontal slash
	slashes.append({
		"start": Vector2(-45, 0),
		"end": Vector2(45, 0),
		"delay": 0.06,
		"alpha": 0.0,
		"width": 5.0
	})

func _add_extra_slash() -> void:
	var angle = randf() * TAU
	var length = randf_range(35, 50)
	var dir = Vector2(cos(angle), sin(angle))
	slashes.append({
		"start": -dir * length,
		"end": dir * length,
		"delay": 0.02 * slashes.size(),
		"alpha": 0.0,
		"width": randf_range(4, 6)
	})

func _spawn_blood_burst() -> void:
	# Big burst of blood particles
	for i in range(25):
		var angle = randf() * TAU
		var speed = randf_range(100, 250)
		blood_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * speed,
			"alpha": 1.0,
			"size": randf_range(4, 10),
			"is_dark": randf() < 0.4
		})

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Flash at the start
	if elapsed < 0.08:
		flash_alpha = 1.0 - (elapsed / 0.08)
	else:
		flash_alpha = 0.0

	# Update slashes
	for slash in slashes:
		var slash_time = elapsed - slash.delay
		if slash_time > 0:
			if slash_time < 0.05:
				# Quick fade in
				slash.alpha = slash_time / 0.05
			elif slash_time < 0.15:
				# Hold
				slash.alpha = 1.0
			else:
				# Fade out
				slash.alpha = max(0, 1.0 - (slash_time - 0.15) / 0.3)

	# Update blood particles
	for i in range(blood_particles.size() - 1, -1, -1):
		var p = blood_particles[i]
		p.pos += p.velocity * delta
		p.velocity.y += 400 * delta  # Gravity
		p.velocity *= 0.96  # Drag
		p.alpha -= delta * 1.5
		p.size = max(p.size - delta * 4, 2)
		if p.alpha <= 0:
			blood_particles.remove_at(i)

	queue_redraw()

func _draw() -> void:
	# Draw flash
	if flash_alpha > 0:
		var flash_col = FLASH_COLOR
		flash_col.a = flash_alpha * 0.7
		_draw_pixel_circle(Vector2.ZERO, 50, flash_col)

	# Draw blood particles (behind slashes)
	for p in blood_particles:
		if p.alpha > 0:
			var color = BLOOD_DARK if p.get("is_dark", false) else BLOOD_COLOR
			color.a = p.alpha
			var pos = _snap(p.pos)
			var size = int(p.size)
			draw_rect(Rect2(pos, Vector2(size, size)), color)

	# Draw slashes
	for slash in slashes:
		if slash.alpha > 0:
			_draw_anime_slash(slash.start, slash.end, slash.alpha, slash.width)

func _draw_anime_slash(from: Vector2, to: Vector2, alpha: float, width: float) -> void:
	var dist = from.distance_to(to)
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI / 2)
	var steps = int(dist / pixel_size) + 1

	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)

		# Width tapers at ends (thickest in middle)
		var width_mult = 1.0 - pow(abs(t - 0.5) * 2, 1.5) * 0.7
		var current_width = width * width_mult

		# Draw slash with gradient from edge (white) to center (red)
		for w in range(int(-current_width), int(current_width) + 1):
			var draw_pos = pos + perp * w * pixel_size
			draw_pos = _snap(draw_pos)

			var edge_factor = abs(w) / max(current_width, 1)
			var color: Color
			if edge_factor > 0.6:
				# White edge
				color = SLASH_EDGE
				color.a = alpha * (1.0 - (edge_factor - 0.6) / 0.4)
			else:
				# Red center
				color = SLASH_COLOR
				color.a = alpha

			draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 3)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = _snap(center + pos)
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _snap(pos: Vector2) -> Vector2:
	return (pos / pixel_size).floor() * pixel_size
