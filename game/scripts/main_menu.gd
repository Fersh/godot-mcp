extends CanvasLayer

@onready var play_button: Button = $VBoxContainer/ButtonContainer/PlayButton
@onready var gear_button: Button = $VBoxContainer/ButtonContainer/GearButton
@onready var shop_button: Button = $VBoxContainer/ButtonContainer/ShopButton
@onready var characters_button: Button = $VBoxContainer/ButtonContainer/CharactersButton
@onready var coin_amount: Label = $VBoxContainer/CoinsDisplay/CoinAmount

func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	gear_button.pressed.connect(_on_gear_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	characters_button.pressed.connect(_on_characters_pressed)

	# Style all buttons with yellow/gold wooden look
	_style_golden_button(play_button)
	_style_golden_button(gear_button)
	_style_golden_button(shop_button)
	_style_golden_button(characters_button)

	# Update displays
	_update_coin_display()

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

func _update_coin_display() -> void:
	if StatsManager:
		coin_amount.text = " %d" % StatsManager.spendable_coins

func _on_play_pressed() -> void:
	# Go to character select screen
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")

func _on_gear_pressed() -> void:
	# TODO: Implement gear screen
	pass

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_characters_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/character_select.tscn")
