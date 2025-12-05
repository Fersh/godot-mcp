extends Node2D

# Thunderous Impact - T3 Stomp with lightning and thunder devastation

var pixel_size := 4
var duration := 0.85
var elapsed := 0.0

# Electric shockwaves
var shockwaves := []
var num_waves := 3

# Lightning strikes from impact
var lightning_bolts := []
var num_bolts := 10

# Thunder particles
var thunder_particles := []
var num_particles := 30

# Ground electrification
var electrify_arcs := []
var num_arcs := 6

# Central thunder burst
var burst_radius := 0.0
var max_burst := 100.0

func _ready() -> void:
	# Initialize shockwaves
	for i in range(num_waves):
		shockwaves.append({
			"radius": 0.0,
			"alpha": 1.0,
			"delay": i * 0.08
		})

	# Initialize lightning bolts (radial from center)
	for i in range(num_bolts):
		var angle = (i * TAU / num_bolts) + randf() * 0.2
		var bolt_segments = []
		var current = Vector2.ZERO
		var length = randf_range(70, 110)
		var segs = randi_range(5, 9)

		for j in range(segs):
			var seg_angle = angle + randf_range(-0.6, 0.6)
			var seg_len = length / segs
			var end = current + Vector2(cos(seg_angle), sin(seg_angle)) * seg_len
			bolt_segments.append({"start": current, "end": end})
			current = end

		lightning_bolts.append({
			"segments": bolt_segments,
			"alpha": 0.0,
			"trigger_time": randf() * 0.3,
			"flash_rate": randf_range(20, 40)
		})

	# Initialize thunder particles
	for i in range(num_particles):
		var angle = randf() * TAU
		thunder_particles.append({
			"pos": Vector2.ZERO,
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(150, 300),
			"alpha": 1.0
		})

	# Initialize electrification arcs
	for i in range(num_arcs):
		var angle = (i * TAU / num_arcs)
		electrify_arcs.append({
			"angle": angle,
			"length": 0.0,
			"pulse": randf() * TAU
		})

	# Major screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(18, 0.5)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Burst expands
	burst_radius = ease(min(progress * 2, 1.0), 0.3) * max_burst

	# Update shockwaves
	for wave in shockwaves:
		if elapsed > wave.delay:
			var wave_progress = (elapsed - wave.delay) / 0.4
			wave.radius = wave_progress * 110
			wave.alpha = max(0, 1.0 - wave_progress)

	# Update lightning
	for bolt in lightning_bolts:
		if elapsed > bolt.trigger_time:
			bolt.alpha = (0.5 + 0.5 * sin(elapsed * bolt.flash_rate)) * max(0, 1.0 - progress)

	# Update thunder particles
	for p in thunder_particles:
		p.velocity *= 0.94
		p.pos += p.velocity * delta
		p.alpha = max(0, 1.0 - progress * 1.3)

	# Update electrification arcs
	for arc in electrify_arcs:
		arc.pulse += delta * 15
		arc.length = (50 + sin(arc.pulse) * 20) * (1.0 - progress * 0.5)

	queue_redraw()

func _draw() -> void:
	# Draw shockwaves (electric blue/yellow)
	for wave in shockwaves:
		if wave.alpha > 0 and wave.radius > 5:
			var color = Color(0.4, 0.8, 1.0, wave.alpha * 0.6)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 8)
			var inner_color = Color(1.0, 1.0, 0.5, wave.alpha * 0.4)
			_draw_pixel_ring(Vector2.ZERO, wave.radius * 0.7, inner_color, 4)

	# Draw electrification arcs
	for arc in electrify_arcs:
		if arc.length > 10:
			var color = Color(0.5, 0.9, 1.0, 0.6 * (1.0 - elapsed/duration))
			var end = Vector2(cos(arc.angle), sin(arc.angle)) * arc.length
			_draw_electric_arc(Vector2.ZERO, end, color)

	# Draw lightning bolts
	for bolt in lightning_bolts:
		if bolt.alpha > 0:
			# Glow
			var glow_color = Color(0.5, 0.8, 1.0, bolt.alpha * 0.5)
			for seg in bolt.segments:
				_draw_pixel_line_thick(seg.start, seg.end, glow_color, 3)
			# Core
			var core_color = Color(1.0, 1.0, 1.0, bolt.alpha)
			for seg in bolt.segments:
				_draw_pixel_line(seg.start, seg.end, core_color)

	# Draw thunder particles
	for p in thunder_particles:
		if p.alpha > 0:
			var color = Color(0.7, 0.9, 1.0, p.alpha)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw central burst
	var burst_alpha = max(0, 1.0 - elapsed / 0.2)
	if burst_alpha > 0:
		var flash = Color(1.0, 1.0, 0.9, burst_alpha)
		_draw_pixel_circle(Vector2.ZERO, 40, flash)

func _draw_electric_arc(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var segments = int(dist / 12) + 1
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)
	var current = from

	for i in range(segments):
		var t = float(i + 1) / segments
		var target = from.lerp(to, t)
		var offset = perp * randf_range(-6, 6)
		var next = target + offset
		_draw_pixel_line(current, next, color)
		current = next

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = from.lerp(to, t)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_line_thick(from: Vector2, to: Vector2, color: Color, width: int) -> void:
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)
	for w in range(-width/2, width/2 + 1):
		var offset = perp * w * pixel_size
		_draw_pixel_line(from + offset, to + offset, color)

func _draw_pixel_ring(center: Vector2, radius: float, color: Color, thickness: float) -> void:
	var circumference = TAU * radius
	var steps = max(int(circumference / pixel_size), 16)
	for i in range(steps):
		var angle = (float(i) / steps) * TAU
		for t in range(int(thickness / pixel_size)):
			var r = radius - t * pixel_size
			if r > 0:
				var pos = center + Vector2(cos(angle), sin(angle)) * r
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
