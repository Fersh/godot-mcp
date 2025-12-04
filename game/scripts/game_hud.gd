extends CanvasLayer

# Game HUD - Simplified UI with pause button in top left, XP bar in top center
# Clicking pause button opens pause menu

const PAUSE_BUTTON_SIZE := 32  # Visible pause button size
const PAUSE_TOUCH_SIZE := 80  # Larger touch area for easier tapping
const PROGRESS_BAR_HEIGHT := 31  # XP bar height (increased by 5px)
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

# Missions tracker UI
var missions_container: VBoxContainer = null
var missions_content: VBoxContainer = null  # Container for mission rows (collapsible)
var missions_content_margin: MarginContainer = null  # Margin wrapper for content
var missions_header: Button = null  # Clickable header
var missions_expanded: bool = true  # Track expanded state
var mission_rows: Array = []  # Array of HBoxContainers for each mission

# Mission completion notification
var notification_container: Control = null

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

	# Connect to missions manager signals
	if MissionsManager:
		MissionsManager.mission_completed.connect(_on_mission_completed)
		MissionsManager.mission_progress_updated.connect(_on_mission_progress_updated)
		MissionsManager.clear_run_completed_missions()  # Clear at run start
		_update_missions_display()

	# Connect to settings changes to toggle missions tracker
	if GameSettings:
		GameSettings.settings_changed.connect(_on_settings_changed)
		_update_missions_tracker_visibility()

