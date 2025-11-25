extends Node2D

# Fireball explosion effect

var radius: float = 50.0
var duration: float = 0.3

func _ready() -> void:
	queue_redraw()

	scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.5, 1.5), duration).set_ease(Tween.EASE_OUT)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Outer orange glow
	draw_circle(Vector2.ZERO, radius, Color(1.0, 0.5, 0.1, 0.4))

	# Middle yellow
	draw_circle(Vector2.ZERO, radius * 0.7, Color(1.0, 0.8, 0.2, 0.6))

	# Inner white-hot core
	draw_circle(Vector2.ZERO, radius * 0.3, Color(1.0, 1.0, 0.8, 0.9))

	# Flame tendrils
	for i in range(8):
		var angle = TAU * i / 8.0 + randf_range(-0.2, 0.2)
		var length = radius * randf_range(0.8, 1.2)
		var end_pos = Vector2.from_angle(angle) * length
		draw_line(Vector2.ZERO, end_pos, Color(1.0, 0.6, 0.1, 0.7), 3.0)
