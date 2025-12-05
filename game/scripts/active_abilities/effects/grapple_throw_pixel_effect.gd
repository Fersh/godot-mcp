extends Node2D

# Grapple Throw - T2 Throw that pulls enemy

var pixel_size := 4
var duration := 0.6
var elapsed := 0.0

# Grapple chain
var chain_extended := false
var chain_length := 0.0
var max_chain := 80.0
var chain_retracting := false

# Hook at end
var hook_pos := Vector2.ZERO

# Chain links
var chain_links := []
var num_links := 10

# Impact effect
var impact_alpha := 0.0

# Pull particles
var pull_particles := []
var num_particles := 8

func _ready() -> void:
	# Initialize chain links
	for i in range(num_links):
		chain_links.append({
			"offset": Vector2(randf_range(-2, 2), randf_range(-2, 2))
		})

	# Initialize pull particles
	for i in range(num_particles):
		pull_particles.append({
			"pos": Vector2(max_chain, 0),
			"alpha": 0.0
		})

	await get_tree().create_timer(duration + 0.1).timeout
	queue_free()

func _process(delta: float) -> void:
	elapsed += delta
	var progress = elapsed / duration

	# Chain extends then retracts
	if progress < 0.35:
		# Extending
		chain_length = (progress / 0.35) * max_chain
		chain_extended = false
	elif progress < 0.45:
		# Hit - impact
		chain_length = max_chain
		chain_extended = true
		impact_alpha = 1.0 - (progress - 0.35) / 0.1
		# Trigger pull particles
		for p in pull_particles:
			if p.alpha == 0:
				p.alpha = 0.7
	else:
		# Retracting (pulling target)
		chain_retracting = true
		chain_length = max_chain * (1.0 - (progress - 0.45) / 0.55)
		impact_alpha = 0

	hook_pos = Vector2(chain_length, 0)

	# Update pull particles (move toward origin)
	for p in pull_particles:
		if p.alpha > 0:
			p.pos = p.pos.lerp(Vector2.ZERO, delta * 3)
			p.alpha = max(0, p.alpha - delta * 1.5)

	queue_redraw()

func _draw() -> void:
	# Draw pull particles
	for p in pull_particles:
		if p.alpha > 0:
			var color = Color(0.8, 0.6, 0.4, p.alpha)
			var pos = (p.pos / pixel_size).floor() * pixel_size
			draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

	# Draw chain
	if chain_length > 5:
		var link_spacing = chain_length / num_links
		for i in range(num_links):
			var t = float(i) / num_links
			var base_pos = Vector2(t * chain_length, 0)
			var link = chain_links[i]
			var wobble = sin(elapsed * 10 + i) * 2 if chain_retracting else 0
			var pos = base_pos + link.offset + Vector2(0, wobble)

			var link_color = Color(0.5, 0.45, 0.4, 0.9)
			pos = (pos / pixel_size).floor() * pixel_size
			# Draw link (small rectangle)
			draw_rect(Rect2(pos, Vector2(pixel_size * 2, pixel_size)), link_color)

	# Draw hook
	if chain_length > 0:
		_draw_hook(hook_pos)

	# Draw impact effect
	if impact_alpha > 0:
		var impact_color = Color(1.0, 0.8, 0.4, impact_alpha)
		_draw_pixel_circle(hook_pos, 15, impact_color)

	# Draw origin point (hand)
	var hand_color = Color(0.6, 0.5, 0.4, 0.8)
	_draw_pixel_circle(Vector2.ZERO, 6, hand_color)

func _draw_hook(pos: Vector2) -> void:
	var hook_color = Color(0.6, 0.55, 0.5, 1.0)
	# Hook head
	var snapped = (pos / pixel_size).floor() * pixel_size
	draw_rect(Rect2(snapped, Vector2(pixel_size * 2, pixel_size * 2)), hook_color)
	# Hook curve (simple L shape)
	draw_rect(Rect2(snapped + Vector2(pixel_size * 2, 0), Vector2(pixel_size, pixel_size)), hook_color)
	draw_rect(Rect2(snapped + Vector2(pixel_size * 2, pixel_size), Vector2(pixel_size, pixel_size)), hook_color)
	draw_rect(Rect2(snapped + Vector2(pixel_size * 2, pixel_size * 2), Vector2(pixel_size, pixel_size)), hook_color)
	# Point
	var point_color = Color(0.75, 0.7, 0.65, 1.0)
	draw_rect(Rect2(snapped + Vector2(pixel_size * 3, pixel_size * 2), Vector2(pixel_size, pixel_size)), point_color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = center + pos
				draw_pos = (draw_pos / pixel_size).floor() * pixel_size
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)
