extends Node2D

# Ground Slam - Procedural pixelated shockwave effect
# Shows actual ability radius with fantasy RPG pixel aesthetic

var radius: float = 100.0
var duration: float = 0.65  # Increased duration for better visibility
var pixel_size: int = 4  # Size of each "pixel" for retro look

var _time: float = 0.0
var _cracks: Array[Dictionary] = []
var _debris: Array[Dictionary] = []
var _dust_particles: Array[Dictionary] = []

# Colors for earth/stone theme - brighter and more saturated
const CRACK_COLOR = Color(0.15, 0.1, 0.05, 1.0)  # Dark brown/black cracks
const IMPACT_COLOR = Color(0.55, 0.45, 0.3, 1.0)  # Brighter brown impact
const DUST_COLOR = Color(0.75, 0.65, 0.5, 0.85)  # Brighter tan dust
const RING_COLOR = Color(0.9, 0.75, 0.4, 0.9)  # Golden/orange shockwave ring
const FLASH_COLOR = Color(1.0, 0.95, 0.8, 1.0)  # Bright flash at impact

func _ready() -> void:
	_generate_cracks()
	_generate_debris()
	_generate_dust()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.4) -> void:
	radius = p_radius
	duration = p_duration

func _generate_cracks() -> void:
	# Generate radial cracks from center
	var crack_count = randi_range(8, 12)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.2, 0.2)
		var length = radius * randf_range(0.6, 1.0)
		var segments: Array[Vector2] = []

		var current_pos = Vector2.ZERO
		var segment_length = 12.0
		var current_angle = angle

		while current_pos.length() < length:
			current_angle += randf_range(-0.3, 0.3)
			current_pos += Vector2.from_angle(current_angle) * segment_length
			segments.append(current_pos)

		_cracks.append({
			"segments": segments,
			"delay": randf_range(0.0, 0.15)
		})

func _generate_debris() -> void:
	# Generate pixelated rock debris - more pieces for bigger impact
	var debris_count = randi_range(18, 28)
	for i in range(debris_count):
		var angle = randf() * TAU
		var dist = randf_range(25.0, radius * 0.9)
		var size = randi_range(2, 5)
		_debris.append({
			"start_pos": Vector2.from_angle(angle) * dist * 0.2,
			"end_pos": Vector2.from_angle(angle) * dist,
			"size": size,
			"height_offset": randf_range(30.0, 70.0),  # Higher arc
			"delay": randf_range(0.0, 0.12)
		})

func _generate_dust() -> void:
	# Generate dust cloud particles - more and larger
	var dust_count = randi_range(30, 45)
	for i in range(dust_count):
		var angle = randf() * TAU
		var dist = randf_range(radius * 0.2, radius * 1.2)
		_dust_particles.append({
			"pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(4, 10),  # Larger dust clouds
			"alpha_offset": randf_range(0.0, 0.25)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw expanding shockwave rings (pixelated)
	_draw_shockwave_rings()

	# Draw cracks
	_draw_cracks()

	# Draw debris flying up
	_draw_debris()

	# Draw dust cloud
	_draw_dust()

	# Draw central impact
	_draw_impact_center()

func _draw_shockwave_rings() -> void:
	# Draw multiple expanding rings for more impact
	for ring_index in range(3):
		var ring_delay = ring_index * 0.08
		var ring_time = clamp((_time - ring_delay) * 1.2, 0.0, 1.0)
		if ring_time <= 0:
			continue

		var ring_radius = radius * ring_time
		var ring_alpha = (1.0 - ring_time) * (0.9 - ring_index * 0.2)

		if ring_alpha <= 0:
			continue

		# Draw pixelated ring
		var color = RING_COLOR
		color.a = ring_alpha

		# Draw ring as series of rectangles around circumference
		var ring_thickness = pixel_size * (3 - ring_index)  # Outer rings thinner
		var segments = int(ring_radius * 0.6)
		segments = max(segments, 20)
		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * ring_radius
			_draw_pixel_rect(pos, ring_thickness, color)

func _draw_cracks() -> void:
	for crack in _cracks:
		var crack_progress = clamp((_time - crack.delay) * 3.0, 0.0, 1.0)
		if crack_progress <= 0:
			continue

		var segments: Array = crack.segments
		var visible_count = int(segments.size() * crack_progress)

		var prev_pos = Vector2.ZERO
		for j in range(visible_count):
			var seg_pos: Vector2 = segments[j]
			# Draw pixelated line segment
			_draw_pixel_line(prev_pos, seg_pos, pixel_size, CRACK_COLOR)
			prev_pos = seg_pos

func _draw_debris() -> void:
	for debris in _debris:
		var debris_progress = clamp((_time - debris.delay) * 1.8, 0.0, 1.0)  # Slower animation
		if debris_progress <= 0:
			continue

		var start_pos: Vector2 = debris.start_pos
		var end_pos: Vector2 = debris.end_pos
		var pos = start_pos.lerp(end_pos, debris_progress)

		# Arc trajectory (up then down)
		var height = sin(debris_progress * PI) * debris.height_offset
		pos.y -= height

		var alpha = 1.0 - debris_progress * 0.3  # Fade slower
		var color = IMPACT_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, debris.size * pixel_size, color)

func _draw_dust() -> void:
	var dust_alpha = (1.0 - _time * 0.7) * 0.9  # Fade slower, higher opacity
	if dust_alpha <= 0:
		return

	for dust in _dust_particles:
		var expand = 1.0 + _time * 0.4  # Expand more
		var pos: Vector2 = dust.pos * expand
		pos.y -= _time * 25.0  # Float upward a bit faster

		var color = DUST_COLOR
		color.a = dust_alpha * (1.0 - dust.alpha_offset)

		_draw_pixel_rect(pos, dust.size, color)

func _draw_impact_center() -> void:
	# Draw bright flash at the very start
	var flash_alpha = (1.0 - _time * 4.0) * 1.0
	if flash_alpha > 0:
		var flash_color = FLASH_COLOR
		flash_color.a = flash_alpha
		var flash_size = 50.0 * (1.0 + _time * 2.0)
		for x in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
			for y in range(-int(flash_size / pixel_size), int(flash_size / pixel_size) + 1):
				var pos = Vector2(x, y) * pixel_size
				if pos.length() < flash_size * 0.6:
					var dist_factor = pos.length() / (flash_size * 0.6)
					var pixel_color = flash_color
					pixel_color.a *= (1.0 - dist_factor)
					_draw_pixel_rect(pos, pixel_size, pixel_color)

	# Draw impact crater that persists longer
	var impact_alpha = (1.0 - _time * 0.7) * 0.95
	if impact_alpha <= 0:
		return

	var color = IMPACT_COLOR
	color.a = impact_alpha

	# Draw pixelated impact crater - larger and more visible
	var crater_size = 40.0 * (1.0 + _time * 0.4)
	for x in range(-int(crater_size / pixel_size), int(crater_size / pixel_size) + 1):
		for y in range(-int(crater_size / pixel_size), int(crater_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() < crater_size * 0.75:
				var dist_factor = pos.length() / (crater_size * 0.75)
				var pixel_color = color
				pixel_color.a *= (1.0 - dist_factor * 0.4)
				_draw_pixel_rect(pos, pixel_size, pixel_color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	# Snap to pixel grid for crisp retro look
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, width: int, color: Color) -> void:
	# Draw a pixelated line
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var pos = from.lerp(to, t)
		_draw_pixel_rect(pos, width, color)