func _create_ui() -> void:
	# Get viewport size for positioning
	var viewport_size = get_viewport().get_visible_rect().size

	# === PAUSE BUTTON (top right, with larger touch area) ===
	# Use a full-screen Control to position the button properly
	var pause_container = Control.new()
	pause_container.name = "PauseContainer"
	pause_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	pause_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Let clicks pass through except for button
	add_child(pause_container)

	# Pause button - LARGE invisible touch area
	pause_button = Button.new()
	pause_button.name = "PauseButton"
	# Position in top-right corner with larger touch area
	pause_button.anchor_left = 1.0
	pause_button.anchor_right = 1.0
	pause_button.anchor_top = 0.0
	pause_button.anchor_bottom = 0.0
	pause_button.offset_left = -PAUSE_TOUCH_SIZE - 16
	pause_button.offset_right = -16
	pause_button.offset_top = 12
	pause_button.offset_bottom = 12 + PAUSE_TOUCH_SIZE
	pause_button.pressed.connect(_on_pause_pressed)
	pause_button.flat = true  # No default styling
	pause_button.focus_mode = Control.FOCUS_NONE
	pause_button.mouse_filter = Control.MOUSE_FILTER_STOP

	# Transparent style for the large touch area
	var touch_style = StyleBoxFlat.new()
	touch_style.bg_color = Color(0, 0, 0, 0)  # Fully transparent
	pause_button.add_theme_stylebox_override("normal", touch_style)
	pause_button.add_theme_stylebox_override("hover", touch_style)
	pause_button.add_theme_stylebox_override("pressed", touch_style)
	pause_button.add_theme_stylebox_override("focus", touch_style)

	pause_container.add_child(pause_button)

	# Visible pause button background (smaller, positioned in corner of touch area)
	var pause_visual = Panel.new()
	pause_visual.name = "PauseVisual"
	pause_visual.custom_minimum_size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	pause_visual.size = Vector2(PAUSE_BUTTON_SIZE, PAUSE_BUTTON_SIZE)
	# Position in top-right corner of the touch area
	pause_visual.anchor_left = 1.0
	pause_visual.anchor_right = 1.0
	pause_visual.anchor_top = 0.0
	pause_visual.anchor_bottom = 0.0
	pause_visual.offset_left = -PAUSE_BUTTON_SIZE
	pause_visual.offset_right = 0
	pause_visual.offset_top = 9
	pause_visual.offset_bottom = 9 + PAUSE_BUTTON_SIZE
	pause_visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	var pause_bg_style = StyleBoxFlat.new()
	pause_bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.7)
	pause_bg_style.border_color = Color(0.6, 0.6, 0.65, 0.8)
	pause_bg_style.set_border_width_all(2)
	pause_bg_style.set_corner_radius_all(4)
	pause_visual.add_theme_stylebox_override("panel", pause_bg_style)
	pause_button.add_child(pause_visual)

	# === MISSIONS TRACKER (below pause button) ===
	_create_missions_tracker()

	# Pause icon (|| symbol) - inside the visual panel
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
	pause_icon.add_theme_font_size_override("font_size", 13)
	pause_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	pause_visual.add_child(pause_icon)

	# === XP BAR (top center, 60% of screen width) ===
	var xp_bar_width = viewport_size.x * 0.6  # 60% of screen width
	var xp_bar_x = (viewport_size.x - xp_bar_width) / 2.0  # Centered

	var xp_container = Control.new()
	xp_container.name = "XPContainer"
	xp_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	xp_container.offset_top = MARGIN - 30  # Raised 30px (was 40px)
	xp_container.offset_bottom = MARGIN - 30 + PROGRESS_BAR_HEIGHT + 18  # Added 18px margin below (10 + 8)
	xp_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Allow clicks to pass through to pause button
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
	progress_bg_style.set_corner_radius_all(4)  # Same as pause button
	progress_bar_bg.add_theme_stylebox_override("panel", progress_bg_style)
	xp_container.add_child(progress_bar_bg)

	# Progress bar fill
	progress_bar_fill = Panel.new()
	progress_bar_fill.name = "ProgressBarFill"
	progress_bar_fill.size = Vector2(0, PROGRESS_BAR_HEIGHT - 4)
	progress_bar_fill.position = Vector2(xp_bar_x + 2, 2)  # Inside the bg bar
	progress_bar_fill.clip_contents = true
	var progress_fill_style = StyleBoxFlat.new()
	progress_fill_style.bg_color = Color(0.3, 0.7, 1.0, 1.0)  # Blue
	progress_fill_style.set_corner_radius_all(3)  # Slightly less than bg to fit inside
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
	level_label.add_theme_font_size_override("font_size", 12)
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
	# Don't show pause menu if ability selection UIs are visible
	var ability_ui = get_tree().get_first_node_in_group("ability_selection_ui")
	if ability_ui and ability_ui.visible:
		return

	var active_ability_ui = get_tree().get_first_node_in_group("active_ability_selection_ui")
	if active_ability_ui and active_ability_ui.visible:
		return

	var ultimate_ui = get_tree().get_first_node_in_group("ultimate_selection_ui")
	if ultimate_ui and ultimate_ui.visible:
		return

	var pickup_ui = get_tree().get_first_node_in_group("item_pickup_ui")
	if pickup_ui and pickup_ui.visible:
		return

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
		var ability_ui = get_tree().get_first_node_in_group("ability_selection_ui")
		if ability_ui and ability_ui.visible:
			return

		var active_ability_ui = get_tree().get_first_node_in_group("active_ability_selection_ui")
		if active_ability_ui and active_ability_ui.visible:
			return

		var ultimate_ui = get_tree().get_first_node_in_group("ultimate_selection_ui")
		if ultimate_ui and ultimate_ui.visible:
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

# ============================================
# MISSIONS TRACKER
# ============================================

