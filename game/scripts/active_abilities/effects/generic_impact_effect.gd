extends Node2D
class_name GenericImpactEffect

# A generic circular impact effect that can be customized
# Used as fallback for abilities without specific effects

@export var color: Color = Color(1.0, 0.8, 0.3, 0.8)
@export var radius: float = 50.0
@export var duration: float = 0.3
@export var expand: bool = true

var elapsed: float = 0.0

func _ready() -> void:
	queue_redraw()

	# Auto-destroy after duration
	var tween = create_tween()
	if expand:
		tween.tween_property(self, "scale", Vector2(1.5, 1.5), duration)
	tween.parallel().tween_property(self, "modulate:a", 0.0, duration)
	tween.tween_callback(queue_free)

func _draw() -> void:
	# Draw expanding ring
	draw_arc(Vector2.ZERO, radius, 0, TAU, 32, color, 4.0)

	# Draw inner glow
	var inner_color = color
	inner_color.a *= 0.3
	draw_circle(Vector2.ZERO, radius * 0.5, inner_color)

func setup(p_radius: float, p_color: Color, p_duration: float = 0.3) -> void:
	radius = p_radius
	color = p_color
	duration = p_duration
