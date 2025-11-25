extends Node2D

var lifetime: float = 0.08
var timer: float = 0.0
var flash_size: float = 20.0

func _ready() -> void:
	flash_size = randf_range(15, 25)

func _process(delta: float) -> void:
	timer += delta
	if timer >= lifetime:
		queue_free()
	queue_redraw()

func _draw() -> void:
	var alpha = 1.0 - (timer / lifetime)
	var size = flash_size * (1.0 + timer / lifetime * 0.5)

	# Core flash
	draw_circle(Vector2.ZERO, size * 0.3, Color(1.0, 1.0, 0.9, alpha))
	# Outer glow
	draw_circle(Vector2.ZERO, size * 0.6, Color(1.0, 0.8, 0.3, alpha * 0.6))
	# Outer ring
	draw_circle(Vector2.ZERO, size, Color(1.0, 0.5, 0.1, alpha * 0.3))
