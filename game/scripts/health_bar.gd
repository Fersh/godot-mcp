extends Node2D

@export var bar_width: float = 40.0
@export var bar_height: float = 6.0
@export var offset_y: float = -25.0

var max_health: float = 100.0
var current_health: float = 100.0
var shield_amount: float = 0.0
var shield_max: float = 0.0

@onready var background: Panel = $Background
@onready var fill: Panel = $Fill

var highlight: ColorRect
var shadow: ColorRect
var shield_fill: Panel

func _ready() -> void:
	position.y = offset_y
	background.size = Vector2(bar_width, bar_height)
	background.position = Vector2(-bar_width / 2, -bar_height / 2)
	fill.size = Vector2(bar_width, bar_height)
	fill.position = Vector2(-bar_width / 2, -bar_height / 2)

	# Set background to black (missing health portion)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)  # Dark/black background
	background.add_theme_stylebox_override("panel", bg_style)

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

	# Create shield fill (drawn on top of health)
	shield_fill = Panel.new()
	shield_fill.size = Vector2(0, bar_height)
	shield_fill.position = Vector2(-bar_width / 2, -bar_height / 2)
	shield_fill.z_index = 1
	var shield_style = StyleBoxFlat.new()
	shield_style.bg_color = Color(0.4, 0.6, 1.0, 0.9)  # Blue for shield
	# Add border on left, top, bottom (not right) with darker blue
	shield_style.border_width_left = 2
	shield_style.border_width_top = 2
	shield_style.border_width_bottom = 2
	shield_style.border_width_right = 0
	shield_style.border_color = Color(0.2, 0.35, 0.7, 1.0)  # Darker blue border
	shield_style.corner_radius_top_left = 2
	shield_style.corner_radius_bottom_left = 2
	shield_fill.add_theme_stylebox_override("panel", shield_style)
	shield_fill.visible = false
	add_child(shield_fill)

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

	# Change color based on health (or blue if shielded)
	var style = fill.get_theme_stylebox("panel").duplicate()
	if shield_amount > 0:
		style.bg_color = Color(0.3, 0.5, 0.9, 1)  # Blue when shielded
	elif ratio > 0.5:
		style.bg_color = Color(0.2, 0.8, 0.2, 1)  # Green
	elif ratio > 0.25:
		style.bg_color = Color(0.9, 0.7, 0.1, 1)  # Yellow
	else:
		style.bg_color = Color(0.9, 0.2, 0.2, 1)  # Red
	fill.add_theme_stylebox_override("panel", style)

	# Update shield display
	_update_shield_display()

func set_shield(current_shield: float, max_shield: float) -> void:
	shield_amount = current_shield
	shield_max = max_shield
	_update_shield_display()

	# Also update health bar color
	set_health(current_health, max_health)

func _update_shield_display() -> void:
	if shield_fill == null:
		return

	if shield_amount > 0 and shield_max > 0:
		shield_fill.visible = true
		var shield_ratio = clamp(shield_amount / shield_max, 0.0, 1.0)
		shield_fill.size.x = bar_width * shield_ratio
	else:
		shield_fill.visible = false

func show_heal_text(amount: float) -> void:
	"""Show +HP text above the health bar."""
	var label = Label.new()
	label.text = "+" + str(int(amount))
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))  # Green
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)

	# Load pixel font if available
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
		label.add_theme_font_override("font", pixel_font)

	# Position above health bar
	label.position = Vector2(-bar_width / 2, -20)
	label.size = Vector2(bar_width, 20)
	add_child(label)

	# Animate floating up and fading
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - 15, 0.8)
	tween.tween_property(label, "modulate:a", 0.0, 0.6).set_delay(0.3)
	tween.chain().tween_callback(label.queue_free)
