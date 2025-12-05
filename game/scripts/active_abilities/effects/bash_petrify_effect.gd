extends Node2D

# Lockdown Shield Bash of Petrification - T3 Signature
# Stone/petrification effect with grey coloring and stone cracks

var radius: float = 80.0
var duration: float = 0.7
var pixel_size: int = 4

var _time: float = 0.0
var _stone_cracks: Array[Dictionary] = []
var _stone_particles: Array[Dictionary] = []
var _petrify_wave: Array[Dictionary] = []

# Stone/petrification colors
const STONE_DARK = Color(0.35, 0.35, 0.38, 1.0)  # Dark stone grey
const STONE_MID = Color(0.5, 0.5, 0.53, 1.0)  # Medium stone
const STONE_LIGHT = Color(0.65, 0.65, 0.68, 1.0)  # Light stone highlight
const CRACK_COLOR = Color(0.2, 0.2, 0.22, 1.0)  # Dark crack
const MAGIC_COLOR = Color(0.6, 0.55, 0.7, 1.0)  # Subtle purple magic
const DUST_COLOR = Color(0.55, 0.55, 0.5, 0.6)  # Stone dust

func _ready() -> void:
	_generate_stone_cracks()
	_generate_stone_particles()
	_generate_petrify_wave()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_radius: float, p_duration: float = 0.7) -> void:
	radius = p_radius
	duration = p_duration

func _generate_stone_cracks() -> void:
	# Stone texture cracks spreading from center
	var crack_count = randi_range(8, 14)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.25, 0.25)
		var length = radius * randf_range(0.5, 1.0)
		var segments: Array[Vector2] = []

		var current_pos = Vector2.ZERO
		var segment_length = 10.0
		var current_angle = angle

		while current_pos.length() < length:
			current_angle += randf_range(-0.35, 0.35)
			current_pos += Vector2.from_angle(current_angle) * segment_length
			segments.append(current_pos)

			# Branch cracks
			if randf() > 0.7 and segments.size() > 2:
				var branch_angle = current_angle + randf_range(-0.8, 0.8)
				var branch_pos = current_pos + Vector2.from_angle(branch_angle) * segment_length * 0.6
				segments.append(branch_pos)
				segments.append(current_pos)  # Return to main crack

		_stone_cracks.append({
			"segments": segments,
			"delay": randf_range(0.0, 0.15)
		})

func _generate_stone_particles() -> void:
	# Stone chips/dust particles
	var particle_count = randi_range(20, 35)
	for i in range(particle_count):
		var angle = randf() * TAU
		var dist = randf_range(10.0, radius * 0.8)
		_stone_particles.append({
			"start_pos": Vector2.from_angle(angle) * dist * 0.3,
			"end_pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(2, 5),
			"height": randf_range(15.0, 40.0),
			"delay": randf_range(0.0, 0.12),
			"is_dust": randf() > 0.6
		})

func _generate_petrify_wave() -> void:
	# Concentric petrification rings
	var ring_count = 5
	for i in range(ring_count):
		_petrify_wave.append({
			"radius_mult": 0.2 + (float(i) / ring_count) * 0.8,
			"delay": i * 0.05,
			"thickness": randi_range(2, 4)
		})

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	# Draw petrification spreading wave
	_draw_petrify_wave()

	# Draw stone surface
	_draw_stone_surface()

	# Draw cracks
	_draw_stone_cracks()

	# Draw stone particles
	_draw_stone_particles()

	# Draw central stone formation
	_draw_stone_center()

	# Draw magic aura
	_draw_magic_aura()

func _draw_petrify_wave() -> void:
	for wave in _petrify_wave:
		var wave_progress = clamp((_time - wave.delay) * 2.5, 0.0, 1.0)
		if wave_progress <= 0:
			continue

		var wave_radius = radius * wave.radius_mult * wave_progress
		var wave_alpha = (1.0 - wave_progress) * 0.6

		if wave_alpha <= 0:
			continue

		var color = STONE_MID
		color.a = wave_alpha

		var segments = int(wave_radius * 0.5)
		segments = max(segments, 12)

		for i in range(segments):
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * wave_radius
			_draw_pixel_rect(pos, pixel_size * wave.thickness, color)

func _draw_stone_surface() -> void:
	# Textured stone surface spreading outward
	var surface_progress = clamp(_time * 2.0, 0.0, 1.0)
	var surface_radius = radius * 0.7 * surface_progress
	var surface_alpha = (1.0 - _time * 0.6) * 0.7

	if surface_alpha <= 0 or surface_radius <= 0:
		return

	# Draw pixelated stone texture
	var grid_step = pixel_size * 3
	for x in range(-int(surface_radius / grid_step), int(surface_radius / grid_step) + 1):
		for y in range(-int(surface_radius / grid_step), int(surface_radius / grid_step) + 1):
			var pos = Vector2(x, y) * grid_step
			if pos.length() < surface_radius:
				var dist_factor = pos.length() / surface_radius

				# Varied stone coloring
				var noise_val = sin(pos.x * 0.3 + pos.y * 0.2) * 0.5 + 0.5
				var color = STONE_DARK.lerp(STONE_LIGHT, noise_val * 0.5)
				color.a = surface_alpha * (1.0 - dist_factor * 0.5)

				_draw_pixel_rect(pos, pixel_size * 2, color)

