extends CanvasLayer

@onready var play_button: Button = $VBoxContainer/ButtonContainer/PlayButton
@onready var shop_button: Button = $VBoxContainer/ButtonContainer/ShopButton
@onready var coin_amount: Label = $VBoxContainer/CoinsDisplay/CoinAmount
@onready var stats_label: Label = $VBoxContainer/StatsLabel
@onready var video_player: VideoStreamPlayer = $VideoBackground

func _ready() -> void:
	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	shop_button.pressed.connect(_on_shop_pressed)

	# Style buttons with medieval/pixel fantasy look
	_style_medieval_button(play_button, Color(0.2, 0.5, 0.3, 1))  # Green tint for Play
	_style_medieval_button(shop_button, Color(0.5, 0.35, 0.15, 1))  # Brown/gold tint for Shop

	# Ensure video loops
	if video_player:
		video_player.finished.connect(_on_video_finished)

	# Update displays
	_update_coin_display()
	_update_stats_display()

func _on_video_finished() -> void:
	# Restart video when it finishes
	if video_player:
		video_player.play()

func _style_medieval_button(button: Button, tint: Color) -> void:
	# Medieval/fantasy pixel style - dark with ornate border
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.08, 0.06, 0.04, 0.95)
	style_normal.border_width_left = 4
	style_normal.border_width_right = 4
	style_normal.border_width_top = 4
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.6, 0.5, 0.3, 1)  # Gold/bronze border
	style_normal.corner_radius_top_left = 4
	style_normal.corner_radius_top_right = 4
	style_normal.corner_radius_bottom_left = 4
	style_normal.corner_radius_bottom_right = 4
	# Inner shadow effect
	style_normal.shadow_color = tint * 0.5
	style_normal.shadow_size = 8
	style_normal.shadow_offset = Vector2(0, 0)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.12, 0.1, 0.06, 0.98)
	style_hover.border_width_left = 4
	style_hover.border_width_right = 4
	style_hover.border_width_top = 4
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.85, 0.7, 0.4, 1)  # Brighter gold on hover
	style_hover.corner_radius_top_left = 4
	style_hover.corner_radius_top_right = 4
	style_hover.corner_radius_bottom_left = 4
	style_hover.corner_radius_bottom_right = 4
	style_hover.shadow_color = tint * 0.7
	style_hover.shadow_size = 12
	style_hover.shadow_offset = Vector2(0, 0)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.06, 0.04, 0.02, 0.98)
	style_pressed.border_width_left = 4
	style_pressed.border_width_right = 4
	style_pressed.border_width_top = 6
	style_pressed.border_width_bottom = 4
	style_pressed.border_color = Color(0.5, 0.4, 0.25, 1)
	style_pressed.corner_radius_top_left = 4
	style_pressed.corner_radius_top_right = 4
	style_pressed.corner_radius_bottom_left = 4
	style_pressed.corner_radius_bottom_right = 4

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
