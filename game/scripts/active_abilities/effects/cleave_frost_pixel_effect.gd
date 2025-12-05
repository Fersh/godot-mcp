extends Node2D

# Cleave Frost - T2 Cleave with ice/frost effects

var pixel_size := 4
var duration := 0.55
var elapsed := 0.0

# Main arc slash
var arc_progress := 0.0
var arc_width := 90.0
var arc_angle_span := PI * 0.75

# Ice shards
var ice_shards := []
var num_shards := 12

# Frost particles
var frost_particles := []
var num_frost := 16

# Freeze mist
var mist_particles := []
var num_mist := 8

func _ready() -> void:
	# Initialize ice shards
	for i in range(num_shards):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		ice_shards.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(35, 55),
			"velocity": Vector2(cos(angle), sin(angle)) * randf_range(100, 180),
			"size": Vector2(randi_range(2, 4) * pixel_size, randi_range(1, 2) * pixel_size),
			"alpha": 1.0,
			"rotation": randf() * TAU
		})

	# Initialize frost particles
	for i in range(num_frost):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		frost_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(20, 70),
			"velocity": Vector2(cos(angle + randf_range(-0.3, 0.3)), sin(angle + randf_range(-0.3, 0.3))) * randf_range(30, 80),
			"alpha": 0.8,
			"size": randf_range(4, 10)
		})

	# Initialize mist
	for i in range(num_mist):
		var angle = randf_range(-arc_angle_span/2, arc_angle_span/2) - PI/2
		mist_particles.append({
			"pos": Vector2(cos(angle), sin(angle)) * randf_range(30, 60),
			"alpha": 0.5,
			"size": randf_range(15, 30)
		})

	await get_tree().create_timer(duration + 0.15).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Arc sweeps
	arc_progress = ease(min(progress * 2.2, 1.0), 0.25)

	# Update ice shards
	for shard in ice_shards:
		shard.velocity *= 0.94
		shard.pos += shard.velocity * delta
		shard.alpha = max(0, 1.0 - progress * 1.1)
		shard.rotation += delta * 3.0

	# Update frost particles
	for frost in frost_particles:
		frost.velocity *= 0.92
		frost.pos += frost.velocity * delta
		frost.alpha = max(0, 0.8 - progress)

	# Update mist (expand and fade)
	for mist in mist_particles:
		mist.size += delta * 20
		mist.alpha = max(0, 0.5 - progress * 0.6)

	queue_redraw()

func _draw() -> void:
	# Draw mist (light blue, transparent)
	for mist in mist_particles:
		if mist.alpha > 0:
			var color = Color(0.7, 0.9, 1.0, mist.alpha * 0.4)
			_draw_pixel_circle(mist.pos, mist.size, color)

	# Draw main arc (cyan/white)
	if arc_progress > 0:
		var steps = int(arc_angle_span * arc_progress * 18)
		for i in range(steps):
			var t = float(i) / max(steps, 1)
			var angle = -arc_angle_span/2 - PI/2 + t * arc_angle_span * arc_progress
			var fade = 1.0 - (float(i) / steps) * 0.4

			# Outer edge (cyan)
			var outer_color = Color(0.4, 0.8, 1.0, fade * 0.7)
			for r in range(3):
				var radius = arc_width - r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), outer_color)

			# Core (white/light blue)
			var core_color = Color(0.9, 0.95, 1.0, fade)
			for r in range(2):
				var radius = 40 + r * pixel_size
				var pos = Vector2(cos(angle), sin(angle)) * radius
				pos = (pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), core_color)

	# Draw ice shards (light blue/white)
	for shard in ice_shards:
		if shard.alpha > 0:
			var color = Color(0.8, 0.95, 1.0, shard.alpha)
			var pos = (shard.pos / pixel_size).floor() * pixel_size
			# Draw as rotated rectangle (simplified)
			draw_rect(Rect2(pos - shard.size/2, shard.size), color)

	# Draw frost particles (sparkles)
	for frost in frost_particles:
		if frost.alpha > 0:
			var color = Color(1.0, 1.0, 1.0, frost.alpha)
			var pos = (frost.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)
			# Cross pattern for sparkle
			if frost.size > 6:
				var dim_color = Color(0.7, 0.9, 1.0, frost.alpha * 0.6)
				draw_rect(Rect2(pos + Vector2(pixel_size, 0), Vector2(pixel_size, pixel_size)), dim_color)
				draw_rect(Rect2(pos + Vector2(-pixel_size, 0), Vector2(pixel_size, pixel_size)), dim_color)
				draw_rect(Rect2(pos + Vector2(0, pixel_size), Vector2(pixel_size, pixel_size)), dim_color)
				draw_rect(Rect2(pos + Vector2(0, -pixel_size), Vector2(pixel_size, pixel_size)), dim_color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 4)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
