extends Node2D

# Crucify - T3 Impale pin to cross formation

var pixel_size := 4
var duration := 1.1
var elapsed := 0.0

# Cross formation
var cross_alpha := 0.0
var cross_size := 80.0

# Pinning spikes
var spikes := []
var num_spikes := 5

# Dark energy
var dark_energy := []
var num_dark := 20

# Doom aura
var doom_aura := 0.0

# Trapped victim silhouette
var victim_alpha := 0.0

func _ready() -> void:
	# Initialize pinning spikes
	var spike_positions = [
		Vector2(0, -30),  # Head
		Vector2(-35, 0),  # Left arm
		Vector2(35, 0),   # Right arm
		Vector2(-10, 35), # Left leg
		Vector2(10, 35)   # Right leg
	]
	for i in range(num_spikes):
		spikes.append({
			"target": spike_positions[i],
			"pos": spike_positions[i].normalized() * 100,
			"alpha": 0.0,
			"trigger_time": 0.2 + i * 0.1,
			"hit": false
		})

	# Initialize dark energy particles
	for i in range(num_dark):
		var angle = randf() * TAU
		dark_energy.append({
			"angle": angle,
			"radius": randf_range(50, 80),
			"speed": randf_range(2, 4),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.2).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Cross appears
	cross_alpha = ease(min(progress * 3, 1.0), 0.3) * (1.0 - progress * 0.3)

	# Doom aura builds
	doom_aura = ease(min(progress * 2, 1.0), 0.5) * (1.0 - progress * 0.2)

	# Update spikes
	for spike in spikes:
		if elapsed > spike.trigger_time:
			if not spike.hit:
				var dist = spike.pos.distance_to(spike.target)
				if dist > 5:
					spike.pos = spike.pos.move_toward(spike.target, delta * 400)
					spike.alpha = 1.0
				else:
					spike.hit = true
					spike.pos = spike.target
			else:
				spike.alpha = 1.0 - progress * 0.3

	# Victim appears after spikes hit
	var all_hit = true
	for spike in spikes:
		if not spike.hit:
			all_hit = false
			break
	if all_hit:
		victim_alpha = min(victim_alpha + delta * 3, 1.0) * (1.0 - (progress - 0.6))

	# Update dark energy
	for p in dark_energy:
		p.angle += p.speed * delta
		p.alpha = doom_aura * 0.6

	queue_redraw()

func _draw() -> void:
	# Draw doom aura
	if doom_aura > 0:
		var aura_color = Color(0.2, 0.1, 0.25, doom_aura * 0.4)
		_draw_pixel_circle(Vector2.ZERO, 70, aura_color)

	# Draw dark energy
	for p in dark_energy:
		if p.alpha > 0:
			var pos = Vector2(cos(p.angle), sin(p.angle)) * p.radius
			var color = Color(0.3, 0.1, 0.35, p.alpha)
			_draw_pixel_circle(pos, 6, color)

	# Draw cross
	if cross_alpha > 0:
		var cross_color = Color(0.3, 0.2, 0.25, cross_alpha)
		# Vertical beam
		_draw_thick_line(Vector2(0, -cross_size * 0.6), Vector2(0, cross_size * 0.6), cross_color, 12)
		# Horizontal beam
		_draw_thick_line(Vector2(-cross_size * 0.5, -10), Vector2(cross_size * 0.5, -10), cross_color, 12)

	# Draw victim silhouette
	if victim_alpha > 0:
		_draw_crucified_victim(Vector2.ZERO, victim_alpha)

	# Draw spikes
	for spike in spikes:
		if spike.alpha > 0:
			var color = Color(0.5, 0.4, 0.45, spike.alpha)
			_draw_spike(spike.pos, spike.target, color)

func _draw_crucified_victim(center: Vector2, alpha: float) -> void:
	var color = Color(0.5, 0.4, 0.45, alpha)

	# Head
	_draw_pixel_circle(center + Vector2(0, -30), 10, color)

	# Torso
	for y in range(-15, 25):
		var width = 8 if y < 10 else 6
		for x in range(-width, width + 1, pixel_size):
			var pos = center + Vector2(x, y)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Arms stretched
	for arm_x in [-1, 1]:
		for x in range(5, 35):
			var pos = center + Vector2(x * arm_x, 0)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Legs
	for leg_x in [-10, 10]:
		for y in range(25, 40):
			var pos = center + Vector2(leg_x, y)
			pos = (pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_spike(from: Vector2, to: Vector2, color: Color) -> void:
	var dir = (to - from).normalized()
	var length = from.distance_to(to)

	# Spike body
	_draw_pixel_line(from, to, color)

	# Spike head (wider at tip)
	var tip_color = Color(0.7, 0.5, 0.55, color.a)
	_draw_pixel_circle(to, 6, tip_color)

func _draw_thick_line(from: Vector2, to: Vector2, color: Color, thickness: float) -> void:
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI/2)

	for t in range(-int(thickness/2/pixel_size), int(thickness/2/pixel_size) + 1):
		var offset = perp * t * pixel_size
		_draw_pixel_line(from + offset, to + offset, color)

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
