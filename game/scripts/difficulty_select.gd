extends CanvasLayer

# Difficulty Selection Screen
# Allows player to choose between Endless mode and Challenge mode with difficulty tiers

# UI References
var mode_container: HBoxContainer = null
var endless_btn: Button = null
var challenge_btn: Button = null
var difficulty_container: VBoxContainer = null
var difficulty_buttons: Array[Button] = []
var description_label: Label = null
var start_button: Button = null
var back_button: Button = null

# Font
var pixel_font: Font = null

# Selected values (default to Challenge mode)
var selected_mode: DifficultyManager.GameMode = DifficultyManager.GameMode.CHALLENGE
var selected_difficulty: DifficultyManager.DifficultyTier = DifficultyManager.DifficultyTier.JUVENILE

func _ready() -> void:
	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	layer = 10
	_build_ui()
	_update_difficulty_visibility()
	_update_selection_display()

func _build_ui() -> void:
	"""Build the entire UI programmatically."""
	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0.08, 0.08, 0.1, 1.0)
	add_child(bg)

	# Main container
	var main_container = VBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_CENTER)
	main_container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	main_container.grow_vertical = Control.GROW_DIRECTION_BOTH
	main_container.alignment = BoxContainer.ALIGNMENT_CENTER
	main_container.add_theme_constant_override("separation", 25)
	add_child(main_container)

	# Title
	var title = Label.new()
	title.text = "SELECT MODE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.3, 0.0, 0.8))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	main_container.add_child(title)

	# Mode selection (Endless / Challenge)
	mode_container = HBoxContainer.new()
	mode_container.alignment = BoxContainer.ALIGNMENT_CENTER
	mode_container.add_theme_constant_override("separation", 20)
	main_container.add_child(mode_container)

	challenge_btn = _create_mode_button("CHALLENGE", "10-minute run with boss encounters")
	challenge_btn.pressed.connect(_on_challenge_selected)
	mode_container.add_child(challenge_btn)

	endless_btn = _create_mode_button("ENDLESS", "Classic survival - how long can you last?")
	endless_btn.pressed.connect(_on_endless_selected)
	mode_container.add_child(endless_btn)

	# Difficulty selection (only shown in Challenge mode)
	var diff_title = Label.new()
	diff_title.text = "DIFFICULTY"
	diff_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		diff_title.add_theme_font_override("font", pixel_font)
	diff_title.add_theme_font_size_override("font_size", 20)
	diff_title.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	diff_title.name = "DifficultyTitle"
	main_container.add_child(diff_title)

	difficulty_container = VBoxContainer.new()
	difficulty_container.alignment = BoxContainer.ALIGNMENT_CENTER
	difficulty_container.add_theme_constant_override("separation", 8)
	main_container.add_child(difficulty_container)

	# Create difficulty buttons
	_create_difficulty_buttons()

	# Description label
	description_label = Label.new()
	description_label.text = ""
	description_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description_label.custom_minimum_size = Vector2(400, 50)
	if pixel_font:
		description_label.add_theme_font_override("font", pixel_font)
	description_label.add_theme_font_size_override("font_size", 12)
	description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	main_container.add_child(description_label)

	# Button container
	var btn_container = HBoxContainer.new()
	btn_container.alignment = BoxContainer.ALIGNMENT_CENTER
	btn_container.add_theme_constant_override("separation", 20)
	main_container.add_child(btn_container)

	# Back button
	back_button = Button.new()
	back_button.text = "BACK"
	back_button.custom_minimum_size = Vector2(120, 50)
	back_button.pressed.connect(_on_back_pressed)
	_style_button(back_button, Color(0.4, 0.4, 0.45))
	btn_container.add_child(back_button)

	# Start button
	start_button = Button.new()
	start_button.text = "START"
	start_button.custom_minimum_size = Vector2(150, 55)
	start_button.pressed.connect(_on_start_pressed)
	_style_button(start_button, Color(0.2, 0.75, 0.3))
	btn_container.add_child(start_button)

func _create_mode_button(text: String, tooltip: String) -> Button:
	"""Create a mode selection button."""
	var btn = Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(180, 60)
	btn.tooltip_text = tooltip

	if pixel_font:
		btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", 16)

	return btn

func _create_difficulty_buttons() -> void:
	"""Create buttons for each difficulty tier."""
	if not DifficultyManager:
		return

	difficulty_buttons.clear()

	for tier in DifficultyManager.get_all_difficulties():
		var btn = Button.new()
		var data = DifficultyManager.DIFFICULTY_DATA[tier]
		var is_completed = DifficultyManager.is_difficulty_completed(tier)

		# Add checkmark if completed
		btn.text = data["name"] + "  ✓" if is_completed else data["name"]
		btn.custom_minimum_size = Vector2(300, 45)
		# All difficulties are now selectable (temporary bypass)
		btn.disabled = false

		if pixel_font:
			btn.add_theme_font_override("font", pixel_font)
		btn.add_theme_font_size_override("font_size", 14)

		# Store tier as metadata
		btn.set_meta("tier", tier)
		btn.pressed.connect(_on_difficulty_selected.bind(tier))

		_style_difficulty_button(btn, data["color"], true)  # Always style as unlocked
		difficulty_container.add_child(btn)
		difficulty_buttons.append(btn)