func _create_missions_tracker() -> void:
	"""Create the missions tracker UI below the pause button."""
	# Load saved expanded state
	if GameSettings:
		missions_expanded = GameSettings.get_setting("missions_expanded", true)

	missions_container = VBoxContainer.new()
	missions_container.name = "MissionsTracker"
	missions_container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	missions_container.offset_left = MARGIN + 80  # Shifted 80px right (40 + 40)
	missions_container.offset_top = MARGIN + PAUSE_BUTTON_SIZE + 35  # Adjusted down 10px
	missions_container.offset_right = MARGIN + 260
	missions_container.offset_bottom = MARGIN + PAUSE_BUTTON_SIZE + 280
	missions_container.add_theme_constant_override("separation", 8)
	add_child(missions_container)

	# Create header button
	missions_header = Button.new()
	missions_header.name = "MissionsHeader"
	missions_header.flat = true
	missions_header.alignment = HORIZONTAL_ALIGNMENT_LEFT
	missions_header.text = ("v " if missions_expanded else "> ") + "MISSIONS"
	missions_header.add_theme_font_size_override("font_size", 12)
	missions_header.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	missions_header.add_theme_color_override("font_hover_color", Color(1.0, 1.0, 1.0))
	if pixel_font:
		missions_header.add_theme_font_override("font", pixel_font)
	# Remove all borders/backgrounds
	var empty_style = StyleBoxEmpty.new()
	missions_header.add_theme_stylebox_override("focus", empty_style)
	missions_header.add_theme_stylebox_override("normal", empty_style)
	missions_header.add_theme_stylebox_override("hover", empty_style)
	missions_header.add_theme_stylebox_override("pressed", empty_style)
	missions_header.add_theme_stylebox_override("disabled", empty_style)
	missions_header.focus_mode = Control.FOCUS_NONE
	missions_header.pressed.connect(_on_missions_header_pressed)
	# Set initial transparency based on collapsed state
	missions_header.modulate.a = 1.0 if missions_expanded else 0.5
	missions_container.add_child(missions_header)

	# Create content container for mission rows with 10px top margin
	missions_content_margin = MarginContainer.new()
	missions_content_margin.name = "MissionsContentMargin"
	missions_content_margin.add_theme_constant_override("margin_top", 10)
	missions_content_margin.visible = missions_expanded
	missions_container.add_child(missions_content_margin)

	missions_content = VBoxContainer.new()
	missions_content.name = "MissionsContent"
	missions_content.add_theme_constant_override("separation", 24)
	missions_content_margin.add_child(missions_content)

	# Create 3 mission row slots with slight rotation (left side down)
	for i in range(3):
		var row = _create_mission_row()
		row.visible = false
		row.pivot_offset = Vector2(0, 14)  # Pivot on left side
		row.rotation = 0.02  # Very slight rotation (~1.1 degrees)
		missions_content.add_child(row)
		mission_rows.append(row)

func _on_missions_header_pressed() -> void:
	"""Toggle missions expanded/collapsed state."""
	missions_expanded = not missions_expanded
	missions_content_margin.visible = missions_expanded
	missions_header.text = ("v " if missions_expanded else "> ") + "MISSIONS"
	# Make header more transparent when collapsed
	missions_header.modulate.a = 1.0 if missions_expanded else 0.5

	# Save state
	if GameSettings:
		GameSettings.set_setting("missions_expanded", missions_expanded)

	# Play sound
	if SoundManager:
		SoundManager.play_click()

func _create_mission_row() -> Control:
	"""Create a single mission row UI element - simplified with dropshadow."""
	var container = Control.new()
	container.custom_minimum_size = Vector2(200, 34)  # Increased height by 6px

	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 7)

	# Mission description label (with dropshadow) - smaller and lighter
	var title = Label.new()
	title.name = "Title"
	title.add_theme_font_size_override("font_size", 12)  # Reduced by 2px
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))  # Slightly lighter
	title.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 1)
	title.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	vbox.add_child(title)

	# Progress bar background - fixed width regardless of text
	var bar_bg = Panel.new()
	bar_bg.name = "ProgressBG"
	bar_bg.custom_minimum_size = Vector2(144, 16)  # Width reduced 20%, height reduced 2px
	bar_bg.size = Vector2(144, 16)  # Fixed size
	bar_bg.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN  # Don't expand with text
	var bar_bg_style = StyleBoxFlat.new()
	bar_bg_style.bg_color = Color(0.1, 0.1, 0.12, 0.8)
	bar_bg_style.set_corner_radius_all(3)
	bar_bg.add_theme_stylebox_override("panel", bar_bg_style)

	# Progress bar fill
	var bar_fill = Panel.new()
	bar_fill.name = "ProgressFill"
	bar_fill.size = Vector2(0, 16)  # Height reduced 2px
	bar_fill.position = Vector2(0, 0)
	var bar_fill_style = StyleBoxFlat.new()
	bar_fill_style.bg_color = Color(0.9, 0.7, 0.2, 1)
	bar_fill_style.set_corner_radius_all(3)
	bar_fill.add_theme_stylebox_override("panel", bar_fill_style)
	bar_bg.add_child(bar_fill)

	# Percentage text inside the bar
	var percent_label = Label.new()
	percent_label.name = "PercentLabel"
	percent_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	percent_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	percent_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	percent_label.add_theme_font_size_override("font_size", 10)  # Reduced 2px
	percent_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	percent_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	percent_label.add_theme_constant_override("shadow_offset_x", 1)
	percent_label.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		percent_label.add_theme_font_override("font", pixel_font)
	bar_bg.add_child(percent_label)

	vbox.add_child(bar_bg)
	container.add_child(vbox)

	return container

