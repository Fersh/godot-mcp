extends CanvasLayer

@onready var play_button: Button = $ButtonContainer/PlayButton
@onready var gear_button: Button = $ButtonContainer/GearButton
@onready var shop_button: Button = $ButtonContainer/ShopButton
@onready var coin_amount: Label = $CoinsDisplay/CoinAmount

func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	gear_button.pressed.connect(_on_gear_pressed)
	shop_button.pressed.connect(_on_shop_pressed)

	# Style buttons with different colors
	_style_golden_button(play_button)  # Gold for Play
	_style_blue_button(gear_button)    # Blue for Gear
	_style_purple_button(shop_button)  # Purple for Upgrade

	# Update displays
	_update_coin_display()

	# Play main menu music (1. Stolen Future)
	if SoundManager:
		SoundManager.play_menu_music()

func _style_golden_button(button: Button) -> void:
	# Golden/yellow button with wooden bottom border (matching reference image)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.85, 0.65, 0.2, 1)  # Golden yellow
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 8  # Thicker bottom for wooden plank effect
	style_normal.border_color = Color(0.45, 0.3, 0.15, 1)  # Dark brown wood
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.92, 0.72, 0.25, 1)  # Brighter gold on hover
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 8
	style_hover.border_color = Color(0.5, 0.35, 0.18, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.75, 0.55, 0.15, 1)  # Darker when pressed
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 6  # Inverted border for pressed effect
	style_pressed.border_width_bottom = 5
	style_pressed.border_color = Color(0.4, 0.25, 0.1, 1)
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)

func _style_blue_button(button: Button) -> void:
	# Blue button for Gear
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.3, 0.5, 0.75, 1)  # Steel blue
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 8
	style_normal.border_color = Color(0.15, 0.25, 0.4, 1)  # Dark blue
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.4, 0.6, 0.85, 1)  # Brighter blue
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 8
	style_hover.border_color = Color(0.2, 0.3, 0.5, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.25, 0.4, 0.6, 1)  # Darker blue
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 6
	style_pressed.border_width_bottom = 5
	style_pressed.border_color = Color(0.1, 0.2, 0.35, 1)
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.8, 0.85, 0.95, 1))

func _style_purple_button(button: Button) -> void:
	# Purple button for Upgrade
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.55, 0.3, 0.7, 1)  # Purple
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 8
	style_normal.border_color = Color(0.3, 0.15, 0.4, 1)  # Dark purple
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.65, 0.4, 0.8, 1)  # Brighter purple
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 8
	style_hover.border_color = Color(0.35, 0.2, 0.45, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.45, 0.25, 0.55, 1)  # Darker purple
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 6
	style_pressed.border_width_bottom = 5
	style_pressed.border_color = Color(0.25, 0.1, 0.35, 1)
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(1, 0.95, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.95, 1))

func _update_coin_display() -> void:
	if StatsManager:
		coin_amount.text = " %d" % StatsManager.spendable_coins

func _on_play_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# Go to difficulty/mode selection screen
	get_tree().change_scene_to_file("res://scenes/difficulty_select.tscn")

func _on_gear_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/equipment/equipment_screen.tscn")

func _on_shop_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