func _style_difficulty_button(btn: Button, color: Color, is_unlocked: bool) -> void:
	"""Style a difficulty button based on its state."""
	var bg_color = color if is_unlocked else Color(0.3, 0.3, 0.3)
	var border_color = color.darkened(0.3) if is_unlocked else Color(0.2, 0.2, 0.2)

	var style = StyleBoxFlat.new()
	style.bg_color = bg_color.darkened(0.5)
	style.border_color = border_color
	style.set_border_width_all(2)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = bg_color.darkened(0.3) if is_unlocked else bg_color.darkened(0.5)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = bg_color.darkened(0.6)
	btn.add_theme_stylebox_override("pressed", pressed)

	var disabled_style = style.duplicate()
	disabled_style.bg_color = Color(0.15, 0.15, 0.15)
	disabled_style.border_color = Color(0.25, 0.25, 0.25)
	btn.add_theme_stylebox_override("disabled", disabled_style)

	btn.add_theme_color_override("font_color", Color.WHITE if is_unlocked else Color(0.5, 0.5, 0.5))
	btn.add_theme_color_override("font_disabled_color", Color(0.4, 0.4, 0.4))

func _style_button(btn: Button, color: Color) -> void:
	"""Style a regular button."""
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 6
	style.border_color = color.darkened(0.4)
	style.set_corner_radius_all(6)
	btn.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	btn.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	pressed.border_width_top = 5
	pressed.border_width_bottom = 4
	btn.add_theme_stylebox_override("pressed", pressed)

	if pixel_font:
		btn.add_theme_font_override("font", pixel_font)
	btn.add_theme_font_size_override("font_size", 14)

func _update_mode_buttons() -> void:
	"""Update mode button styles based on selection."""
	var endless_color = Color(0.3, 0.6, 0.9) if selected_mode == DifficultyManager.GameMode.ENDLESS else Color(0.3, 0.35, 0.4)
	var challenge_color = Color(0.9, 0.5, 0.2) if selected_mode == DifficultyManager.GameMode.CHALLENGE else Color(0.3, 0.35, 0.4)

	_style_button(endless_btn, endless_color)
	_style_button(challenge_btn, challenge_color)

func _update_difficulty_visibility() -> void:
	"""Show/hide difficulty selection based on mode (keep layout stable)."""
	var show_difficulty = (selected_mode == DifficultyManager.GameMode.CHALLENGE)

	# Use modulate instead of visible to keep layout stable
	var target_alpha = 1.0 if show_difficulty else 0.3
	difficulty_container.modulate.a = target_alpha

	# Disable/enable buttons based on mode
	for btn in difficulty_buttons:
		btn.disabled = not show_difficulty

	# Also update the title
	var diff_title = get_node_or_null("DifficultyTitle")
	if diff_title:
		diff_title.modulate.a = target_alpha

func _update_selection_display() -> void:
	"""Update all UI elements based on current selection."""
	_update_mode_buttons()

	# Update difficulty button highlights
	for btn in difficulty_buttons:
		var tier = btn.get_meta("tier") as DifficultyManager.DifficultyTier
		var is_selected = (tier == selected_difficulty)
		var data = DifficultyManager.DIFFICULTY_DATA[tier] if DifficultyManager else {}
		var is_completed = DifficultyManager.is_difficulty_completed(tier) if DifficultyManager else false

		# Update button text with checkmark if completed
		btn.text = data["name"] + "  ✓" if is_completed else data["name"]

		if is_selected:
			# Highlight selected
			var style = btn.get_theme_stylebox("normal").duplicate() as StyleBoxFlat
			style.bg_color = data["color"].darkened(0.2)
			style.border_width_left = 4
			style.border_width_right = 4
			style.border_width_top = 4
			style.border_width_bottom = 4
			style.border_color = Color.WHITE
			btn.add_theme_stylebox_override("normal", style)
		else:
			_style_difficulty_button(btn, data.get("color", Color.GRAY), true)

	# Update description
	if selected_mode == DifficultyManager.GameMode.ENDLESS:
		description_label.text = "Survive as long as you can. Enemies get stronger over time."
		description_label.add_theme_color_override("font_color", Color(0.5, 0.8, 0.5))  # Juvenile green
	elif DifficultyManager:
		description_label.text = DifficultyManager.get_difficulty_description(selected_difficulty)
		description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))  # Default grey
	else:
		description_label.text = ""
		description_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

func _on_endless_selected() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	selected_mode = DifficultyManager.GameMode.ENDLESS
	_update_difficulty_visibility()
	_update_selection_display()

func _on_challenge_selected() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	selected_mode = DifficultyManager.GameMode.CHALLENGE
	_update_difficulty_visibility()
	_update_selection_display()

func _on_difficulty_selected(tier: DifficultyManager.DifficultyTier) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# All difficulties are now selectable (temporary bypass)
	selected_difficulty = tier
	_update_selection_display()

func _on_start_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.medium()

	# Set the selected mode and difficulty
	if DifficultyManager:
		DifficultyManager.set_mode(selected_mode)
		if selected_mode == DifficultyManager.GameMode.CHALLENGE:
			DifficultyManager.set_difficulty(selected_difficulty)

	# Go to character select
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