func _update_missions_display() -> void:
	"""Update the missions tracker with current mission data."""
	if not MissionsManager:
		return

	var missions = MissionsManager.get_in_progress_missions(3)

	for i in range(mission_rows.size()):
		var row = mission_rows[i]
		if i < missions.size():
			var mission = missions[i]
			row.visible = true
			_update_mission_row(row, mission)
		else:
			row.visible = false

func _update_mission_row(row: Control, mission) -> void:
	"""Update a single mission row with mission data."""
	var vbox = row.get_node("VBox")
	var title = vbox.get_node("Title")
	var bar_bg = vbox.get_node("ProgressBG")
	var bar_fill = bar_bg.get_node("ProgressFill")
	var percent_label = bar_bg.get_node("PercentLabel")

	# Show description instead of title, truncate if needed
	var display_text = mission.description
	if display_text.length() > 28:
		display_text = display_text.substr(0, 26) + ".."
	title.text = display_text

	# Update progress bar
	var progress_ratio = float(mission.current_progress) / float(mission.target_value) if mission.target_value > 0 else 0
	progress_ratio = clamp(progress_ratio, 0.0, 1.0)
	var bar_width = 144.0  # Reduced 20%
	bar_fill.size.x = bar_width * progress_ratio

	# Update percentage text
	var percent = int(progress_ratio * 100)
	percent_label.text = "%d%%" % percent

	# Smart font color: white if bar hasn't reached center, black if it has
	if progress_ratio >= 0.5:
		percent_label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
		percent_label.add_theme_color_override("font_shadow_color", Color(1, 1, 1, 0.3))
	else:
		percent_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
		percent_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))

	# Change bar color if complete
	if mission.is_completed:
		var fill_style = bar_fill.get_theme_stylebox("panel").duplicate()
		fill_style.bg_color = Color(0.3, 0.9, 0.4, 1)  # Green when complete
		bar_fill.add_theme_stylebox_override("panel", fill_style)

func _on_mission_completed(mission) -> void:
	"""Handle mission completion - show notification."""
	_show_mission_notification(mission)
	_update_missions_display()

func _on_mission_progress_updated(mission) -> void:
	"""Handle mission progress update."""
	_update_missions_display()
	# Find and animate the row for this mission
	_animate_mission_progress(mission)

func _animate_mission_progress(mission) -> void:
	"""Animate the progress bar for a specific mission."""
	if not MissionsManager:
		return

	var displayed_missions = MissionsManager.get_in_progress_missions(3)
	for i in range(min(displayed_missions.size(), mission_rows.size())):
		if displayed_missions[i].id == mission.id:
			var row = mission_rows[i]
			if not row.visible:
				continue
			var vbox = row.get_node("VBox")
			var bar_bg = vbox.get_node("ProgressBG")
			var bar_fill = bar_bg.get_node("ProgressFill")
			_animate_mission_bar(bar_bg, bar_fill)
			break