func _draw_stone_cracks() -> void:
	for crack in _stone_cracks:
		var crack_progress = clamp((_time - crack.delay) * 2.5, 0.0, 1.0)
		if crack_progress <= 0:
			continue

		var segments: Array = crack.segments
		var visible_count = int(segments.size() * crack_progress)

		var prev_pos = Vector2.ZERO
		for j in range(visible_count):
			var seg_pos: Vector2 = segments[j]

			var alpha = (1.0 - _time * 0.4) * 0.95
			var color = CRACK_COLOR
			color.a = alpha

			_draw_pixel_line(prev_pos, seg_pos, pixel_size, color)
			prev_pos = seg_pos

func _draw_stone_particles() -> void:
	for particle in _stone_particles:
		var particle_progress = clamp((_time - particle.delay) * 2.5, 0.0, 1.0)
		if particle_progress <= 0:
			continue

		var start_pos: Vector2 = particle.start_pos
		var end_pos: Vector2 = particle.end_pos
		var pos = start_pos.lerp(end_pos, particle_progress)

		# Arc upward
		var height = sin(particle_progress * PI) * particle.height
		pos.y -= height

		var alpha = (1.0 - particle_progress * 0.6) * 0.9

		var color: Color
		if particle.is_dust:
			color = DUST_COLOR
		else:
			color = STONE_MID
		color.a = alpha

		_draw_pixel_rect(pos, particle.size * pixel_size, color)

func _draw_stone_center() -> void:
	var center_alpha = (1.0 - _time * 0.8) * 0.9
	if center_alpha <= 0:
		return

	# Central stone formation (like target turning to stone)
	var stone_size = 50.0 * (0.8 + _time * 0.4)

	# Stone body silhouette
	for x in range(-int(stone_size / pixel_size), int(stone_size / pixel_size) + 1):
		for y in range(-int(stone_size / pixel_size), int(stone_size / pixel_size) + 1):
			var pos = Vector2(x, y) * pixel_size
			var dist = pos.length()

			# Roughly humanoid shape (taller than wide)
			var shape_width = stone_size * 0.6 * (1.0 - abs(pos.y) / stone_size * 0.3)
			if abs(pos.x) < shape_width and dist < stone_size:
				var dist_factor = dist / stone_size

				# Stone coloring with highlights
				var highlight = 0.0
				if pos.x < 0 and pos.y < 0:  # Upper left highlight
					highlight = 0.2
				var color = STONE_MID.lightened(highlight)
				color.a = center_alpha * (1.0 - dist_factor * 0.3)

				_draw_pixel_rect(pos, pixel_size, color)

	# Stone texture lines on the figure
	var texture_color = CRACK_COLOR
	texture_color.a = center_alpha * 0.5

	for i in range(5):
		var y_pos = -stone_size * 0.5 + (stone_size / 5) * i
		var line_width = stone_size * 0.4 * (1.0 - abs(y_pos) / stone_size * 0.3)
		_draw_pixel_line(
			Vector2(-line_width, y_pos),
			Vector2(line_width, y_pos),
			pixel_size,
			texture_color
		)

func _draw_magic_aura() -> void:
	# Subtle magic glow around petrification
	var aura_alpha = sin(_time * PI) * 0.4
	if aura_alpha <= 0:
		return

	var color = MAGIC_COLOR
	color.a = aura_alpha

	var aura_radius = radius * (0.5 + _time * 0.3)

	# Sparse magic particles
	var particle_count = 12
	for i in range(particle_count):
		var base_angle = (TAU / particle_count) * i
		var angle = base_angle + sin(_time * 4.0 + i) * 0.3
		var dist = aura_radius * (0.7 + sin(_time * 3.0 + i * 0.5) * 0.3)
		var pos = Vector2.from_angle(angle) * dist

		_draw_pixel_rect(pos, pixel_size * 2, color)

	# Inner glow ring
	var inner_color = MAGIC_COLOR
	inner_color.a = aura_alpha * 0.5
	var inner_radius = 40.0

	var segments = 16
	for i in range(segments):
		if (i + int(_time * 8)) % 3 == 0:  # Sparse/animated
			var angle = (TAU / segments) * i
			var pos = Vector2.from_angle(angle) * inner_radius
			_draw_pixel_rect(pos, pixel_size, inner_color)

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
