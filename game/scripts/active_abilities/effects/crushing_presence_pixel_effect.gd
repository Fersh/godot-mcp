extends Node2D

# Crushing Presence - T3 Roar overwhelming dominance aura

var pixel_size := 4
var duration := 1.1
var elapsed := 0.0

# Dominance aura layers
var inner_aura := 0.0
var mid_aura := 0.0
var outer_aura := 0.0

# Pressure waves
var pressure_waves := []
var num_waves := 5

# Crushed enemies indicator
var crush_marks := []
var num_marks := 6

# Ground tremor
var tremor_cracks := []
var num_cracks := 10

# Crown of dominance
var crown_alpha := 0.0

func _ready() -> void:
	# Initialize pressure waves
	for i in range(num_waves):
		pressure_waves.append({
			"radius": 0.0,
			"alpha": 0.0,
			"delay": i * 0.15
		})

	# Initialize crush marks
	for i in range(num_marks):
		var angle = (i * TAU / num_marks)
		var dist = randf_range(60, 90)
		crush_marks.append({
			"pos": Vector2(cos(angle), sin(angle)) * dist,
			"alpha": 0.0,
			"trigger_time": 0.3 + randf() * 0.3
		})

	# Initialize tremor cracks
	for i in range(num_cracks):
		var angle = randf() * TAU
		tremor_cracks.append({
			"angle": angle,
			"length": 0.0,
			"max_length": randf_range(40, 80)
		})

	# Heavy screen shake
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("shake"):
		camera.shake(15, 0.5)

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Aura layers build up
	inner_aura = ease(min(progress * 3, 1.0), 0.3) * (1.0 - progress * 0.2)
	mid_aura = ease(min(progress * 2, 1.0), 0.3) * (1.0 - progress * 0.25)
	outer_aura = ease(min(progress * 1.5, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Crown appears
	if progress > 0.2:
		crown_alpha = min((progress - 0.2) / 0.3, 1.0) * (1.0 - max(0, progress - 0.7) / 0.3)

	# Update pressure waves
	for wave in pressure_waves:
		if elapsed > wave.delay:
			var wave_age = elapsed - wave.delay
			wave.radius = wave_age * 100
			wave.alpha = max(0, 0.7 - wave_age)

	# Update crush marks
	for mark in crush_marks:
		if elapsed > mark.trigger_time:
			var age = elapsed - mark.trigger_time
			if age < 0.15:
				mark.alpha = age / 0.15
			else:
				mark.alpha = max(0, 1.0 - (age - 0.15) / 0.4)

	# Update tremor cracks
	for crack in tremor_cracks:
		crack.length = ease(min(progress * 2, 1.0), 0.3) * crack.max_length

	queue_redraw()

func _draw() -> void:
	# Draw tremor cracks
	for crack in tremor_cracks:
		if crack.length > 5:
			var color = Color(0.3, 0.2, 0.15, 0.6)
			var end = Vector2(cos(crack.angle), sin(crack.angle)) * crack.length
			_draw_pixel_line(Vector2.ZERO, end, color)

	# Draw outer aura
	if outer_aura > 0:
		var color = Color(0.5, 0.3, 0.2, outer_aura * 0.3)
		_draw_pixel_circle(Vector2.ZERO, 80, color)

	# Draw mid aura
	if mid_aura > 0:
		var color = Color(0.7, 0.4, 0.2, mid_aura * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 55, color)

	# Draw inner aura
	if inner_aura > 0:
		var color = Color(0.9, 0.6, 0.3, inner_aura * 0.5)
		_draw_pixel_circle(Vector2.ZERO, 30, color)

	# Draw pressure waves
	for wave in pressure_waves:
		if wave.alpha > 0:
			var color = Color(0.8, 0.5, 0.2, wave.alpha * 0.4)
			_draw_pixel_ring(Vector2.ZERO, wave.radius, color, 8)

	# Draw crush marks
	for mark in crush_marks:
		if mark.alpha > 0:
			_draw_crush_mark(mark.pos, mark.alpha)

	# Draw crown
	if crown_alpha > 0:
		_draw_crown(Vector2(0, -50), crown_alpha)

func _draw_crush_mark(center: Vector2, alpha: float) -> void:
	# Downward arrow indicating crushing force
	var color = Color(0.8, 0.4, 0.2, alpha)
	# Arrow body
	_draw_pixel_line(center + Vector2(0, -15), center + Vector2(0, 10), color)
	# Arrow head
	_draw_pixel_line(center + Vector2(-8, 2), center + Vector2(0, 10), color)
	_draw_pixel_line(center + Vector2(8, 2), center + Vector2(0, 10), color)

func _draw_crown(center: Vector2, alpha: float) -> void:
	var color = Color(1.0, 0.8, 0.3, alpha)
	var gem_color = Color(1.0, 0.3, 0.2, alpha)

	# Crown base
	for x in range(-15, 16):
		var pos = center + Vector2(x, 5)
		pos = (pos / pixel_size).floor() * pixel_size
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Crown points
	var points = [-12, -6, 0, 6, 12]
	for px in points:
		for y in range(-8, 6):
			var height_factor = 1.0 - abs(y + 1) / 8.0
			if randf() < height_factor or y > 2:
				var pos = center + Vector2(px, y)
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Center gem
	_draw_pixel_circle(center + Vector2(0, 0), 4, gem_color)

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
