extends Node2D

# Tremor Savage Leap (T2A) - Seismic shockwave rings effect
# Expanding concentric earthquake rings with ground rupture

var radius: float = 150.0
var duration: float = 0.5
var pixel_size: int = 4

var _time: float = 0.0
var _ring_offsets: Array[float] = []
var _rupture_lines: Array[Dictionary] = []
var _shockwave_particles: Array[Dictionary] = []

# Seismic/earthquake colors
const RING_COLOR_INNER = Color(0.9, 0.75, 0.4, 1.0)  # Golden shockwave
const RING_COLOR_OUTER = Color(0.6, 0.5, 0.35, 1.0)  # Brown outer
const RUPTURE_COLOR = Color(0.25, 0.2, 0.15, 1.0)  # Dark ground cracks
const ENERGY_COLOR = Color(1.0, 0.9, 0.5, 1.0)  # Bright energy

func _ready() -> void:
	_generate_rings()
	_generate_ruptures()
	_generate_particles()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.5) -> void:
	radius = p_radius
	duration = p_duration

func _generate_rings() -> void:
	# Generate 3 expanding rings with staggered timing
	_ring_offsets = [0.0, 0.15, 0.3]

func _generate_ruptures() -> void:
	# Generate ground rupture lines radiating outward
	var rupture_count = randi_range(8, 12)
	for i in range(rupture_count):
		var angle = (TAU / rupture_count) * i + randf_range(-0.2, 0.2)
		var length = radius * randf_range(0.6, 1.0)
		var width = randi_range(2, 4)
		_rupture_lines.append({
			"angle": angle,
			"length": length,
			"width": width,
			"wave_offset": randf() * TAU
		})

func _generate_particles() -> void:
	# Generate shockwave debris particles
	var particle_count = randi_range(15, 25)
	for i in range(particle_count):
		var angle = randf() * TAU
		var speed = randf_range(80.0, 180.0)
		var size = randi_range(2, 4)
		_shockwave_particles.append({
			"angle": angle,
			"speed": speed,
			"size": size,
			"delay": randf_range(0.0, 0.2),
			"arc_height": randf_range(30.0, 60.0)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw expanding shockwave rings
	_draw_rings()

	# Draw ground rupture lines
	_draw_ruptures()

	# Draw shockwave particles
	_draw_particles()

	# Draw central stun burst
	_draw_stun_burst()

func _draw_rings() -> void:
	for i in range(_ring_offsets.size()):
		var offset = _ring_offsets[i]
		var ring_time = clamp((_time - offset) * 2.0, 0.0, 1.0)
		if ring_time <= 0:
			continue

		var ring_radius = radius * ring_time
		var ring_alpha = (1.0 - ring_time) * (0.8 - i * 0.15)

		# Interpolate color from inner to outer
		var color = RING_COLOR_INNER.lerp(RING_COLOR_OUTER, ring_time)
		color.a = ring_alpha

		# Draw pixelated ring with varying thickness
		var thickness = (3 - i) * pixel_size
		var segments = int(ring_radius * 0.8)
		segments = max(segments, 16)

		for j in range(segments):
			var angle = (TAU / segments) * j
			var pos = Vector2.from_angle(angle) * ring_radius
			# Add slight wave distortion
			var wave = sin(angle * 8.0 + _time * 10.0) * 3.0
			pos += Vector2.from_angle(angle) * wave
			_draw_pixel_rect(pos, thickness, color)

func _draw_ruptures() -> void:
	for rupture in _rupture_lines:
		var rupture_progress = clamp(_time * 3.0, 0.0, 1.0)
		if rupture_progress <= 0:
			continue

		var alpha = (1.0 - _time * 0.8) * 0.9
		var color = RUPTURE_COLOR
		color.a = alpha

		# Draw jagged rupture line
		var current_pos = Vector2.ZERO
		var end_dist = rupture.length * rupture_progress
		var step_size = pixel_size * 2
		var steps = int(end_dist / step_size)

		for s in range(steps):
			var dist = s * step_size
			var wave = sin(dist * 0.1 + rupture.wave_offset) * 5.0
			var pos = Vector2.from_angle(rupture.angle) * dist
			pos += Vector2.from_angle(rupture.angle + PI * 0.5) * wave
			_draw_pixel_rect(pos, rupture.width * pixel_size, color)

func _draw_particles() -> void:
	for particle in _shockwave_particles:
		var particle_time = clamp((_time - particle.delay) * 1.5, 0.0, 1.0)
		if particle_time <= 0:
			continue

		var pos = Vector2.from_angle(particle.angle) * particle.speed * particle_time
		# Arc trajectory
		var arc = sin(particle_time * PI) * particle.arc_height
		pos.y -= arc

		var alpha = (1.0 - particle_time) * 0.8
		var color = RING_COLOR_INNER
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_stun_burst() -> void:
	# Central stun indicator - bright flash
	var burst_alpha = (1.0 - _time * 2.5) * 1.0
	if burst_alpha <= 0:
		return

	var color = ENERGY_COLOR
	color.a = burst_alpha

	# Starburst pattern
	var burst_size = 40.0 * (1.0 + _time * 0.5)
	var points = 8
	for i in range(points):
		var angle = (TAU / points) * i + _time * 2.0
		var length = burst_size * (0.6 + sin(angle * 3.0) * 0.4)
		var end_pos = Vector2.from_angle(angle) * length
		_draw_pixel_line(Vector2.ZERO, end_pos, pixel_size, color)

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
