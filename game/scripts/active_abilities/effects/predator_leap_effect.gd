extends Node2D

# Predator Savage Leap (T2B) - Beast claw marks and speed aura
# Feral claw slashes, speed trails, and predator energy

var radius: float = 100.0
var duration: float = 0.45
var pixel_size: int = 4

var _time: float = 0.0
var _claw_marks: Array[Dictionary] = []
var _speed_lines: Array[Dictionary] = []
var _feral_particles: Array[Dictionary] = []

# Predator/beast colors
const CLAW_COLOR = Color(0.9, 0.3, 0.2, 1.0)  # Red-orange claws
const SPEED_COLOR = Color(1.0, 0.85, 0.3, 1.0)  # Golden speed
const FERAL_COLOR = Color(0.8, 0.5, 0.2, 1.0)  # Orange feral energy
const BLOOD_COLOR = Color(0.7, 0.15, 0.1, 1.0)  # Dark red accents

func _ready() -> void:
	_generate_claw_marks()
	_generate_speed_lines()
	_generate_particles()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.45) -> void:
	radius = p_radius
	duration = p_duration

func _generate_claw_marks() -> void:
	# Generate 3 claw slash marks
	var base_angle = randf() * TAU
	for i in range(3):
		var angle = base_angle + (i - 1) * 0.4
		var length = radius * randf_range(0.5, 0.8)
		var curve = randf_range(-0.3, 0.3)
		_claw_marks.append({
			"angle": angle,
			"length": length,
			"curve": curve,
			"width": 3 - abs(i - 1),  # Middle claw is thickest
			"delay": i * 0.05
		})

func _generate_speed_lines() -> void:
	# Generate speed/motion lines
	var line_count = randi_range(10, 16)
	for i in range(line_count):
		var angle = randf() * TAU
		var length = randf_range(40.0, 80.0)
		var dist = randf_range(radius * 0.3, radius * 0.8)
		_speed_lines.append({
			"angle": angle,
			"length": length,
			"dist": dist,
			"delay": randf_range(0.0, 0.15)
		})

func _generate_particles() -> void:
	# Generate feral energy particles
	var particle_count = randi_range(15, 25)
	for i in range(particle_count):
		var angle = randf() * TAU
		var speed = randf_range(80.0, 160.0)
		var size = randi_range(2, 4)
		_feral_particles.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"spiral": randf_range(2.0, 4.0),
			"delay": randf_range(0.0, 0.1)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw speed aura ring
	_draw_speed_aura()

	# Draw speed lines
	_draw_speed_lines()

	# Draw claw marks
	_draw_claw_marks()

	# Draw feral particles
	_draw_particles()

	# Draw predator eye flash
	_draw_predator_flash()

func _draw_speed_aura() -> void:
	var aura_alpha = (1.0 - _time) * 0.4
	if aura_alpha <= 0:
		return

	var color = SPEED_COLOR
	color.a = aura_alpha

	# Pulsing speed aura
	var pulse = sin(_time * 15.0) * 0.2 + 0.8
	var aura_radius = radius * 0.6 * pulse

	var segments = int(aura_radius * 0.6)
	segments = max(segments, 12)

	for i in range(segments):
		var angle = (TAU / segments) * i
		var pos = Vector2.from_angle(angle) * aura_radius
		# Directional streaking
		var streak = Vector2.from_angle(angle) * 10.0 * _time
		_draw_pixel_rect(pos + streak, pixel_size * 2, color)

func _draw_speed_lines() -> void:
	for line in _speed_lines:
		var line_time = clamp((_time - line.delay) * 3.0, 0.0, 1.0)
		if line_time <= 0:
			continue

		var alpha = (1.0 - line_time) * 0.7
		var color = SPEED_COLOR
		color.a = alpha

		var start_pos = Vector2.from_angle(line.angle) * line.dist
		var end_pos = start_pos + Vector2.from_angle(line.angle) * line.length * line_time
		_draw_pixel_line(start_pos, end_pos, pixel_size, color)

func _draw_claw_marks() -> void:
	for claw in _claw_marks:
		var claw_time = clamp((_time - claw.delay) * 4.0, 0.0, 1.0)
		if claw_time <= 0:
			continue

		var alpha = (1.0 - _time * 0.6) * 1.0
		var color = CLAW_COLOR
		color.a = alpha

		# Draw curved claw slash
		var steps = int(claw.length / (pixel_size * 2))
		for s in range(int(steps * claw_time)):
			var t = float(s) / max(steps - 1, 1)
			var dist = claw.length * t
			# Add curve
			var curve_offset = sin(t * PI) * claw.curve * 20.0
			var base_pos = Vector2.from_angle(claw.angle) * dist
			var perp = Vector2.from_angle(claw.angle + PI * 0.5) * curve_offset
			var pos = base_pos + perp

			var claw_width = claw.width * pixel_size
			# Taper the claw
			claw_width = int(claw_width * (1.0 - t * 0.5))
			claw_width = max(claw_width, pixel_size)

			_draw_pixel_rect(pos, claw_width, color)

			# Blood splatter at claw tips
			if t > 0.7 and randf() > 0.6:
				var blood_color = BLOOD_COLOR
				blood_color.a = alpha * 0.8
				var splatter_offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
				_draw_pixel_rect(pos + splatter_offset, pixel_size, blood_color)

func _draw_particles() -> void:
	for particle in _feral_particles:
		var particle_time = clamp((_time - particle.delay) * 2.0, 0.0, 1.0)
		if particle_time <= 0:
			continue

		# Spiral outward motion
		var spiral_angle = particle.angle + particle_time * particle.spiral
		var pos = Vector2.from_angle(spiral_angle) * particle.speed * particle_time

		var alpha = (1.0 - particle_time) * 0.8
		var color = FERAL_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_predator_flash() -> void:
	# Central predator eye/energy flash
	var flash_alpha = (1.0 - _time * 3.0) * 1.0
	if flash_alpha <= 0:
		return

	var color = SPEED_COLOR
	color.a = flash_alpha

	# Diamond/eye shape
	var flash_size = 25.0 * (1.0 + _time * 0.5)
	var points = [
		Vector2(0, -flash_size),
		Vector2(flash_size * 0.5, 0),
		Vector2(0, flash_size),
		Vector2(-flash_size * 0.5, 0)
	]

	for i in range(4):
		_draw_pixel_line(points[i], points[(i + 1) % 4], pixel_size * 2, color)

	# Inner glow
	var inner_color = CLAW_COLOR
	inner_color.a = flash_alpha * 0.7
	_draw_pixel_rect(Vector2.ZERO, pixel_size * 3, inner_color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var pos = from.lerp(to, t)
		_draw_pixel_rect(pos, width, color)
