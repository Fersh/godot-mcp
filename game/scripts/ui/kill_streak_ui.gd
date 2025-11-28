extends CanvasLayer

# Kill Streak UI - Minimal combo display on right side
# Shows streak counter with fade out instead of progress bar

const TIER_THRESHOLDS: Array[int] = [0, 5, 10, 20, 35, 50, 75, 100]
const TIER_NAMES: Array[String] = ["", "KILLING SPREE", "RAMPAGE", "UNSTOPPABLE", "DOMINATING", "GODLIKE", "LEGENDARY", "BEYOND GODLIKE"]
const TIER_COLORS: Array[Color] = [
	Color(1.0, 1.0, 1.0),       # White (0)
	Color(1.0, 0.9, 0.3),       # Yellow (5)
	Color(1.0, 0.6, 0.2),       # Orange (10)
	Color(1.0, 0.3, 0.2),       # Red (20)
	Color(0.9, 0.2, 0.9),       # Purple (35)
	Color(0.3, 0.8, 1.0),       # Cyan (50)
	Color(1.0, 0.85, 0.0),      # Gold (75)
	Color(1.0, 1.0, 1.0),       # Prismatic/White (100)
]

var pixel_font: Font = null
var container: Control = null
var streak_label: Label = null
var tier_label: Label = null

var current_streak: int = 0
var current_tier: int = 0
var display_timer: float = 0.0
var fade_duration: float = 0.5
var is_visible_state: bool = false
var pulse_time: float = 0.0
var rainbow_time: float = 0.0

# Animation state
var milestone_animation_active: bool = false
var milestone_scale: float = 1.0

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
	# Main container - positioned at top right, below stats
	container = Control.new()
	container.name = "StreakContainer"
	container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	container.anchor_left = 0.75
	container.anchor_right = 1.0
	container.anchor_top = 0.12  # Below points/coins/wave
	container.anchor_bottom = 0.25
	container.offset_right = -20
	container.modulate.a = 0.0
	add_child(container)

	# Tier name label (RAMPAGE, GODLIKE, etc.) - shown above streak
	tier_label = Label.new()
	tier_label.name = "TierLabel"
	tier_label.text = ""
	tier_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	tier_label.anchor_left = 0.0
	tier_label.anchor_right = 1.0
	tier_label.anchor_top = 0.0
	tier_label.anchor_bottom = 0.5
	tier_label.offset_right = -10
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tier_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	if pixel_font:
		tier_label.add_theme_font_override("font", pixel_font)
	tier_label.add_theme_font_size_override("font_size", 14)
	tier_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	tier_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	tier_label.add_theme_constant_override("outline_size", 3)
	tier_label.pivot_offset = Vector2(100, 15)
	container.add_child(tier_label)

	# Streak count (e.g., "x15") - main display
	streak_label = Label.new()
	streak_label.name = "StreakLabel"
	streak_label.text = "x0"
	streak_label.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	streak_label.anchor_left = 0.0
	streak_label.anchor_right = 1.0
	streak_label.anchor_top = 0.5
	streak_label.anchor_bottom = 1.0
	streak_label.offset_right = -10
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	streak_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	if pixel_font:
		streak_label.add_theme_font_override("font", pixel_font)
	streak_label.add_theme_font_size_override("font_size", 28)
	streak_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	streak_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	streak_label.add_theme_constant_override("outline_size", 4)
	streak_label.pivot_offset = Vector2(100, 20)
	container.add_child(streak_label)

func _process(delta: float) -> void:
	# Update visibility with fade out
	if is_visible_state:
		display_timer -= delta
		if display_timer <= 0:
			_start_fade_out()

	# Pulse animation for high tiers
	if current_tier >= 3 and is_visible_state:
		pulse_time += delta * (2.0 + current_tier * 0.5)
		var pulse = 1.0 + sin(pulse_time) * 0.03 * current_tier
		streak_label.scale = Vector2(pulse, pulse) * milestone_scale
		tier_label.scale = Vector2(pulse * 0.9, pulse * 0.9)

	# Rainbow effect for max tier
	if current_tier >= 6 and is_visible_state:
		rainbow_time += delta * 2.0
		var hue = fmod(rainbow_time, 1.0)
		var rainbow_color = Color.from_hsv(hue, 0.8, 1.0)
		streak_label.add_theme_color_override("font_color", rainbow_color)

	# Milestone animation
	if milestone_animation_active:
		milestone_scale = lerp(milestone_scale, 1.0, delta * 8.0)
		if milestone_scale < 1.05:
			milestone_animation_active = false
			milestone_scale = 1.0

func _on_streak_changed(streak: int, tier: int) -> void:
	current_streak = streak
	current_tier = tier

	if streak > 0:
		_show_ui()
		_update_display()
		display_timer = 3.0

func _on_streak_milestone(tier: int, tier_name: String) -> void:
	# Epic milestone animation
	milestone_animation_active = true
	milestone_scale = 1.5  # Start big, shrink down

	# Update tier label with animation
	tier_label.text = tier_name
	tier_label.scale = Vector2(0.5, 0.5)

	var tween = create_tween()
	tween.tween_property(tier_label, "scale", Vector2(1.1, 1.1), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(tier_label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)

	# Extend display time for milestones
	display_timer = 5.0

func _on_streak_ended(final_streak: int) -> void:
	# Just fade out - no "STREAK ENDED" text
	_start_fade_out()

func _update_display() -> void:
	streak_label.text = "x" + str(current_streak)

	# Update colors based on tier
	var color = TIER_COLORS[current_tier]
	streak_label.add_theme_color_override("font_color", color)
	tier_label.add_theme_color_override("font_color", color)

	# Update tier name (empty for tier 0)
	if current_tier > 0:
		tier_label.text = TIER_NAMES[current_tier]
	else:
		tier_label.text = "COMBO"

	# Scale font size based on streak (subtle)
	var base_size = 28
	var size_bonus = min(current_streak / 10, 6) * 2
	streak_label.add_theme_font_size_override("font_size", base_size + int(size_bonus))

func _show_ui() -> void:
	if not is_visible_state:
		is_visible_state = true
		var tween = create_tween()
		tween.tween_property(container, "modulate:a", 1.0, 0.15)

func _start_fade_out() -> void:
	if is_visible_state:
		is_visible_state = false
		var tween = create_tween()
		tween.tween_property(container, "modulate:a", 0.0, fade_duration)
		tween.tween_callback(func():
			current_streak = 0
			current_tier = 0
		)
