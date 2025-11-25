extends Node2D

# Frost Nova - expanding ring of ice

var radius: float = 100.0
var color: Color = Color(0.5, 0.8, 1.0, 0.8)
var duration: float = 0.4

var particles: Array = []

func _ready() -> void:
	# Create ice particle positions
	for i in range(12):
		var angle = TAU * i / 12.0
		particles.append({
			"angle": angle,
			"dist": randf_range(0.3, 0.8),
			"size": randf_range(5, 15)
		})

	queue_redraw()

	# Animate expansion
	scale = Vector2(0.3, 0.3)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), duration * 0.6).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration).set_ease(Tween.EASE_IN)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Outer ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, 4.0)

	# Inner glow
	var inner_color = color
	inner_color.a *= 0.2
	draw_circle(Vector2.ZERO, radius * 0.7, inner_color)

	# Ice crystal particles
	for p in particles:
		var pos = Vector2.from_angle(p.angle) * radius * p.dist
		_draw_ice_crystal(pos, p.size)

func _draw_ice_crystal(pos: Vector2, size: float) -> void:
	# Simple diamond shape
	var points = [
		pos + Vector2(0, -size),
		pos + Vector2(size * 0.5, 0),
		pos + Vector2(0, size),
		pos + Vector2(-size * 0.5, 0)
	]
	draw_colored_polygon(points, Color(0.8, 0.95, 1.0, 0.9))