func _animate_mission_bar(bar_bg: Control, bar_fill: Control) -> void:
	"""Subtle shake and pulse animation for mission progress bar."""
	if bar_bg == null or bar_fill == null:
		return

	# Set pivot to center
	bar_bg.pivot_offset = bar_bg.size / 2
	bar_fill.pivot_offset = Vector2(bar_fill.size.x / 2, bar_fill.size.y / 2)

	# Animate background bar
	var tween = create_tween()
	tween.set_parallel(true)

	# Subtle pulse scale
	tween.tween_property(bar_bg, "scale", Vector2(1.04, 1.08), 0.05).set_ease(Tween.EASE_OUT)

	# Very subtle rotation shake
	tween.tween_property(bar_bg, "rotation", 0.015, 0.03)

	tween.set_parallel(false)
	tween.tween_property(bar_bg, "rotation", -0.01, 0.03)
	tween.tween_property(bar_bg, "rotation", 0.005, 0.02)
	tween.tween_property(bar_bg, "rotation", 0.0, 0.02)

	# Return scale to normal
	tween.tween_property(bar_bg, "scale", Vector2(1.0, 1.0), 0.08).set_ease(Tween.EASE_OUT)

	# Animate fill bar with slight delay
	var fill_tween = create_tween()
	fill_tween.tween_interval(0.02)
	fill_tween.tween_property(bar_fill, "scale", Vector2(1.02, 1.06), 0.04).set_ease(Tween.EASE_OUT)
	fill_tween.tween_property(bar_fill, "scale", Vector2(1.0, 1.0), 0.06).set_ease(Tween.EASE_OUT)

func _show_mission_notification(mission) -> void:
	"""Show a juicy notification when a mission is completed."""
	# Play sound and haptic
	if SoundManager:
		SoundManager.play_player_join()
	if HapticManager:
		HapticManager.medium()

	# Create notification container if needed
	if notification_container:
		notification_container.queue_free()

	notification_container = Control.new()
	notification_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notification_container.offset_top = 80
	notification_container.offset_bottom = 160
	add_child(notification_container)

	# Create notification panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER_TOP)
	panel.offset_left = -150
	panel.offset_right = 150
	panel.offset_top = 0
	panel.offset_bottom = 70

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.08, 0.15, 0.95)
	style.border_color = Color(1.0, 0.85, 0.3, 1)
	style.set_border_width_all(3)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(1.0, 0.8, 0.2, 0.3)
	style.shadow_size = 10
	panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 4)

	# "MISSION COMPLETE!" text
	var header = Label.new()
	header.text = "MISSION COMPLETE!"
	header.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header.add_theme_font_size_override("font_size", 12)
	header.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2))
	if pixel_font:
		header.add_theme_font_override("font", pixel_font)
	vbox.add_child(header)

	# Mission title
	var title = Label.new()
	title.text = mission.title
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 10)
	title.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9))
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	vbox.add_child(title)

	# Coin reward
	var reward = Label.new()
	reward.text = "+%d Coins" % mission.reward_coins
	reward.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	reward.add_theme_font_size_override("font_size", 11)
	reward.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	if pixel_font:
		reward.add_theme_font_override("font", pixel_font)
	vbox.add_child(reward)

	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 15)
	margin.add_theme_constant_override("margin_right", 15)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.add_child(vbox)
	panel.add_child(margin)

	notification_container.add_child(panel)

	# Animate in
	panel.scale = Vector2(0.5, 0.5)
	panel.pivot_offset = panel.size / 2
	panel.modulate.a = 0

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)

	tween.set_parallel(false)
	tween.tween_interval(2.5)  # Show for 2.5 seconds

	# Animate out
	tween.tween_property(panel, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		if notification_container:
			notification_container.queue_free()
			notification_container = null
	)

# ============================================
# SETTINGS
# ============================================

func _on_settings_changed() -> void:
	"""Handle settings changes."""
	_update_missions_tracker_visibility()

func _update_missions_tracker_visibility() -> void:
	"""Show/hide missions tracker based on settings."""
	if missions_container:
		var should_show = GameSettings.track_missions_enabled if GameSettings else true
		missions_container.visible = should_show
