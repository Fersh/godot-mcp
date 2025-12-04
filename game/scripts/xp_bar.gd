extends CanvasLayer

var progress_bar: ProgressBar = null
var level_label: Label = null

var player: Node2D = null
var current_tween: Tween = null
var displayed_xp: float = 0.0

func _ready() -> void:
	# Create the UI dynamically
	_create_xp_bar_ui()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_changed)
		player.connect("level_up", _on_level_up)
		displayed_xp = player.current_xp
		progress_bar.max_value = player.xp_to_next_level
		progress_bar.value = displayed_xp
		level_label.text = "Lv " + str(player.current_level)

	# Connect to viewport size changes
	get_viewport().size_changed.connect(_on_viewport_resized)

func _create_xp_bar_ui() -> void:
	var viewport_size = get_viewport().get_visible_rect().size
	var bar_width = viewport_size.x * 0.5  # 50% of screen width

	# Create progress bar directly under CanvasLayer
	progress_bar = ProgressBar.new()
	progress_bar.size = Vector2(bar_width, 26)
	progress_bar.position = Vector2((viewport_size.x - bar_width) / 2.0, 20)  # Centered horizontally
	progress_bar.max_value = 10.0
	progress_bar.show_percentage = false

	# Style the progress bar
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	bg_style.border_width_left = 3
	bg_style.border_width_top = 3
	bg_style.border_width_right = 3
	bg_style.border_width_bottom = 3
	bg_style.border_color = Color(0.1, 0.15, 0.35, 1)
	bg_style.corner_radius_top_left = 8
	bg_style.corner_radius_top_right = 8
	bg_style.corner_radius_bottom_right = 8
	bg_style.corner_radius_bottom_left = 8

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.3, 0.7, 1, 1)
	fill_style.border_width_left = 3
	fill_style.border_width_top = 3
	fill_style.border_width_right = 3
	fill_style.border_width_bottom = 3
	fill_style.border_color = Color(0.15, 0.35, 0.6, 1)
	fill_style.corner_radius_top_left = 8
	fill_style.corner_radius_top_right = 8
	fill_style.corner_radius_bottom_right = 8
	fill_style.corner_radius_bottom_left = 8

	progress_bar.add_theme_stylebox_override("background", bg_style)
	progress_bar.add_theme_stylebox_override("fill", fill_style)
	add_child(progress_bar)

	# Create level label inside progress bar
	level_label = Label.new()
	level_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	level_label.text = "Lv 1"
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	level_label.add_theme_constant_override("shadow_offset_x", 2)
	level_label.add_theme_constant_override("shadow_offset_y", 2)

	var font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if font:
		level_label.add_theme_font_override("font", font)
	level_label.add_theme_font_size_override("font_size", 16)
	progress_bar.add_child(level_label)

func _on_viewport_resized() -> void:
	if progress_bar:
		var viewport_size = get_viewport().get_visible_rect().size
		var bar_width = viewport_size.x * 0.5
		progress_bar.size.x = bar_width
		progress_bar.position.x = (viewport_size.x - bar_width) / 2.0

func _on_xp_changed(current_xp: float, xp_needed: float, level: int) -> void:
	# Update max value immediately
	progress_bar.max_value = xp_needed
	level_label.text = "Lv " + str(level)

	# Cancel existing tween if any
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	# If XP decreased (level up reset), snap to new value
	if current_xp < displayed_xp:
		displayed_xp = current_xp
		progress_bar.value = current_xp
		return

	# Smoothly animate to new XP value
	current_tween = create_tween()
	current_tween.tween_method(_update_bar_value, displayed_xp, current_xp, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	displayed_xp = current_xp

func _update_bar_value(value: float) -> void:
	progress_bar.value = value

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv " + str(new_level)

	# Play level up sound and haptic
	if SoundManager:
		SoundManager.play_levelup()
	if HapticManager:
		HapticManager.medium()

	# Animate level label with a pulse effect
	var original_scale = level_label.scale
	level_label.pivot_offset = level_label.size / 2

	var tween = create_tween()
	tween.tween_property(level_label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(level_label, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN)
