extends CanvasLayer

# Game HUD - Simplified UI with pause button in top left, XP bar in top center
# Clicking pause button opens pause menu

const PAUSE_BUTTON_SIZE := 32  # Simple pause button size (smaller)
const PROGRESS_BAR_HEIGHT := 30  # XP bar height
const MARGIN := 48  # Distance from edge of screen
const SPACING := 11

var player: Node2D = null
var pixel_font: Font = null
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
var pause_menu: CanvasLayer = null

# UI References
var pause_button: Button = null
var pause_icon: Label = null
var progress_bar_bg: Panel = null
var progress_bar_fill: Panel = null
var level_label: Label = null

# State
var displayed_xp: float = 0.0
var previous_xp: float = 0.0
var current_tween: Tween = null

# Animation constants (subtle movement)
const BAR_BASE_ROTATION: float = 0.0
const BAR_SHAKE_AMOUNT: float = 0.012  # Drastically reduced from 0.06
const BAR_PULSE_SCALE: float = 1.015  # Drastically reduced from 1.08
const BAR_FILL_PULSE_SCALE: float = 1.008  # Drastically reduced from 1.04

func _ready() -> void:
	layer = 50

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_create_ui()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_changed)
		player.connect("level_up", _on_level_up)

		# Initialize values
		displayed_xp = player.current_xp
		_update_progress_bar(player.current_xp, player.xp_to_next_level)
		_update_level_label(player.current_level)

func _create_ui() -> void:
	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size

	# === PAUSE BUTTON (top left, centered with stats stack) ===
	# Stats stack is 3 rows of 24px with 4px separation = 80px total
	# Center pause button (32px) with the 80px stats
	var stats_height = 80  # 3 x ICON_SIZE(24) + 2 x separation(4)
	var pause_vertical_offset = MARGIN + (stats_height - PAUSE_BUTTON_SIZE) / 2

	var pause_container = Control.new()
	pause_container.name = "PauseContainer"
	pause_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	pause_container.offset_left = MARGIN
	pause_container.offset_top = pause_vertical_offset
	pause_container.offset_right = MARGIN + PAUSE_BUTTON_SIZE
	pause_container.offset_bottom = pause_vertical_offset + PAUSE_BUTTON_SIZE
	add_child(pause_container)

	# Pause button
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	pause_button.custom_minimum_size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	pause_button.size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	pause_button.position = Vector2.ZERO
	pause_button.pressed.connect(_on_pause_pressed)
	# Note: NOT using flat = true so border shows in normal state

	# Pause button background style with light border when inactive
	var pause_bg_style = StyleBoxFlat.new()
	pause_bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	pause_bg_style.border_color = Color(0.6, 0.6, 0.65, 0.8)  # Light border when inactive
	pause_bg_style.set_border_width_all(2)
	pause_bg_style.set_corner_radius_all(4)
	pause_button.add_theme_stylebox_override("normal", pause_bg_style)

	var pause_hover_style = pause_bg_style.duplicate()
	pause_hover_style.bg_color = Color(0.15, 0.15, 0.2, 0.8)
	pause_hover_style.border_color = Color(0.8, 0.8, 0.85, 1.0)  # Brighter border on hover
	pause_button.add_theme_stylebox_override("hover", pause_hover_style)

	var pause_pressed_style = pause_bg_style.duplicate()
	pause_pressed_style.bg_color = Color(0.08, 0.08, 0.12, 0.9)
	pause_pressed_style.border_color = Color(0.5, 0.5, 0.55, 1.0)
	pause_button.add_theme_stylebox_override("pressed", pause_pressed_style)

	pause_container.add_child(pause_button)

	# Pause icon (|| symbol)
	pause_icon = Label.new()
	pause_icon.name = "PauseIcon"
	pause_icon.text = "||"
	pause_icon.size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	pause_icon.position = Vector2.ZERO
	pause_icon.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_icon.add_theme_color_override("font_color", Color(1, 1, 1, 0.9))
	pause_icon.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	pause_icon.add_theme_constant_override("shadow_offset_x", 1)
	pause_icon.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		pause_icon.add_theme_font_override("font", pixel_font)
	pause_icon.add_theme_font_size_override("font_size", 11)
	pause_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_button.add_child(pause_icon)

	# === XP BAR (top, spans from pause button left edge to same margin on right) ===
	var xp_bar_x = MARGIN  # Align with pause button left edge
	var xp_bar_width = viewport_size.x - (MARGIN * 2)  # Same margin on both sides

	var xp_container = Control.new()
	xp_container.name = "XPContainer"
	xp_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	xp_container.offset_top = MARGIN - 40  # Raised 40px
	xp_container.offset_bottom = MARGIN - 40 + PROGRESS_BAR_HEIGHT
	add_child(xp_container)

	# Progress bar background
	progress_bar_bg = Panel.new()
	progress_bar_bg.name = "ProgressBarBG"
	progress_bar_bg.size = Vector2(xp_bar_width, PROGRESS_BAR_HEIGHT)
	progress_bar_bg.position = Vector2(xp_bar_x, 0)
	progress_bar_bg.pivot_offset = Vector2(xp_bar_width / 2, PROGRESS_BAR_HEIGHT / 2)
	var progress_bg_style = StyleBoxFlat.new()
	progress_bg_style.bg_color = Color(0.1, 0.1, 0.1, 1.0)
	progress_bg_style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	progress_bg_style.set_border_width_all(2)
	progress_bg_style.set_corner_radius_all(2)
	progress_bar_bg.add_theme_stylebox_override("panel", progress_bg_style)
	xp_container.add_child(progress_bar_bg)

	# Progress bar fill
	progress_bar_fill = Panel.new()
	progress_bar_fill.name = "ProgressBarFill"
	progress_bar_fill.size = Vector2(0, PROGRESS_BAR_HEIGHT - 4)
	progress_bar_fill.position = Vector2(xp_bar_x + 2, 2)
	progress_bar_fill.clip_contents = true
	var progress_fill_style = StyleBoxFlat.new()
	progress_fill_style.bg_color = Color(0.3, 0.7, 1.0, 1.0)  # Blue
	progress_fill_style.set_corner_radius_all(1)
	progress_bar_fill.add_theme_stylebox_override("panel", progress_fill_style)
	xp_container.add_child(progress_bar_fill)
	_add_bar_texture_overlays(progress_bar_fill, PROGRESS_BAR_HEIGHT - 4, xp_bar_width)

	# Level label (centered on progress bar)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "1"
	level_label.size = Vector2(xp_bar_width, PROGRESS_BAR_HEIGHT)
	level_label.position = Vector2(xp_bar_x, 0)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		level_label.add_theme_font_override("font", pixel_font)
	level_label.add_theme_font_size_override("font_size", 10)
	xp_container.add_child(level_label)

	# Store XP bar width for progress updates
	set_meta("xp_bar_width", xp_bar_width)

