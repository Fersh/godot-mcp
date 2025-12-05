extends Node2D

# Lockdown Shield Bash - Procedural pixelated binding/chain effect
# Shows chains wrapping around target with cold steel aesthetic

var radius: float = 60.0
var duration: float = 0.6
var pixel_size: int = 4

var _time: float = 0.0
var _chains: Array[Dictionary] = []
var _lock_particles: Array[Dictionary] = []

# Cold steel/chain colors
const CHAIN_COLOR = Color(0.5, 0.55, 0.6, 1.0)  # Steel grey
const CHAIN_HIGHLIGHT = Color(0.7, 0.75, 0.8, 1.0)  # Light steel
const LOCK_COLOR = Color(0.4, 0.45, 0.55, 1.0)  # Dark steel
const SPARK_COLOR = Color(0.8, 0.85, 0.95, 1.0)  # Cold spark
const IMPACT_COLOR = Color(0.6, 0.65, 0.75, 1.0)  # Impact flash

func _ready() -> void:
	_generate_chains()
	_generate_lock_particles()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.6) -> void:
	radius = p_radius
	duration = p_duration

func _generate_chains() -> void:
	# Generate 4-6 chains wrapping around
	var chain_count = randi_range(4, 6)
	for i in range(chain_count):
		var start_angle = (TAU / chain_count) * i + randf_range(-0.2, 0.2)
		var wrap_amount = randf_range(0.8, 1.5)  # How much the chain wraps
		var link_count = randi_range(8, 14)

		_chains.append({
			"start_angle": start_angle,
			"wrap_amount": wrap_amount,
			"link_count": link_count,
			"radius_offset": randf_range(-10.0, 10.0),
			"delay": randf_range(0.0, 0.1)
		})

func _generate_lock_particles() -> void:
	# Metal fragments/sparks
	var particle_count = randi_range(12, 20)
	for i in range(particle_count):
		var angle = randf() * TAU
		var speed = randf_range(40.0, 100.0)
		_lock_particles.append({
			"angle": angle,
			"speed": speed,
			"size": randi_range(2, 3),
			"delay": randf_range(0.0, 0.1)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw impact flash
	_draw_impact_flash()

	# Draw chains wrapping
	_draw_chains()

	# Draw lock/bind symbol at center
	_draw_lock_symbol()

	# Draw metal sparks
	_draw_lock_particles()

	# Draw binding ring
	_draw_binding_ring()

func _draw_impact_flash() -> void:
	var flash_alpha = (1.0 - _time * 4.0) * 0.7
	if flash_alpha <= 0:
		return

	var color = IMPACT_COLOR
	color.a = flash_alpha

	var flash_size = 30.0 * (1.0 + _time * 1.5)

	for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
		for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < flash_size * 0.6:
				var dist_factor = pos.length() / (flash_size * 0.6)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_chains() -> void:
	for chain in _chains:
		var chain_progress = clamp((_time - chain.delay) * 2.0, 0.0, 1.0)
		if chain_progress <= 0:
			continue

		var chain_radius = radius + chain.radius_offset
		var visible_links = int(chain.link_count * chain_progress)

		var prev_pos: Vector2 = Vector2.ZERO
		var first = true

		for link_idx in range(visible_links):
			var t = float(link_idx) / chain.link_count
			var angle = chain.start_angle + t * chain.wrap_amount * TAU

			# Spiral inward slightly
			var r = chain_radius * (1.0 - t * 0.3)
			var pos = Vector2.from_angle(angle) * r

			# Slight vertical offset for 3D feel
			pos.y += sin(t * PI * 4) * 5.0

			var alpha = (1.0 - _time * 0.5) * 0.9
			var color = CHAIN_COLOR if link_idx % 2 == 0 else CHAIN_HIGHLIGHT
			color.a = alpha

			# Draw chain link as small rectangle
			var link_size = pixel_size * 2
			_draw_pixel_rect(pos, link_size, color)

			# Draw connecting line
			if not first:
				var line_color = CHAIN_COLOR
				line_color.a = alpha * 0.7
				_draw_pixel_line(prev_pos, pos, pixel_size, line_color)

			prev_pos = pos
			first = false

func _draw_lock_symbol() -> void:
	var lock_alpha = clamp(_time * 3.0, 0.0, 1.0) * (1.0 - (_time - 0.5) * 2.0)
	lock_alpha = clamp(lock_alpha, 0.0, 1.0)
	if lock_alpha <= 0:
		return

	var color = LOCK_COLOR
	color.a = lock_alpha

	# Draw pixelated padlock shape
	var lock_width = 16.0
	var lock_height = 20.0

	# Lock body (rectangle)
	for x in range(-int(lock_width / pixel_size / 2), int(lock_width / pixel_size / 2) + 1):
		for y in range(0, int(lock_height / pixel_size / 2) + 1):
			var pos = Vector2(x * pixel_size, y * pixel_size)
			var pixel_color = color
			# Keyhole
			if abs(x) <= 1 and y >= 1 and y <= 2:
				pixel_color = pixel_color.darkened(0.4)
			_draw_pixel_rect(pos, pixel_size, pixel_color)

	# Lock shackle (arch at top)
	var shackle_color = CHAIN_HIGHLIGHT
	shackle_color.a = lock_alpha

	var arch_radius = 8.0
	for i in range(8):
		var t = float(i) / 7
		var angle = PI + t * PI  # Bottom half of circle (inverted)
		var pos = Vector2.from_angle(angle) * arch_radius
		pos.y -= 4  # Move up
		_draw_pixel_rect(pos, pixel_size, shackle_color)

func _draw_lock_particles() -> void:
	for particle in _lock_particles:
		var particle_progress = clamp((_time - particle.delay) * 3.0, 0.0, 1.0)
		if particle_progress <= 0:
			continue

		var dist = particle.speed * particle_progress
		var pos = Vector2.from_angle(particle.angle) * dist
		# Slight gravity
		pos.y += particle_progress * particle_progress * 30.0

		var alpha = (1.0 - particle_progress) * 0.8
		var color = SPARK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_binding_ring() -> void:
	# Pulsing ring that contracts
	var ring_progress = clamp(_time * 1.5, 0.0, 1.0)
	var ring_radius = radius * (1.0 - ring_progress * 0.4)  # Contract inward
	var ring_alpha = (1.0 - _time * 0.8) * 0.6

	if ring_alpha <= 0:
		return

	var color = CHAIN_COLOR
	color.a = ring_alpha

	# Draw dashed/segmented ring (like chain links)
	var segments = 24
	for i in range(segments):
		if i % 2 == 0:  # Skip every other for dashed effect
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * ring_radius
			_draw_pixel_rect(pos, pixel_size * 2, color)

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
