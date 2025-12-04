extends CanvasLayer

var pixel_font: Font = null
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
var pause_menu: CanvasLayer = null

@onready var button: Button = $FullScreenControl/PauseButton

func _ready() -> void:
	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	button.pressed.connect(_on_pause_pressed)
	_setup_style()
	_create_visual_icon()

func _setup_style() -> void:
	# Make the large button semi-visible for debugging (change to 0 alpha when working)
	var transparent_style = StyleBoxFlat.new()
	transparent_style.bg_color = Color(1, 0, 0, 0.3)  # RED for debugging

	button.add_theme_stylebox_override("normal", transparent_style)
	button.add_theme_stylebox_override("hover", transparent_style)
	button.add_theme_stylebox_override("pressed", transparent_style)
	button.add_theme_stylebox_override("focus", transparent_style)

	# Ensure button captures input
	button.mouse_filter = Control.MOUSE_FILTER_STOP
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND

func _create_visual_icon() -> void:
	# Create the visible pause button icon inside the large invisible button
	var visual = PanelContainer.new()
	visual.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Position in the top-right corner of the large button area
	visual.anchor_left = 1.0
	visual.anchor_right = 1.0
	visual.anchor_top = 0.0
	visual.anchor_bottom = 0.0
	visual.offset_left = -55
	visual.offset_right = -16
	visual.offset_top = 12
	visual.offset_bottom = 67

	# Style the visual panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.12, 0.2, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.border_color = Color(0.35, 0.28, 0.18, 1.0)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	visual.add_theme_stylebox_override("panel", style)

	# Add the pause text
	var label = Label.new()
	label.text = "||"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1.0))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE

	visual.add_child(label)
	button.add_child(visual)

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

	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	if pause_menu == null:
		pause_menu = pause_menu_scene.instantiate()
		pause_menu.gave_up.connect(_on_gave_up)
		get_tree().root.add_child(pause_menu)

	pause_menu.show_menu()

func _on_gave_up() -> void:
	# Trigger game over with gave_up flag
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		main = get_node_or_null("/root/Main")

	if main and main.has_method("show_game_over"):
		main.show_game_over(true)  # true = gave up
	else:
		# Fallback: just go to game over scene
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
