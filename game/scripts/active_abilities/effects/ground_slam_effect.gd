extends Node2D

# Ground slam shockwave effect

var radius: float = 100.0
var duration: float = 0.4

var wave_count: int = 3

func _ready() -> void:
	queue_redraw()

	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var progress = 1.0 - modulate.a

	# Draw expanding shockwave rings
	for i in range(wave_count):
		var wave_progress = clamp(progress - i * 0.15, 0.0, 1.0)
		var wave_radius = radius * wave_progress
		var alpha = (1.0 - wave_progress) * 0.8

		draw_arc(Vector2.ZERO, wave_radius, 0, TAU, 32, Color(0.8, 0.6, 0.3, alpha), 4.0 - i)

	# Ground crack lines
	for i in range(8):
		var angle = TAU * i / 8.0
		var crack_length = radius * 0.9 * progress
		var end_pos = Vector2.from_angle(angle) * crack_length
		draw_line(Vector2.ZERO, end_pos, Color(0.6, 0.4, 0.2, 0.6 * (1.0 - progress)), 2.0)

	# Dust particles
	for i in range(12):
		var angle = TAU * i / 12.0
		var dist = radius * 0.5 * progress
		var pos = Vector2.from_angle(angle) * dist + Vector2(0, -progress * 20)
		var size = 5.0 * (1.0 - progress)
		draw_circle(pos, size, Color(0.7, 0.6, 0.4, 0.5 * (1.0 - progress)))
