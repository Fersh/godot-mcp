extends Node2D

var radius: float = 80.0
var duration: float = 0.3
var timer: float = 0.0

func _ready() -> void:
	queue_redraw()

func _process(delta: float) -> void:
	timer += delta
	if timer >= duration:
		queue_free()
	else:
		queue_redraw()

func _draw() -> void:
	var progress = timer / duration
	var alpha = 1.0 - progress
	var current_radius = radius * (0.5 + progress * 0.5)

	# Orange/red explosion
	draw_circle(Vector2.ZERO, current_radius, Color(1.0, 0.5, 0.2, alpha * 0.6))
	draw_circle(Vector2.ZERO, current_radius * 0.6, Color(1.0, 0.8, 0.3, alpha * 0.8))
