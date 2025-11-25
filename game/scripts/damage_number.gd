extends Node2D

@export var rise_speed: float = 50.0
@export var fade_duration: float = 0.8
@export var spread: float = 20.0

var velocity: Vector2 = Vector2.ZERO
var time: float = 0.0

@onready var label: Label = $Label

func _ready() -> void:
	# Random horizontal spread
	velocity = Vector2(randf_range(-spread, spread), -rise_speed)

	# Set initial scale for pop effect
	scale = Vector2(0.5, 0.5)

	# Animate scale up
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _process(delta: float) -> void:
	time += delta

	# Rise up and slow down
	position += velocity * delta
	velocity.y += 50.0 * delta  # Gravity effect

	# Fade out
	var alpha = 1.0 - (time / fade_duration)
	modulate.a = max(0, alpha)

	if time >= fade_duration:
		queue_free()

func set_damage(amount: float, is_critical: bool = false, is_player_damage: bool = false) -> void:
	label.text = str(int(amount))

	if is_player_damage:
		# Player taking damage - red
		label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1))
		label.add_theme_font_size_override("font_size", 32)
	elif is_critical:
		# Critical hit - bigger gold/yellow
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
		label.add_theme_font_size_override("font_size", 42)
		scale = Vector2(1.2, 1.2)
	else:
		# Normal enemy hit - white
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
		label.add_theme_font_size_override("font_size", 26)
