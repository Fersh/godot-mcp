extends Node2D

var radius: float = 100.0
var pulse_timer: float = 0.0

func _ready() -> void:
	z_index = -1  # Draw behind player

func _process(delta: float) -> void:
	pulse_timer += delta
	queue_redraw()

func _draw() -> void:
	var pulse = sin(pulse_timer * 3.0) * 0.1 + 0.9
	var current_radius = radius * pulse

	# Multiple layers for nice effect
	draw_circle(Vector2.ZERO, current_radius, Color(0.2, 0.8, 0.2, 0.15))
	draw_circle(Vector2.ZERO, current_radius * 0.7, Color(0.3, 0.9, 0.3, 0.1))

	# Draw edge
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 32, Color(0.4, 1.0, 0.4, 0.3), 2.0)
