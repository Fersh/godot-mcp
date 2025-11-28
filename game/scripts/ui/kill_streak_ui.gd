extends CanvasLayer

# Kill Streak UI - Epic visual display for combo kills
# Shows streak counter with escalating effects

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
var multiplier_label: Label = null
var progress_bar: Panel = null
var progress_fill: Panel = null
var glow_effect: Panel = null

var current_streak: int = 0
var current_tier: int = 0
var display_timer: float = 0.0
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
	# Main container - positioned at top center
	container = Control.new()
	container.name = "StreakContainer"
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.anchor_top = 0.02
	container.anchor_bottom = 0.15
	container.offset_left = 0
	container.offset_right = 0
	container.modulate.a = 0.0
	add_child(container)

	# Glow background effect
	glow_effect = Panel.new()
	glow_effect.name = "GlowEffect"
	glow_effect.set_anchors_preset(Control.PRESET_CENTER_TOP)
	glow_effect.anchor_left = 0.3
	glow_effect.anchor_right = 0.7
	glow_effect.anchor_top = 0.0
	glow_effect.anchor_bottom = 1.0
	glow_effect.offset_top = -10
	glow_effect.offset_bottom = 10
	var glow_style = StyleBoxFlat.new()
	glow_style.bg_color = Color(1.0, 0.8, 0.2, 0.0)  # Starts invisible
	glow_style.set_corner_radius_all(20)
	glow_effect.add_theme_stylebox_override("panel", glow_style)
	container.add_child(glow_effect)

	# Streak count (big number)
	streak_label = Label.new()
	streak_label.name = "StreakLabel"
	streak_label.text = "0"
	streak_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	streak_label.anchor_left = 0.5
	streak_label.anchor_right = 0.5
	streak_label.anchor_top = 0.1
	streak_label.anchor_bottom = 0.5
	streak_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	streak_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	streak_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		streak_label.add_theme_font_override("font", pixel_font)
	streak_label.add_theme_font_size_override("font_size", 48)
	streak_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	streak_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	streak_label.add_theme_constant_override("shadow_offset_x", 4)
	streak_label.add_theme_constant_override("shadow_offset_y", 4)
	streak_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	streak_label.add_theme_constant_override("outline_size", 6)
	streak_label.pivot_offset = Vector2(100, 30)
	container.add_child(streak_label)

	# Tier name label (RAMPAGE, GODLIKE, etc.)
	tier_label = Label.new()
	tier_label.name = "TierLabel"
	tier_label.text = ""
	tier_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	tier_label.anchor_left = 0.5
	tier_label.anchor_right = 0.5
	tier_label.anchor_top = 0.5
	tier_label.anchor_bottom = 0.7
	tier_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		tier_label.add_theme_font_override("font", pixel_font)
	tier_label.add_theme_font_size_override("font_size", 24)
	tier_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	tier_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	tier_label.add_theme_constant_override("shadow_offset_x", 3)
	tier_label.add_theme_constant_override("shadow_offset_y", 3)
	tier_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	tier_label.add_theme_constant_override("outline_size", 4)
	tier_label.pivot_offset = Vector2(100, 15)
	container.add_child(tier_label)

	# Multiplier label
	multiplier_label = Label.new()
	multiplier_label.name = "MultiplierLabel"
	multiplier_label.text = ""
	multiplier_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
	multiplier_label.anchor_left = 0.5
	multiplier_label.anchor_right = 0.5
	multiplier_label.anchor_top = 0.7
	multiplier_label.anchor_bottom = 0.85
	multiplier_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		multiplier_label.add_theme_font_override("font", pixel_font)
	multiplier_label.add_theme_font_size_override("font_size", 14)
	multiplier_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	multiplier_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	multiplier_label.add_theme_constant_override("shadow_offset_x", 2)
	multiplier_label.add_theme_constant_override("shadow_offset_y", 2)
	container.add_child(multiplier_label)

	# Progress bar background
	progress_bar = Panel.new()
	progress_bar.name = "ProgressBar"
	progress_bar.set_anchors_preset(Control.PRESET_CENTER_TOP)
	progress_bar.anchor_left = 0.35
	progress_bar.anchor_right = 0.65
	progress_bar.anchor_top = 0.88
	progress_bar.anchor_bottom = 0.95
	var bar_style = StyleBoxFlat.new()
	bar_style.bg_color = Color(0.1, 0.1, 0.1, 0.8)
	bar_style.set_corner_radius_all(4)
	bar_style.border_color = Color(0.3, 0.3, 0.3, 0.8)
	bar_style.set_border_width_all(2)
	progress_bar.add_theme_stylebox_override("panel", bar_style)
	container.add_child(progress_bar)

	# Progress bar fill
	progress_fill = Panel.new()
	progress_fill.name = "ProgressFill"
	progress_fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	progress_fill.anchor_right = 1.0
	progress_fill.offset_left = 2
	progress_fill.offset_right = -2
	progress_fill.offset_top = 2
	progress_fill.offset_bottom = -2
	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(1.0, 0.9, 0.3, 1.0)
	fill_style.set_corner_radius_all(2)
	progress_fill.add_theme_stylebox_override("panel", fill_style)
	progress_bar.add_child(progress_fill)

