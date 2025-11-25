extends CanvasLayer

@onready var play_button: Button = $VBoxContainer/ButtonContainer/PlayButton
@onready var shop_button: Button = $VBoxContainer/ButtonContainer/ShopButton
@onready var coin_amount: Label = $VBoxContainer/CoinsDisplay/CoinAmount
@onready var stats_label: Label = $VBoxContainer/StatsLabel

func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)

	# Style buttons
	_style_button(play_button, Color(0, 1, 0.8, 1), Color(0, 0.8, 0.64, 1))
	_style_button(shop_button, Color(1, 0.84, 0, 1), Color(0.8, 0.67, 0, 1))

	# Update displays
	_update_coin_display()
	_update_stats_display()

func _style_button(button: Button, normal_color: Color, hover_color: Color) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = normal_color
	style_normal.corner_radius_top_left = 12
	style_normal.corner_radius_top_right = 12
	style_normal.corner_radius_bottom_left = 12
	style_normal.corner_radius_bottom_right = 12
	style_normal.border_width_bottom = 6
	style_normal.border_color = normal_color.darkened(0.3)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = hover_color
	style_hover.corner_radius_top_left = 12
	style_hover.corner_radius_top_right = 12
	style_hover.corner_radius_bottom_left = 12
	style_hover.corner_radius_bottom_right = 12
	style_hover.border_width_bottom = 6
	style_hover.border_color = hover_color.darkened(0.3)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = normal_color.darkened(0.1)
	style_pressed.corner_radius_top_left = 12
	style_pressed.corner_radius_top_right = 12
	style_pressed.corner_radius_bottom_left = 12
	style_pressed.corner_radius_bottom_right = 12
	style_pressed.border_width_top = 4
	style_pressed.border_color = normal_color.darkened(0.4)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)

func _update_coin_display() -> void:
	if StatsManager:
		coin_amount.text = " %d" % StatsManager.spendable_coins

func _update_stats_display() -> void:
	if StatsManager:
		stats_label.text = "Total Runs: %d | Best Wave: %d" % [
			StatsManager.total_runs,
			StatsManager.best_wave
		]

func _on_play_pressed() -> void:
	# Reset run stats and start game
	if StatsManager:
		StatsManager.reset_run()
	if AbilityManager:
		AbilityManager.reset()

	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _on_shop_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/shop.tscn")