func _add_bar_texture_overlays(bar: Panel, bar_height: float, bar_width: float) -> void:
	"""Add highlight and shadow overlays to create a textured gradient effect on bars."""
	var highlight_height = bar_height * 0.25  # Top 25% lighter
	var shadow_height = bar_height * 0.3  # Bottom 30% darker

	# Top highlight (lighter)
	var highlight = ColorRect.new()
	highlight.name = "Highlight"
	highlight.color = Color(1.0, 1.0, 1.0, 0.25)  # Semi-transparent white
	highlight.size = Vector2(bar_width, highlight_height)
	highlight.position = Vector2.ZERO
	highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(highlight)

	# Bottom shadow (darker)
	var shadow = ColorRect.new()
	shadow.name = "Shadow"
	shadow.color = Color(0.0, 0.0, 0.0, 0.3)  # Semi-transparent black
	shadow.size = Vector2(bar_width, shadow_height)
	shadow.position = Vector2(0, bar_height - shadow_height)
	shadow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar.add_child(shadow)

func _on_xp_changed(current_xp: float, xp_needed: float, level: int) -> void:
	_update_level_label(level)

	# Cancel existing tween
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	# Check if XP increased (not level up reset)
	var xp_increased = current_xp > previous_xp and current_xp > 0

	# If XP decreased (level up reset), snap to new value
	if current_xp < displayed_xp:
		displayed_xp = current_xp
		previous_xp = current_xp
		_update_progress_bar(current_xp, xp_needed)
		return

	previous_xp = current_xp

	# Smoothly animate to new XP value
	var start_xp = displayed_xp
	displayed_xp = current_xp
	current_tween = create_tween()
	current_tween.tween_method(
		func(val): _update_progress_bar(val, xp_needed),
		start_xp,
		current_xp,
		0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Animate XP bar on gain (both bg and fill)
	if xp_increased and progress_bar_bg:
		_animate_bar_shake(progress_bar_bg)
		_animate_bar_fill_shake(progress_bar_fill)

func _update_progress_bar(current_xp: float, xp_needed: float) -> void:
	if progress_bar_fill == null:
		return

	var xp_bar_width = get_meta("xp_bar_width", 400.0)
	var ratio = clamp(current_xp / xp_needed, 0.0, 1.0) if xp_needed > 0 else 0.0
	var fill_width = (xp_bar_width - 4) * ratio
	progress_bar_fill.size.x = fill_width

func _update_level_label(level: int) -> void:
	if level_label:
		level_label.text = str(level)

func _on_level_up(new_level: int) -> void:
	_update_level_label(new_level)

	# Pulse animation on level label
	if level_label:
		var original_scale = level_label.scale
		level_label.pivot_offset = level_label.size / 2
		var tween = create_tween()
		tween.tween_property(level_label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(level_label, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN)

func _on_pause_pressed() -> void:
	if pause_menu == null:
		pause_menu = pause_menu_scene.instantiate()
		pause_menu.gave_up.connect(_on_gave_up)
		get_tree().root.add_child(pause_menu)

	pause_menu.show_menu()

func _on_gave_up() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		main = get_node_or_null("/root/Main")

	if main and main.has_method("show_game_over"):
		main.show_game_over(true)
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _input(event: InputEvent) -> void:
	# ESC to toggle pause when not in other menus
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Check if other UIs are open
		var ability_ui = get_tree().get_first_node_in_group("ability_selection")
		if ability_ui and ability_ui.visible:
			return

		var pickup_ui = get_tree().get_first_node_in_group("item_pickup_ui")
		if pickup_ui and pickup_ui.visible:
			return

		if pause_menu and pause_menu.visible:
			pause_menu.hide_menu()
		else:
			_on_pause_pressed()

		get_viewport().set_input_as_handled()

# ============================================
# BAR ANIMATION (rotate + pulse like combo)
# ============================================

func _animate_bar_shake(bar: Control) -> void:
	"""Subtle shake and pulse animation for XP bar background."""
	if bar == null:
		return

	# Set pivot to center of bar
	bar.pivot_offset = bar.size / 2

	# Subtle shake animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Subtle pulse scale
	tween.tween_property(bar, "scale", Vector2(BAR_PULSE_SCALE, BAR_PULSE_SCALE), 0.06).set_ease(Tween.EASE_OUT)

	# Subtle rotation shake
	tween.tween_property(bar, "rotation", BAR_SHAKE_AMOUNT, 0.04)

	tween.set_parallel(false)
	tween.tween_property(bar, "rotation", -BAR_SHAKE_AMOUNT * 0.7, 0.04)
	tween.tween_property(bar, "rotation", BAR_SHAKE_AMOUNT * 0.3, 0.03)
	tween.tween_property(bar, "rotation", BAR_BASE_ROTATION, 0.03)

	# Return scale to normal
	tween.tween_property(bar, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

func _animate_bar_fill_shake(fill_bar: Control) -> void:
	"""Very subtle pulse for the fill bar inside."""
	if fill_bar == null:
		return

	# Set pivot to center of fill bar
	fill_bar.pivot_offset = fill_bar.size / 2

	# Slight delay to offset from bg animation
	var tween = create_tween()
	tween.tween_interval(0.02)

	tween.set_parallel(true)

	# Very subtle pulse scale for fill
	tween.tween_property(fill_bar, "scale", Vector2(BAR_FILL_PULSE_SCALE, BAR_FILL_PULSE_SCALE), 0.05).set_ease(Tween.EASE_OUT)

	# Very subtle rotation shake
	var fill_shake = BAR_SHAKE_AMOUNT * 0.5
	tween.tween_property(fill_bar, "rotation", fill_shake, 0.03)

	tween.set_parallel(false)
	tween.tween_property(fill_bar, "rotation", -fill_shake * 0.6, 0.03)
	tween.tween_property(fill_bar, "rotation", fill_shake * 0.2, 0.02)
	tween.tween_property(fill_bar, "rotation", BAR_BASE_ROTATION, 0.02)

	# Return scale to normal
	tween.tween_property(fill_bar, "scale", Vector2(1.0, 1.0), 0.08).set_ease(Tween.EASE_OUT)
