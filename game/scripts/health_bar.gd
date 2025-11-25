extends Node2D

@export var bar_width: float = 40.0
@export var bar_height: float = 6.0
@export var offset_y: float = -25.0

var max_health: float = 100.0
var current_health: float = 100.0

@onready var background: Panel = $Background
@onready var fill: Panel = $Fill

var highlight: ColorRect
var shadow: ColorRect

func _ready() -> void:
	position.y = offset_y
	background.size = Vector2(bar_width, bar_height)
	background.position = Vector2(-bar_width / 2, -bar_height / 2)
	fill.size = Vector2(bar_width, bar_height)
	fill.position = Vector2(-bar_width / 2, -bar_height / 2)

	# Create highlight (top 1px)
	highlight = ColorRect.new()
	highlight.size = Vector2(bar_width, 1)
	highlight.position = Vector2(0, 0)
	highlight.color = Color(1, 1, 1, 0.3)
	fill.add_child(highlight)

	# Create shadow (bottom 1px)
	shadow = ColorRect.new()
	shadow.size = Vector2(bar_width, 1)
	shadow.position = Vector2(0, bar_height - 1)
	shadow.color = Color(0, 0, 0, 0.3)
	fill.add_child(shadow)

func set_health(current: float, maximum: float) -> void:
	max_health = maximum
	current_health = current
	var ratio = clamp(current / maximum, 0.0, 1.0)
	var fill_width = bar_width * ratio
	fill.size.x = fill_width

	# Update highlight/shadow widths
	if highlight:
		highlight.size.x = fill_width
	if shadow:
		shadow.size.x = fill_width

	# Change color based on health
	var style = fill.get_theme_stylebox("panel").duplicate()
	if ratio > 0.5:
		style.bg_color = Color(0.2, 0.8, 0.2, 1)  # Green
	elif ratio > 0.25:
		style.bg_color = Color(0.9, 0.7, 0.1, 1)  # Yellow
	else:
		style.bg_color = Color(0.9, 0.2, 0.2, 1)  # Red
	fill.add_theme_stylebox_override("panel", style)
