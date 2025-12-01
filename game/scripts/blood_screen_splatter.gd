extends CanvasLayer

# Blood splatter effect on camera/screen
# Spawns blood droplets that drip down leaving trails

class BloodDrop:
	var position: Vector2
	var size: float
	var alpha: float
	var lifetime: float
	var max_lifetime: float
	var drip_speed: float
	var trail_points: Array = []  # Trail of positions as it drips

class BloodRemnant:
	var position: Vector2
	var size: float
	var alpha: float
	var lifetime: float

var blood_drops: Array = []
var blood_remnants: Array = []  # Static remnants left behind
var control: Control

func _ready() -> void:
	layer = 100  # Render on top of everything

	control = Control.new()
	control.set_anchors_preset(Control.PRESET_FULL_RECT)
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(control)

	control.draw.connect(_on_draw)

func spawn_splatter(intensity: int = 5) -> void:
	"""Spawn blood splatter drops on the screen."""
	var viewport_size = get_viewport().get_visible_rect().size

	for i in range(intensity):
		var drop = BloodDrop.new()
		# Random position, biased toward edges for more dramatic effect
		var edge_bias = randf()
		if edge_bias < 0.3:
			# Top edge
			drop.position = Vector2(randf() * viewport_size.x, randf_range(0, viewport_size.y * 0.3))
		elif edge_bias < 0.5:
			# Left edge
			drop.position = Vector2(randf_range(0, viewport_size.x * 0.3), randf() * viewport_size.y)
		elif edge_bias < 0.7:
			# Right edge
			drop.position = Vector2(randf_range(viewport_size.x * 0.7, viewport_size.x), randf() * viewport_size.y)
		else:
			# Random anywhere
			drop.position = Vector2(randf() * viewport_size.x, randf() * viewport_size.y)

		drop.size = randf_range(6, 16)  # Larger drops
		drop.alpha = randf_range(0.7, 0.95)  # More visible
		drop.max_lifetime = randf_range(12.0, 22.0)  # Match ground blood duration
		drop.lifetime = drop.max_lifetime
		drop.drip_speed = randf_range(8, 20)  # Drip speed

		blood_drops.append(drop)

func _process(delta: float) -> void:
	var needs_redraw = false

	if not blood_drops.is_empty():
		needs_redraw = true
		for drop in blood_drops:
			drop.lifetime -= delta

			# Store previous position for trail
			var prev_pos = drop.position

			# Slowly drip down
			drop.position.y += drop.drip_speed * delta

			# Leave remnant trail every few pixels
			if drop.position.y - prev_pos.y > 2.0:
				var remnant = BloodRemnant.new()
				remnant.position = prev_pos
				remnant.size = drop.size * randf_range(0.3, 0.6)
				remnant.alpha = drop.alpha * 0.6
				remnant.lifetime = randf_range(10.0, 18.0)
				blood_remnants.append(remnant)

			# Fade out gradually
			var life_ratio = drop.lifetime / drop.max_lifetime
			drop.alpha = life_ratio * 0.9

		# Remove dead drops
		blood_drops = blood_drops.filter(func(d): return d.lifetime > 0)

	# Update remnants
	if not blood_remnants.is_empty():
		needs_redraw = true
		for remnant in blood_remnants:
			remnant.lifetime -= delta
			if remnant.lifetime < 2.0:
				remnant.alpha = (remnant.lifetime / 2.0) * 0.6

		blood_remnants = blood_remnants.filter(func(r): return r.lifetime > 0)

	if needs_redraw:
		control.queue_redraw()

func _on_draw() -> void:
	# Draw remnant trails first (underneath)
	for remnant in blood_remnants:
		if remnant.lifetime <= 0:
			continue
		var pixel_pos = Vector2(round(remnant.position.x), round(remnant.position.y))
		var color = Color(0.5, 0.02, 0.02, remnant.alpha)
		var s = remnant.size
		control.draw_rect(Rect2(pixel_pos - Vector2(s/2, s/2), Vector2(s, s)), color)

	# Draw active drops on top
	for drop in blood_drops:
		if drop.lifetime <= 0:
			continue

		var pixel_pos = Vector2(round(drop.position.x), round(drop.position.y))

		# Main drop (larger, more pronounced)
		var color = Color(0.65, 0.02, 0.02, drop.alpha)
		var base_size = drop.size

		# Draw irregular blood splat shape (multiple overlapping rects)
		control.draw_rect(Rect2(pixel_pos - Vector2(base_size/2, base_size/3), Vector2(base_size, base_size * 0.7)), color)
		control.draw_rect(Rect2(pixel_pos - Vector2(base_size/3, base_size/2), Vector2(base_size * 0.8, base_size)), color)
		control.draw_rect(Rect2(pixel_pos - Vector2(base_size/4, base_size/4), Vector2(base_size * 0.6, base_size * 0.5)), color)

		# Darker center core
		var dark_color = Color(0.4, 0.01, 0.01, drop.alpha * 0.9)
		var inner_size = drop.size * 0.5
		control.draw_rect(Rect2(pixel_pos - Vector2(inner_size/2, inner_size/2), Vector2(inner_size, inner_size)), dark_color)

		# Drip trail below the main drop
		var trail_color = Color(0.55, 0.02, 0.02, drop.alpha * 0.7)
		var drip_length = drop.drip_speed * 0.4
		for j in range(3):
			var offset_y = drop.size * 0.5 + drip_length * (j + 1) * 0.25
			var trail_size = drop.size * (0.5 - j * 0.12)
			if trail_size > 1:
				control.draw_rect(Rect2(pixel_pos + Vector2(-trail_size/2, offset_y), Vector2(trail_size, trail_size)), trail_color)
