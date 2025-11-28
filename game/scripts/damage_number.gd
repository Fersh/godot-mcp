extends Node2D

@export var rise_speed: float = 50.0
@export var fade_duration: float = 0.8
@export var spread: float = 20.0

var velocity: Vector2 = Vector2.ZERO
var time: float = 0.0

@onready var label: Label = $Label

var pixel_font: Font

# Static tracking for position spreading
static var spawn_index: int = 0
static var recent_positions: Array[Vector2] = []
static var position_cleanup_time: float = 0.0

const SPREAD_RADIUS: float = 45.0  # How far to spread from center
const MIN_DISTANCE: float = 35.0   # Minimum distance between numbers
const POSITION_MEMORY: int = 8     # How many recent positions to remember

func _ready() -> void:
	# Load pixel font
	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if pixel_font and label:
		label.add_theme_font_override("font", pixel_font)

	# Calculate spread position using rotating pattern
	var angle = (spawn_index * 137.5) * PI / 180.0  # Golden angle for even distribution
	var radius = SPREAD_RADIUS * (0.5 + 0.5 * (spawn_index % 3) / 2.0)  # Vary radius
	spawn_index = (spawn_index + 1) % 360

	# Apply position offset
	var offset = Vector2(cos(angle) * radius, sin(angle) * radius * 0.5)  # Squash vertically
	global_position += offset

	# Push away from recent positions
	_avoid_recent_positions()

	# Track this position
	recent_positions.append(global_position)
	if recent_positions.size() > POSITION_MEMORY:
		recent_positions.pop_front()

	# Velocity goes outward from center + upward
	var outward_dir = Vector2(cos(angle), -0.5).normalized()
	velocity = outward_dir * rise_speed * randf_range(0.8, 1.2)
	velocity.y = min(velocity.y, -rise_speed * 0.5)  # Ensure it goes up

	# Set initial scale for pop effect
	scale = Vector2(0.5, 0.5)

	# Animate scale up
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.1)

func _avoid_recent_positions() -> void:
	# Push away from any nearby recent damage numbers
	for recent_pos in recent_positions:
		var dist = global_position.distance_to(recent_pos)
		if dist < MIN_DISTANCE and dist > 0:
			var push_dir = (global_position - recent_pos).normalized()
			global_position += push_dir * (MIN_DISTANCE - dist)

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
	if is_player_damage:
		# Player taking damage - red with shake animation
		label.text = str(int(amount))
		label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1))
		label.add_theme_font_size_override("font_size", 32)
		# Add outline for visibility
		label.add_theme_color_override("font_outline_color", Color(0.3, 0, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		# Shake animation for player damage (#22)
		_animate_shake()
	elif is_critical:
		# ENHANCED Critical hit - gold with "CRIT!" prefix (#7)
		label.text = "CRIT! " + str(int(amount))
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
		label.add_theme_font_size_override("font_size", 30)
		# Strong outline for crits
		label.add_theme_color_override("font_outline_color", Color(0.6, 0.3, 0, 1))
		label.add_theme_constant_override("outline_size", 4)
		scale = Vector2(0.5, 0.5)  # Start small for pop
		# Epic crit animation
		_animate_crit()
		# Register with JuiceManager for crit streaks
		if JuiceManager:
			JuiceManager.register_crit()
	else:
		# Normal enemy hit - white with subtle bounce (#22)
		label.text = str(int(amount))
		label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
		label.add_theme_font_size_override("font_size", 26)
		label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("outline_size", 3)
		# Subtle bounce animation
		_animate_bounce()

func set_heal(amount: float) -> void:
	label.text = "+" + str(int(amount))
	# Healing - green
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.3, 1))
	label.add_theme_font_size_override("font_size", 28)

func set_blocked(amount: float) -> void:
	label.text = str(int(amount)) + " BLOCKED"
	# Blocked - light blue/steel color
	label.add_theme_color_override("font_color", Color(0.5, 0.7, 1.0, 1))
	label.add_theme_font_size_override("font_size", 26)

func set_dodge() -> void:
	label.text = "DODGE!"
	# Dodge - cyan/teal color
	label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.9, 1))
	label.add_theme_font_size_override("font_size", 28)
	scale = Vector2(1.1, 1.1)

func set_shield() -> void:
	label.text = "BLOCKED"
	# Blocked by shield - cyan/blue color
	label.add_theme_color_override("font_color", Color(0.3, 0.7, 1.0, 1))
	label.add_theme_font_size_override("font_size", 18)
	scale = Vector2(0.9, 0.9)

func set_shield_gain(amount: float) -> void:
	label.text = "+" + str(int(amount))
	# Shield gain - blue color matching shield bar
	label.add_theme_color_override("font_color", Color(0.4, 0.6, 1.0, 1))
	label.add_theme_font_size_override("font_size", 24)
	scale = Vector2(0.9, 0.9)

func set_elemental(text: String, color: Color) -> void:
	label.text = text
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 14)
	scale = Vector2(0.7, 0.7)

# ============================================
# ENHANCED ANIMATIONS (#22)
# ============================================

func _animate_bounce() -> void:
	"""Subtle bounce animation for normal damage numbers."""
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.1, 0.9), 0.05)
	tween.tween_property(self, "scale", Vector2(0.95, 1.05), 0.05)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.05)

func _animate_crit() -> void:
	"""Crit animation - starts small, pops, slight rotation."""
	var tween = create_tween()
	tween.set_parallel(true)
	# Scale pop - start small, overshoot, settle
	tween.tween_property(self, "scale", Vector2(1.2, 1.2), 0.1).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.chain().tween_property(self, "scale", Vector2(1.0, 1.0), 0.08)
	# Slight rotation wobble
	var rot_tween = create_tween()
	rot_tween.tween_property(self, "rotation", 0.08, 0.04)
	rot_tween.tween_property(self, "rotation", -0.08, 0.08)
	rot_tween.tween_property(self, "rotation", 0.0, 0.08)
	# Brief color flash (white flash then back to gold)
	var color_tween = create_tween()
	label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
	color_tween.tween_callback(func():
		label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.1, 1))
	).set_delay(0.06)

func _animate_shake() -> void:
	"""Shake animation for player damage numbers."""
	var tween = create_tween()
	var original_pos = position
	tween.tween_property(self, "position", original_pos + Vector2(4, 0), 0.03)
	tween.tween_property(self, "position", original_pos + Vector2(-4, 0), 0.03)
	tween.tween_property(self, "position", original_pos + Vector2(2, 0), 0.03)
	tween.tween_property(self, "position", original_pos, 0.03)

func set_kill_streak(streak: int, tier_name: String, color: Color) -> void:
	"""Special display for kill streak milestones."""
	label.text = tier_name + " x" + str(streak)
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 32)
	label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	label.add_theme_constant_override("outline_size", 5)
	scale = Vector2(0.5, 0.5)
	_animate_crit()
	# Longer fade for milestones
	fade_duration = 1.5
