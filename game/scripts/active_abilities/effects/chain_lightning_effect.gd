extends Node2D

# Chain lightning hit effect

var color: Color = Color(0.6, 0.8, 1.0, 0.9)
var duration: float = 0.2

func _ready() -> void:
	queue_redraw()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Central spark
	draw_circle(Vector2.ZERO, 10, Color(1.0, 1.0, 1.0, 0.9))
	draw_circle(Vector2.ZERO, 15, color)

	# Lightning bolts radiating out
	for i in range(6):
		var angle = TAU * i / 6.0
		_draw_lightning_bolt(Vector2.ZERO, Vector2.from_angle(angle) * 40, color)

func _draw_lightning_bolt(start: Vector2, end: Vector2, col: Color) -> void:
	var points: Array[Vector2] = [start]
	var segments = 4
	var direction = (end - start) / segments

	for i in range(1, segments):
		var point = start + direction * i
		# Add some randomness for jagged effect
		point += Vector2(randf_range(-8, 8), randf_range(-8, 8))
		points.append(point)

	points.append(end)

	# Draw the bolt
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], col, 2.0)
		# Glow
		draw_line(points[i], points[i + 1], Color(col.r, col.g, col.b, col.a * 0.3), 5.0)
