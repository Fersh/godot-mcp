extends CanvasLayer

# Kill Streak UI - Minimal combo display on right side
# Shows streak counter with tier name on same line

const TIER_THRESHOLDS: Array[int] = [0, 5, 10, 20, 35, 50, 75, 100, 150, 200, 250, 300, 350, 400, 450, 500]
const TIER_NAMES: Array[String] = [
	"COMBO",           # 0
	"KILLING SPREE",   # 5
	"RAMPAGE",         # 10
	"UNSTOPPABLE",     # 20
	"DOMINATING",      # 35
	"GODLIKE",         # 50
	"LEGENDARY",       # 75
	"WHOA BRO",        # 100
	"SEEK HELP",       # 150
	"GOT GUD",         # 200
	"TOUCH GRASS",     # 250
	"GET A LIFE",      # 300
	"1V1 ME BRO",      # 350
	"OVERCOMPENSATING", # 400
	"ARE YOU OK?",     # 450
	"LOL WTF!?",       # 500
]
const TIER_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0),       # White (0)
	Color(1.0, 0.9, 0.3),       # Yellow (5)
	Color(1.0, 0.6, 0.2),       # Orange (10)
	Color(1.0, 0.3, 0.2),       # Red (20)
	Color(0.9, 0.2, 0.9),       # Purple (35)
	Color(0.3, 0.8, 1.0),       # Cyan (50)
	Color(1.0, 0.85, 0.0),      # Gold (75)
	Color(1.0, 1.0, 1.0),       # Prismatic/Rainbow (100)
	Color(1.0, 0.3, 0.5),       # Rose (150)
	Color(0.4, 1.0, 0.6),       # Mint (200)
	Color(0.5, 1.0, 0.5),       # Neon Green (250)
	Color(1.0, 0.4, 0.8),       # Hot Pink (300)
	Color(0.6, 0.4, 1.0),       # Indigo (350)
	Color(0.4, 1.0, 1.0),       # Electric Cyan (400)
	Color(1.0, 0.6, 0.0),       # Blazing Orange (450)
	Color(1.0, 1.0, 1.0),       # Prismatic/Rainbow (500)
]

var pixel_font: Font = null
var container: Control = null
var combo_label: Label = null  # Single label for "x15 COMBO" or "x25 RAMPAGE"

var current_streak: int = 0
var current_tier: int = 0
var display_timer: float = 0.0
var fade_duration: float = 0.5
var is_visible_state: bool = false
var pulse_time: float = 0.0
var rainbow_time: float = 0.0

# Base rotation (slight tilt with left side down)
const BASE_ROTATION: float = 0.03  # ~1.7 degrees

func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_font()
	_create_ui()

	# Connect to KillStreakManager
	if KillStreakManager:
		KillStreakManager.streak_changed.connect(_on_streak_changed)
		KillStreakManager.streak_milestone.connect(_on_streak_milestone)
		KillStreakManager.streak_ended.connect(_on_streak_ended)

func _load_font() -> void:
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func _create_ui() -> void:
	# Main container - positioned at top right with 20px margin
	container = Control.new()
	container.name = "StreakContainer"
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.anchor_left = 0.5
	container.anchor_right = 1.0
	container.anchor_top = 0.0
	container.anchor_bottom = 0.1
	container.offset_top = 68  # 48px margin + 20px extra = 68px from top
	container.offset_right = -48  # Match the game's margin
	container.modulate.a = 0.0
	add_child(container)

	# Single combo label (e.g., "x15 COMBO" or "x25 RAMPAGE")
	combo_label = Label.new()
	combo_label.name = "ComboLabel"
	combo_label.text = "x0 COMBO"
	combo_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	combo_label.anchor_left = 0.0
	combo_label.anchor_right = 1.0
	combo_label.anchor_top = 0.0
	combo_label.anchor_bottom = 1.0
	combo_label.offset_right = -10
	combo_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	combo_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		combo_label.add_theme_font_override("font", pixel_font)
	combo_label.add_theme_font_size_override("font_size", 28)  # Larger combo font
	combo_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	# Drop shadow - darker for better visibility
	combo_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	combo_label.add_theme_constant_override("shadow_offset_x", 4)
	combo_label.add_theme_constant_override("shadow_offset_y", 4)
	# Outline for visibility
	combo_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	combo_label.add_theme_constant_override("outline_size", 3)
	# Set pivot for rotation (right side)
	combo_label.pivot_offset = Vector2(200, 15)
	# Apply base rotation (left side slightly down)
	combo_label.rotation = BASE_ROTATION
	container.add_child(combo_label)