func _process(delta: float) -> void:
	# Update visibility
	if is_visible_state:
		display_timer -= delta
		if display_timer <= 0:
			_hide_ui()

	# Update progress bar
	if KillStreakManager and is_visible_state:
		var progress = KillStreakManager.get_streak_progress()
		progress_fill.anchor_right = progress

	# Pulse animation for high tiers
	if current_tier >= 3 and is_visible_state:
		pulse_time += delta * (2.0 + current_tier * 0.5)
		var pulse = 1.0 + sin(pulse_time) * 0.05 * current_tier
		streak_label.scale = Vector2(pulse, pulse) * milestone_scale
		tier_label.scale = Vector2(pulse * 0.9, pulse * 0.9)

	# Rainbow effect for max tier
	if current_tier >= 6 and is_visible_state:
		rainbow_time += delta * 2.0
		var hue = fmod(rainbow_time, 1.0)
		var rainbow_color = Color.from_hsv(hue, 0.8, 1.0)
		streak_label.add_theme_color_override("font_color", rainbow_color)
		_update_glow_color(rainbow_color)

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
	milestone_scale = 1.8  # Start big, shrink down

	# Update tier label with animation
	tier_label.text = tier_name
	tier_label.scale = Vector2(0.5, 0.5)

	var tween = create_tween()
	tween.tween_property(tier_label, "scale", Vector2(1.2, 1.2), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(tier_label, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_IN)

	# Flash the glow
	var color = TIER_COLORS[tier]
	_flash_glow(color)

	# Extend display time for milestones
	display_timer = 5.0

func _on_streak_ended(final_streak: int) -> void:
	# Show "STREAK ENDED" briefly
	if final_streak >= 10:
		tier_label.text = "STREAK ENDED: " + str(final_streak)
		tier_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
		display_timer = 2.0
	else:
		_hide_ui()

func _update_display() -> void:
	streak_label.text = str(current_streak)

	# Update colors based on tier
	var color = TIER_COLORS[current_tier]
	streak_label.add_theme_color_override("font_color", color)
	tier_label.add_theme_color_override("font_color", color)

	# Update glow
	_update_glow_color(color)

	# Update tier name
	if current_tier > 0:
		tier_label.text = TIER_NAMES[current_tier]
	else:
		tier_label.text = "COMBO"

	# Update multiplier display
	if KillStreakManager:
		var xp_mult = KillStreakManager.get_xp_multiplier()
		if xp_mult > 1.0:
			multiplier_label.text = "x%.1f XP & GOLD" % xp_mult
		else:
			multiplier_label.text = ""

	# Scale font size based on streak
	var base_size = 48
	var size_bonus = min(current_streak / 5, 10) * 2
	streak_label.add_theme_font_size_override("font_size", base_size + int(size_bonus))

	# Update progress bar color
	var fill_style = progress_fill.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	fill_style.bg_color = color
	progress_fill.add_theme_stylebox_override("panel", fill_style)

func _update_glow_color(color: Color) -> void:
	var intensity = 0.1 + current_tier * 0.08
	var glow_style = glow_effect.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	glow_style.bg_color = Color(color.r, color.g, color.b, intensity)
	glow_effect.add_theme_stylebox_override("panel", glow_style)

func _flash_glow(color: Color) -> void:
	var tween = create_tween()
	var glow_style = glow_effect.get_theme_stylebox("panel").duplicate() as StyleBoxFlat

	# Flash bright
	glow_style.bg_color = Color(color.r, color.g, color.b, 0.5)
	glow_effect.add_theme_stylebox_override("panel", glow_style)

	# Fade back
	tween.tween_method(func(alpha: float):
		var style = glow_effect.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.bg_color = Color(color.r, color.g, color.b, alpha)
		glow_effect.add_theme_stylebox_override("panel", style)
	, 0.5, 0.15, 0.5)

func _show_ui() -> void:
	if not is_visible_state:
		is_visible_state = true
		var tween = create_tween()
		tween.tween_property(container, "modulate:a", 1.0, 0.2)

func _hide_ui() -> void:
	if is_visible_state:
		is_visible_state = false
		var tween = create_tween()
		tween.tween_property(container, "modulate:a", 0.0, 0.3)
		tween.tween_callback(func():
			current_streak = 0
			current_tier = 0
		)
