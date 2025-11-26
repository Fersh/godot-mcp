extends CanvasLayer

var pixel_font: Font = null
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
var pause_menu: CanvasLayer = null

@onready var button: Button = $MarginContainer/PauseButton

func _ready() -> void:
	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	button.pressed.connect(_on_pause_pressed)
	_setup_style()

func _setup_style() -> void:
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

	var style_hover = style.duplicate()
	style_hover.bg_color = Color(0.2, 0.17, 0.25, 0.95)

	var style_pressed = style.duplicate()
	style_pressed.bg_color = Color(0.1, 0.08, 0.12, 0.95)
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 2

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 14)
	button.add_theme_color_override("font_color", Color(0.9, 0.85, 0.75, 1.0))

func _on_pause_pressed() -> void:
	if pause_menu == null:
		pause_menu = pause_menu_scene.instantiate()
		pause_menu.gave_up.connect(_on_gave_up)
		get_tree().root.add_child(pause_menu)

	pause_menu.show_menu()

func _on_gave_up() -> void:
	# Trigger game over
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		main = get_node_or_null("/root/Main")

	if main and main.has_method("show_game_over"):
		main.show_game_over()
	else:
		# Fallback: just go to game over scene
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