func _process(delta: float) -> void:
	# Update visibility - gradual fade over the full display time
	if is_visible_state and display_timer > 0:
		display_timer -= delta

		# Gradual opacity fade over the 5 seconds
		# Full opacity for first 2 seconds, then fade out over remaining 3 seconds
		var fade_start_time = 2.0
		var total_display_time = 5.0
		if display_timer < (total_display_time - fade_start_time):
			var fade_progress = display_timer / (total_display_time - fade_start_time)
			container.modulate.a = fade_progress
		else:
			container.modulate.a = 1.0

		if display_timer <= 0:
			_on_fade_complete()

	# Rainbow effect for max tier (color only, no pulsing)
	if current_tier >= 6 and is_visible_state:
		rainbow_time += delta * 2.0
		var hue = fmod(rainbow_time, 1.0)
		var rainbow_color = Color.from_hsv(hue, 0.8, 1.0)
		combo_label.add_theme_color_override("font_color", rainbow_color)

func _on_streak_changed(streak: int, tier: int) -> void:
	var old_streak = current_streak
	current_streak = streak
	current_tier = tier

	if streak > 0:
		_show_ui()
		_update_display()
		display_timer = 5.0  # Match the combo timer duration

		# Rotating shake and pulse animation when streak changes
		if old_streak != streak:
			_animate_shake()
			_animate_pulse()

func _on_streak_milestone(tier: int, tier_name: String) -> void:
	# Update display with new tier name
	_update_display()

	# Bigger shake for milestones
	_animate_milestone_shake()

	# Extend display time for milestones
	display_timer = 5.0

func _on_streak_ended(_final_streak: int) -> void:
	# Quick fade out when streak ends
	is_visible_state = false
	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		current_streak = 0
		current_tier = 0
	)

func _update_display() -> void:
	# Format: "x15 COMBO" or "x25 RAMPAGE"
	var tier_name = TIER_NAMES[current_tier]
	combo_label.text = "x" + str(current_streak) + " " + tier_name

	# Update color based on tier
	var color = TIER_COLORS[current_tier]
	combo_label.add_theme_color_override("font_color", color)

	# Scale font size slightly based on tier
	var base_size = 24
	var size_bonus = min(current_tier, 4) * 2
	combo_label.add_theme_font_size_override("font_size", base_size + size_bonus)

func _animate_shake() -> void:
	"""Rotating shake animation that returns to base rotation."""
	var tween = create_tween()
	tween.tween_property(combo_label, "rotation", BASE_ROTATION + 0.08, 0.04)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION - 0.06, 0.04)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION + 0.03, 0.03)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION, 0.03)

func _animate_pulse() -> void:
	"""Scale pulse animation when combo increases."""
	combo_label.pivot_offset = combo_label.size / 2
	var tween = create_tween()
	tween.tween_property(combo_label, "scale", Vector2(1.15, 1.15), 0.08).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.12).set_ease(Tween.EASE_IN_OUT)

func _animate_milestone_shake() -> void:
	"""Bigger rotating shake for tier milestones."""
	var tween = create_tween()
	# Scale pop
	tween.set_parallel(true)
	tween.tween_property(combo_label, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION + 0.12, 0.05)
	tween.set_parallel(false)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION - 0.1, 0.05)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION + 0.05, 0.04)
	tween.tween_property(combo_label, "rotation", BASE_ROTATION, 0.04)
	tween.tween_property(combo_label, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_OUT)

func _show_ui() -> void:
	if not is_visible_state:
		is_visible_state = true
		var tween = create_tween()
		tween.tween_property(container, "modulate:a", 1.0, 0.15)

func _on_fade_complete() -> void:
	"""Called when the gradual fade completes."""
	is_visible_state = false
	container.modulate.a = 0.0
	current_streak = 0
	current_tier = 0
