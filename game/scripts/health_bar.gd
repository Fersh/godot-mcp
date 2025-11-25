extends Node2D

@export var bar_width: float = 40.0
@export var bar_height: float = 6.0
@export var offset_y: float = -40.0

var max_health: float = 100.0
var current_health: float = 100.0

@onready var background: ColorRect = $Background
@onready var fill: ColorRect = $Fill

func _ready() -> void:
	position.y = offset_y
	background.size = Vector2(bar_width, bar_height)
	background.position = Vector2(-bar_width / 2, -bar_height / 2)
	fill.size = Vector2(bar_width, bar_height)
	fill.position = Vector2(-bar_width / 2, -bar_height / 2)

func set_health(current: float, maximum: float) -> void:
	max_health = maximum
	current_health = current
	var ratio = clamp(current / maximum, 0.0, 1.0)
	fill.size.x = bar_width * ratio

	# Change color based on health
	if ratio > 0.5:
		fill.color = Color(0.2, 0.8, 0.2, 1)  # Green
	elif ratio > 0.25:
		fill.color = Color(0.9, 0.7, 0.1, 1)  # Yellow
	else:
		fill.color = Color(0.9, 0.2, 0.2, 1)  # Red
