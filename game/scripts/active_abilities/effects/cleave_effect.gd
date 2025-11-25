extends Node2D

# Cleave visual effect - a sweeping arc

var arc_radius: float = 80.0
var arc_angle: float = PI * 0.75  # 135 degrees
var direction: Vector2 = Vector2.RIGHT
var color: Color = Color(1.0, 0.9, 0.7, 0.9)
var duration: float = 0.2

func _ready() -> void:
	queue_redraw()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.parallel().tween_property(self, "scale", Vector2(1.2, 1.2), duration)
	tween.tween_callback(queue_free)

func _draw() -> void:
	var start_angle = direction.angle() - arc_angle / 2
	var end_angle = direction.angle() + arc_angle / 2

	# Draw multiple arcs for thickness effect
	for i in range(3):
		var r = arc_radius - i * 10
		var c = color
		c.a *= 1.0 - i * 0.25
		draw_arc(Vector2.ZERO, r, start_angle, end_angle, 24, c, 6.0 - i * 1.5)

	# Draw slash lines
	for i in range(5):
		var angle = start_angle + (end_angle - start_angle) * (i / 4.0)
		var inner = Vector2.from_angle(angle) * 20
		var outer = Vector2.from_angle(angle) * arc_radius
		draw_line(inner, outer, color, 2.0)
