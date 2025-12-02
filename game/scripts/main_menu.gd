extends CanvasLayer

@onready var play_button: Button = $ButtonContainer/PlayButton
@onready var gear_button: Button = $ButtonContainer/GearButton
@onready var shop_button: Button = $ButtonContainer/ShopButton
@onready var princesses_button: Button = $ButtonContainer/PrincessesButton
@onready var coin_amount: Label = $CoinsDisplay/CoinAmount

var curse_label: Label = null
var version_label: Label = null
var pixel_font: Font = null

const VERSION = "1.0.0"
const BUILD = 9

func _ready() -> void:
	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	gear_button.pressed.connect(_on_gear_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	princesses_button.pressed.connect(_on_princesses_pressed)

	# Style buttons with different colors
	_style_golden_button(play_button)  # Gold for Play
	_style_blue_button(gear_button)    # Blue for Gear
	_style_purple_button(shop_button)  # Purple for Upgrade
	_style_pink_button(princesses_button)  # Pink for Princesses

	# Update displays
	_update_coin_display()
	_update_curse_display()
	_create_version_label()

	# Play main menu music (1. Stolen Future)
	if SoundManager:
		SoundManager.play_menu_music()

func _update_curse_display() -> void:
	"""Show active curse count below play button (if any)."""
	if not PrincessManager:
		return

	var curse_count = PrincessManager.get_enabled_curse_count()
	if curse_count == 0:
		if curse_label:
			curse_label.visible = false
		return

	# Create label if not exists
	if curse_label == null:
		curse_label = Label.new()
		curse_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		curse_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
		curse_label.anchor_top = 0.92
		curse_label.anchor_bottom = 0.97
		curse_label.offset_left = 50
		curse_label.offset_right = -50
		if pixel_font:
			curse_label.add_theme_font_override("font", pixel_font)
		curse_label.add_theme_font_size_override("font_size", 12)
		curse_label.add_theme_color_override("font_color", Color.WHITE)
		curse_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		curse_label.add_theme_constant_override("shadow_offset_x", 2)
		curse_label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(curse_label)

	var multiplier = PrincessManager.get_total_bonus_multiplier()
	var mult_str = "%.1fx" % multiplier if fmod(multiplier, 1.0) != 0 else "%dx" % int(multiplier)
	curse_label.text = "%d Curse%s Active (%s Bonus)" % [curse_count, "s" if curse_count > 1 else "", mult_str]
	curse_label.visible = true

func _create_version_label() -> void:
	"""Create version/build label in bottom left corner."""
	version_label = Label.new()
	version_label.text = "v%s (Build %d)" % [VERSION, BUILD]
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_LEFT)
	version_label.offset_left = 110
	version_label.offset_bottom = -50
	version_label.offset_top = -70
	version_label.offset_right = 200
	if pixel_font:
		version_label.add_theme_font_override("font", pixel_font)
	version_label.add_theme_font_size_override("font_size", 10)
	version_label.add_theme_color_override("font_color", Color.WHITE)
	version_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	version_label.add_theme_constant_override("shadow_offset_x", 1)
	version_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(version_label)

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

func _on_princesses_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/princesses.tscn")

func _style_pink_button(button: Button) -> void:
	# Pink button for Princesses
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.75, 0.4, 0.6, 1)  # Pink
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 8
	style_normal.border_color = Color(0.4, 0.2, 0.35, 1)  # Dark pink
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.85, 0.5, 0.7, 1)  # Brighter pink
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 8
	style_hover.border_color = Color(0.45, 0.25, 0.4, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.6, 0.3, 0.5, 1)  # Darker pink
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 6
	style_pressed.border_width_bottom = 5
	style_pressed.border_color = Color(0.35, 0.15, 0.3, 1)
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
