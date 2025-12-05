extends CanvasLayer

# Play button (right side)
@onready var play_button: Button = $PlayButton

# Left side buttons - Vertical stack (Princesses, Library)
@onready var princesses_button: Button = $LeftButtonContainer/PrincessesButton
@onready var unlocks_button: Button = $LeftButtonContainer/UnlocksButton

# Left side buttons - Bottom row (Missions, Gear, Upgrade)
@onready var missions_button: Button = $LeftButtonContainer/BottomRow/MissionsButton
@onready var gear_button: Button = $LeftButtonContainer/BottomRow/GearButton
@onready var shop_button: Button = $LeftButtonContainer/BottomRow/ShopButton

@onready var coin_amount: Label = $CoinsBackground/CoinsDisplay/CoinAmount
@onready var settings_button: Button = $SettingsButton

var curse_label: Label = null
var version_label: Label = null
var pixel_font: Font = null
var settings_panel: Control = null
var confirmation_dialog: Control = null
var locked_message_label: Label = null

# Notification badges
var missions_badge: Control = null
var upgrade_badge: Control = null

# Button animation state
var animatable_buttons: Array[Button] = []
var button_animation_timer: Timer = null
var current_sweep_rect: ColorRect = null

const VERSION = "1.0.0"
const BUILD = 14

func _ready() -> void:
	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Connect button signals
	play_button.pressed.connect(_on_play_pressed)
	gear_button.pressed.connect(_on_gear_pressed)
	shop_button.pressed.connect(_on_shop_pressed)
	princesses_button.pressed.connect(_on_princesses_pressed)
	unlocks_button.pressed.connect(_on_unlocks_pressed)
	missions_button.pressed.connect(_on_missions_pressed)
	settings_button.pressed.connect(_on_settings_pressed)

	# Style settings button like home button with gear icon
	_style_settings_button()

	# Style buttons with different colors
	_style_bright_golden_button(play_button)  # Bright Gold for Play
	_style_pink_button_small(princesses_button)  # Pink for Princesses
	_style_teal_button_small(unlocks_button)  # Teal for Library
	_style_orange_button_small(missions_button)  # Orange for Missions
	_style_blue_button_small(gear_button)    # Blue for Gear
	_style_purple_button_small(shop_button)  # Purple for Upgrade

	# Check if princess button should be locked
	_update_princess_button_state()

	# Check if library button should be locked
	_update_library_button_state()

	# Update displays
	_update_coin_display()
	_update_curse_display()
	_create_version_label()

	# Play main menu music (1. Stolen Future)
	if SoundManager:
		SoundManager.play_menu_music()

	# Show daily login popup if reward available
	_check_daily_login()

	# Update notification badges
	_update_missions_badge()
	_update_upgrade_badge()

	# Setup button animation system
	_setup_button_animations()

func _setup_button_animations() -> void:
	"""Setup random button pulse and light sweep animations."""
	# Build list of animatable buttons
	animatable_buttons = [play_button, princesses_button, unlocks_button, missions_button, gear_button, shop_button]

	# Create timer for random button animations
	button_animation_timer = Timer.new()
	button_animation_timer.wait_time = randf_range(2.5, 4.5)
	button_animation_timer.one_shot = false
	button_animation_timer.timeout.connect(_animate_random_button)
	add_child(button_animation_timer)
	button_animation_timer.start()

	# Trigger first animation after a short delay
	await get_tree().create_timer(1.0).timeout
	_animate_random_button()

func _animate_random_button() -> void:
	"""Pick a random button and animate it with pulse and light sweep."""
	if animatable_buttons.is_empty():
		return

	# Pick random button
	var button = animatable_buttons[randi() % animatable_buttons.size()]

	# Don't animate if button text is "LOCKED"
	if button.text == "LOCKED":
		# Try another button
		var unlocked_buttons = animatable_buttons.filter(func(b): return b.text != "LOCKED")
		if unlocked_buttons.is_empty():
			return
		button = unlocked_buttons[randi() % unlocked_buttons.size()]

	# Randomize next animation time
	button_animation_timer.wait_time = randf_range(2.5, 4.5)

	# Run both animations
	_pulse_button(button)
	_sweep_light_on_button(button)

func _pulse_button(button: Button) -> void:
	"""Subtle pulse animation on a button."""
	button.pivot_offset = button.size / 2
	var tween = create_tween()
	tween.tween_property(button, "scale", Vector2(1.03, 1.03), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT)

func _sweep_light_on_button(button: Button) -> void:
	"""Create a light sweep effect that moves from left to right across the button."""
	# Remove existing sweep if any
	if current_sweep_rect and is_instance_valid(current_sweep_rect):
		current_sweep_rect.queue_free()

	# Create sweep rect
	var sweep = ColorRect.new()
	sweep.color = Color(1.0, 1.0, 1.0, 0.25)
	sweep.size = Vector2(40, button.size.y + 10)
	sweep.position = Vector2(-50, -5)
	sweep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sweep.z_index = 10

	# Use a gradient for the sweep
	var gradient_rect = ColorRect.new()
	gradient_rect.size = sweep.size
	gradient_rect.position = Vector2.ZERO
	gradient_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Apply a shader or just use multiple color rects for gradient effect
	# Simpler approach: use modulate for fade effect
	sweep.modulate = Color(1, 1, 1, 0)

	button.clip_contents = true
	button.add_child(sweep)
	current_sweep_rect = sweep

	# Animate the sweep from left to right
	var tween = create_tween()
	tween.tween_property(sweep, "modulate:a", 0.3, 0.1)
	tween.tween_property(sweep, "position:x", button.size.x + 20, 0.4).set_ease(Tween.EASE_IN_OUT)
	tween.parallel().tween_property(sweep, "modulate:a", 0.0, 0.2).set_delay(0.25)
	tween.tween_callback(func():
		if is_instance_valid(sweep):
			sweep.queue_free()
		if current_sweep_rect == sweep:
			current_sweep_rect = null
		# Reset clip_contents to allow badges to show outside button bounds
		if is_instance_valid(button):
			button.clip_contents = false
	)

func _update_princess_button_state() -> void:
	"""Lock/unlock princess button based on challenge progress."""
	if not PrincessManager:
		return

	var has_beaten_challenge = PrincessManager.has_beaten_any_challenge()
	# Keep button enabled so click shows message

	if not has_beaten_challenge:
		# Style as locked
		_style_locked_button_small(princesses_button)
		princesses_button.text = "LOCKED"
	else:
		# Restore normal pink style
		_style_pink_button_small(princesses_button)
		princesses_button.text = "PRINCESSES"

func _style_locked_button_small(button: Button) -> void:
	"""Style a button as locked/disabled (small version)."""
	var style_disabled = StyleBoxFlat.new()
	style_disabled.bg_color = Color(0.3, 0.3, 0.3, 1)  # Gray
	style_disabled.border_width_left = 2
	style_disabled.border_width_right = 2
	style_disabled.border_width_top = 2
	style_disabled.border_width_bottom = 5
	style_disabled.border_color = Color(0.2, 0.2, 0.2, 1)  # Dark gray
	style_disabled.corner_radius_top_left = 5
	style_disabled.corner_radius_top_right = 5
	style_disabled.corner_radius_bottom_left = 5
	style_disabled.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", style_disabled)
	button.add_theme_stylebox_override("hover", style_disabled)
	button.add_theme_stylebox_override("pressed", style_disabled)
	button.add_theme_stylebox_override("disabled", style_disabled)
	button.add_theme_stylebox_override("focus", style_disabled)
	button.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5, 1))
	button.add_theme_color_override("font_disabled_color", Color(0.5, 0.5, 0.5, 1))

func _update_library_button_state() -> void:
	"""Lock/unlock library button based on having any achievement."""
	var has_any_achievement = false

	# Check if player has completed any mission/achievement
	if MissionsManager:
		has_any_achievement = MissionsManager.get_completed_count() > 0

	# Also check if player has beaten any difficulty
	if not has_any_achievement and DifficultyManager:
		has_any_achievement = DifficultyManager.completed_difficulties.size() > 0

	# Keep button enabled so click shows message

	if not has_any_achievement:
		# Style as locked
		_style_locked_button_small(unlocks_button)
		unlocks_button.text = "LOCKED"
	else:
		# Restore normal teal style
		_style_teal_button_small(unlocks_button)
		unlocks_button.text = "LIBRARY"

func _show_locked_message(message: String) -> void:
	"""Show a temporary message when clicking a locked button."""
	# Remove existing message if any
	if locked_message_label:
		locked_message_label.queue_free()

	locked_message_label = Label.new()
	locked_message_label.text = message
	locked_message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	locked_message_label.set_anchors_preset(Control.PRESET_CENTER)
	locked_message_label.offset_left = -250
	locked_message_label.offset_right = 250
	locked_message_label.offset_top = 150
	locked_message_label.offset_bottom = 200
	if pixel_font:
		locked_message_label.add_theme_font_override("font", pixel_font)
	locked_message_label.add_theme_font_size_override("font_size", 16)
	locked_message_label.add_theme_color_override("font_color", Color(1, 0.8, 0.3))
	locked_message_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	locked_message_label.add_theme_constant_override("shadow_offset_x", 2)
	locked_message_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(locked_message_label)

	# Fade out after 2 seconds
	var tween = create_tween()
	tween.tween_interval(1.5)
	tween.tween_property(locked_message_label, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func():
		if locked_message_label:
			locked_message_label.queue_free()
			locked_message_label = null
	)

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
		curse_label.add_theme_font_size_override("font_size", 14)
		curse_label.add_theme_color_override("font_color", Color.WHITE)
		curse_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
		curse_label.add_theme_constant_override("shadow_offset_x", 2)
		curse_label.add_theme_constant_override("shadow_offset_y", 2)
		add_child(curse_label)

	var bonus_percent = PrincessManager.get_total_bonus_percent()
	curse_label.text = "%d Curse%s Active (+%d%% Bonus)" % [curse_count, "s" if curse_count > 1 else "", bonus_percent]
	curse_label.visible = true

func _create_version_label() -> void:
	"""Create version/build label in bottom center."""
	version_label = Label.new()
	version_label.text = "v%s (Build %d)" % [VERSION, BUILD]
	version_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	version_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	version_label.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	version_label.offset_left = 0
	version_label.offset_right = 0
	version_label.offset_bottom = -30
	version_label.offset_top = -50
	if pixel_font:
		version_label.add_theme_font_override("font", pixel_font)
	version_label.add_theme_font_size_override("font_size", 10)
	version_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 0.8))
	version_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	version_label.add_theme_constant_override("shadow_offset_x", 1)
	version_label.add_theme_constant_override("shadow_offset_y", 1)
	add_child(version_label)

func _style_golden_button(button: Button) -> void:
	# Standard golden button for dialogs
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.85, 0.65, 0.2, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.border_color = Color(0.45, 0.3, 0.15, 1)
	style_normal.set_corner_radius_all(6)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.92, 0.72, 0.25, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 5
	style_hover.border_color = Color(0.5, 0.35, 0.18, 1)
	style_hover.set_corner_radius_all(6)

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

func _style_bright_golden_button(button: Button) -> void:
	# Bright golden/yellow button for PLAY - more vibrant
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(1.0, 0.85, 0.2, 1)  # Bright golden yellow
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.6, 0.45, 0.1, 1)  # Dark gold border
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(1.0, 0.92, 0.4, 1)  # Even brighter on hover
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.65, 0.5, 0.15, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.9, 0.75, 0.15, 1)  # Darker when pressed
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 5
	style_pressed.border_width_bottom = 4
	style_pressed.border_color = Color(0.5, 0.35, 0.08, 1)
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(0.15, 0.1, 0.0, 1))
	button.add_theme_color_override("font_hover_color", Color(0.1, 0.05, 0.0, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.2, 0.15, 0.05, 1))

func _style_blue_button_small(button: Button) -> void:
	# Blue button for Gear (smaller)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.3, 0.5, 0.75, 1)  # Steel blue
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.border_color = Color(0.15, 0.25, 0.4, 1)  # Dark blue
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5
	style_normal.corner_radius_bottom_right = 5

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.4, 0.6, 0.85, 1)  # Brighter blue
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 5
	style_hover.border_color = Color(0.2, 0.3, 0.5, 1)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.corner_radius_bottom_right = 5

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.25, 0.4, 0.6, 1)  # Darker blue
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color(0.1, 0.2, 0.35, 1)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_left = 5
	style_pressed.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(0.95, 0.95, 1.0, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.8, 0.85, 0.95, 1))

func _style_purple_button_small(button: Button) -> void:
	# Purple button for Upgrade (smaller)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.55, 0.3, 0.7, 1)  # Purple
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.border_color = Color(0.3, 0.15, 0.4, 1)  # Dark purple
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5
	style_normal.corner_radius_bottom_right = 5

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.65, 0.4, 0.8, 1)  # Brighter purple
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 5
	style_hover.border_color = Color(0.35, 0.2, 0.45, 1)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.corner_radius_bottom_right = 5

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.45, 0.25, 0.55, 1)  # Darker purple
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color(0.25, 0.1, 0.35, 1)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_left = 5
	style_pressed.corner_radius_bottom_right = 5

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
	# Mark that user has seen upgrades - clear the badge
	_mark_upgrades_seen()
	get_tree().change_scene_to_file("res://scenes/shop.tscn")

func _on_princesses_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	# Check if locked
	if not PrincessManager or not PrincessManager.has_beaten_any_challenge():
		_show_locked_message("Beat Pitiful difficulty to unlock")
		return

	get_tree().change_scene_to_file("res://scenes/princesses.tscn")

func _on_unlocks_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	# Check if locked
	var has_any_achievement = false
	if MissionsManager:
		has_any_achievement = MissionsManager.get_completed_count() > 0
	if not has_any_achievement and DifficultyManager:
		has_any_achievement = DifficultyManager.completed_difficulties.size() > 0

	if not has_any_achievement:
		_show_locked_message("Progress further to unlock")
		return

	get_tree().change_scene_to_file("res://scenes/unlocks.tscn")

func _on_missions_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/missions.tscn")

func _style_teal_button_small(button: Button) -> void:
	# Teal/green button for Library (smaller)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.2, 0.6, 0.55, 1)  # Teal
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.border_color = Color(0.1, 0.3, 0.28, 1)  # Dark teal
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5
	style_normal.corner_radius_bottom_right = 5

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.3, 0.7, 0.65, 1)  # Brighter teal
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 5
	style_hover.border_color = Color(0.15, 0.35, 0.33, 1)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.corner_radius_bottom_right = 5

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.15, 0.5, 0.45, 1)  # Darker teal
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color(0.08, 0.25, 0.22, 1)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_left = 5
	style_pressed.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(0.95, 1, 0.95, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.85, 0.95, 0.9, 1))

func _style_pink_button_small(button: Button) -> void:
	# Pink button for Princesses (smaller)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.75, 0.4, 0.6, 1)  # Pink
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.border_color = Color(0.4, 0.2, 0.35, 1)  # Dark pink
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5
	style_normal.corner_radius_bottom_right = 5

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.85, 0.5, 0.7, 1)  # Brighter pink
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 5
	style_hover.border_color = Color(0.45, 0.25, 0.4, 1)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.corner_radius_bottom_right = 5

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.6, 0.3, 0.5, 1)  # Darker pink
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color(0.35, 0.15, 0.3, 1)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_left = 5
	style_pressed.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(1, 0.95, 1, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.9, 0.85, 0.95, 1))

func _style_settings_button() -> void:
	# Add gear icon from StonePixel spritesheet (row 2, col 1 = position 0,32)
	var icons_texture = load("res://assets/sprites/icons/StonePixel/Icons/32x32.png")
	if icons_texture:
		var atlas = AtlasTexture.new()
		atlas.atlas = icons_texture
		atlas.region = Rect2(0, 32, 32, 32)  # col 0, row 1 (gear icon)

		var icon_rect = TextureRect.new()
		icon_rect.texture = atlas
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

		var center = CenterContainer.new()
		center.set_anchors_preset(Control.PRESET_FULL_RECT)
		center.add_child(icon_rect)
		settings_button.add_child(center)

	# Style the button - light brown/beige background (same as home button)
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.76, 0.60, 0.42, 0.95)
	style.set_corner_radius_all(8)
	settings_button.add_theme_stylebox_override("normal", style)

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.82, 0.68, 0.50, 0.95)
	style_hover.set_corner_radius_all(8)
	settings_button.add_theme_stylebox_override("hover", style_hover)

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.65, 0.50, 0.35, 0.95)
	style_pressed.set_corner_radius_all(8)
	settings_button.add_theme_stylebox_override("pressed", style_pressed)
	settings_button.add_theme_stylebox_override("focus", style)

# ============================================
# SETTINGS PANEL
# ============================================

func _on_settings_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	_show_settings_panel()

func _show_settings_panel() -> void:
	if settings_panel:
		settings_panel.visible = true
		return

	# Create settings panel
	settings_panel = Control.new()
	settings_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(settings_panel)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.92)
	settings_panel.add_child(overlay)

	# Panel background
	var panel_bg = ColorRect.new()
	panel_bg.set_anchors_preset(Control.PRESET_CENTER)
	panel_bg.custom_minimum_size = Vector2(400, 600)
	panel_bg.offset_left = -200
	panel_bg.offset_top = -300
	panel_bg.offset_right = 200
	panel_bg.offset_bottom = 300
	panel_bg.color = Color(0.15, 0.12, 0.1, 0.95)
	settings_panel.add_child(panel_bg)

	# Title
	var title = Label.new()
	title.text = "OPTIONS"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.set_anchors_preset(Control.PRESET_CENTER)
	title.offset_left = -180
	title.offset_top = -280
	title.offset_right = 180
	title.offset_bottom = -250
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 26)
	title.add_theme_color_override("font_color", Color.WHITE)
	settings_panel.add_child(title)

	# Scroll container for options
	var scroll_container = ScrollContainer.new()
	scroll_container.set_anchors_preset(Control.PRESET_CENTER)
	scroll_container.offset_left = -170
	scroll_container.offset_top = -230
	scroll_container.offset_right = 170
	scroll_container.offset_bottom = 200
	scroll_container.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll_container.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	settings_panel.add_child(scroll_container)

	# Options container inside scroll
	var options_container = VBoxContainer.new()
	options_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	options_container.add_theme_constant_override("separation", 20)
	scroll_container.add_child(options_container)

	# Music toggle
	_create_toggle_option(options_container, "Music", GameSettings.music_enabled, func(toggled): GameSettings.set_music_enabled(toggled))

	# SFX toggle
	_create_toggle_option(options_container, "Sound Effects", GameSettings.sfx_enabled, func(toggled): GameSettings.set_sfx_enabled(toggled))

	# Haptics toggle
	_create_toggle_option(options_container, "Haptics", GameSettings.haptics_enabled, func(toggled): GameSettings.set_haptics_enabled(toggled))

	# Screen shake toggle
	_create_toggle_option(options_container, "Screen Shake", GameSettings.screen_shake_enabled, func(toggled): GameSettings.set_screen_shake_enabled(toggled))

	# Damage numbers toggle
	_create_toggle_option(options_container, "Damage Numbers", GameSettings.damage_numbers_enabled, func(toggled): GameSettings.set_damage_numbers_enabled(toggled))

	# Freeze frames toggle (hitstop effects)
	_create_toggle_option(options_container, "Freeze Frames", GameSettings.freeze_frames_enabled, func(toggled): GameSettings.set_freeze_frames_enabled(toggled))

	# Status text toggle (BURN, POISON, etc. over enemies)
	_create_toggle_option(options_container, "Status Text", GameSettings.status_text_enabled, func(toggled): GameSettings.set_status_text_enabled(toggled))

	# Visual effects toggle (tinting, chromatic aberration, etc.)
	_create_toggle_option(options_container, "Visual Effects", GameSettings.visual_effects_enabled, func(toggled): GameSettings.set_visual_effects_enabled(toggled))

	# Track missions toggle
	_create_toggle_option(options_container, "Track Missions", GameSettings.track_missions_enabled, func(toggled): GameSettings.set_track_missions_enabled(toggled))

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 20)
	options_container.add_child(spacer)

	# Reset progress button
	var reset_button = Button.new()
	reset_button.text = "RESET PROGRESS"
	reset_button.custom_minimum_size = Vector2(300, 50)
	if pixel_font:
		reset_button.add_theme_font_override("font", pixel_font)
	reset_button.add_theme_font_size_override("font_size", 14)
	_style_red_button(reset_button)
	reset_button.pressed.connect(_on_reset_progress_pressed)
	options_container.add_child(reset_button)

	# Close button
	var close_button = Button.new()
	close_button.text = "CLOSE"
	close_button.custom_minimum_size = Vector2(200, 50)
	close_button.set_anchors_preset(Control.PRESET_CENTER)
	close_button.offset_left = -100
	close_button.offset_top = 220
	close_button.offset_right = 100
	close_button.offset_bottom = 270
	if pixel_font:
		close_button.add_theme_font_override("font", pixel_font)
	close_button.add_theme_font_size_override("font_size", 16)
	_style_golden_button(close_button)
	close_button.pressed.connect(_hide_settings_panel)
	settings_panel.add_child(close_button)

func _create_toggle_option(container: VBoxContainer, label_text: String, initial_value: bool, on_toggle: Callable) -> void:
	var hbox = HBoxContainer.new()
	hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_child(hbox)

	var label = Label.new()
	label.text = label_text
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 14)
	label.add_theme_color_override("font_color", Color.WHITE)
	hbox.add_child(label)

	var toggle = CheckButton.new()
	toggle.button_pressed = initial_value
	toggle.toggled.connect(on_toggle)
	hbox.add_child(toggle)

func _style_red_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.7, 0.2, 0.2, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 6
	style_normal.border_color = Color(0.4, 0.1, 0.1, 1)
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.85, 0.25, 0.25, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 6
	style_hover.border_color = Color(0.5, 0.15, 0.15, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color.WHITE)

func _hide_settings_panel() -> void:
	if SoundManager:
		SoundManager.play_click()
	if settings_panel:
		settings_panel.visible = false

func _on_reset_progress_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	_show_confirmation_dialog()

func _show_confirmation_dialog() -> void:
	if confirmation_dialog:
		confirmation_dialog.visible = true
		return

	confirmation_dialog = Control.new()
	confirmation_dialog.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(confirmation_dialog)

	# Dark overlay
	var overlay = ColorRect.new()
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.9)
	confirmation_dialog.add_child(overlay)

	# Dialog background
	var dialog_bg = ColorRect.new()
	dialog_bg.set_anchors_preset(Control.PRESET_CENTER)
	dialog_bg.custom_minimum_size = Vector2(380, 220)
	dialog_bg.offset_left = -190
	dialog_bg.offset_top = -110
	dialog_bg.offset_right = 190
	dialog_bg.offset_bottom = 110
	dialog_bg.color = Color(0.2, 0.15, 0.12, 0.98)
	confirmation_dialog.add_child(dialog_bg)

	# Warning text
	var warning = Label.new()
	warning.text = "RESET ALL PROGRESS?"
	warning.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	warning.set_anchors_preset(Control.PRESET_CENTER)
	warning.offset_left = -170
	warning.offset_top = -90
	warning.offset_right = 170
	warning.offset_bottom = -60
	if pixel_font:
		warning.add_theme_font_override("font", pixel_font)
	warning.add_theme_font_size_override("font_size", 18)
	warning.add_theme_color_override("font_color", Color(1, 0.3, 0.3))
	confirmation_dialog.add_child(warning)

	# Description
	var desc = Label.new()
	desc.text = "This will delete all coins,\nitems, and unlocks.\nThis cannot be undone!"
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.set_anchors_preset(Control.PRESET_CENTER)
	desc.offset_left = -170
	desc.offset_top = -40
	desc.offset_right = 170
	desc.offset_bottom = 30
	if pixel_font:
		desc.add_theme_font_override("font", pixel_font)
	desc.add_theme_font_size_override("font_size", 12)
	desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	confirmation_dialog.add_child(desc)

	# Button container
	var button_container = HBoxContainer.new()
	button_container.set_anchors_preset(Control.PRESET_CENTER)
	button_container.offset_left = -160
	button_container.offset_top = 40
	button_container.offset_right = 160
	button_container.offset_bottom = 90
	button_container.add_theme_constant_override("separation", 20)
	confirmation_dialog.add_child(button_container)

	# Cancel button
	var cancel_button = Button.new()
	cancel_button.text = "CANCEL"
	cancel_button.custom_minimum_size = Vector2(140, 50)
	if pixel_font:
		cancel_button.add_theme_font_override("font", pixel_font)
	cancel_button.add_theme_font_size_override("font_size", 14)
	_style_golden_button(cancel_button)
	cancel_button.pressed.connect(_hide_confirmation_dialog)
	button_container.add_child(cancel_button)

	# Confirm button
	var confirm_button = Button.new()
	confirm_button.text = "RESET"
	confirm_button.custom_minimum_size = Vector2(140, 50)
	if pixel_font:
		confirm_button.add_theme_font_override("font", pixel_font)
	confirm_button.add_theme_font_size_override("font_size", 14)
	_style_red_button(confirm_button)
	confirm_button.pressed.connect(_confirm_reset_progress)
	button_container.add_child(confirm_button)

func _hide_confirmation_dialog() -> void:
	if SoundManager:
		SoundManager.play_click()
	if confirmation_dialog:
		confirmation_dialog.visible = false

func _confirm_reset_progress() -> void:
	if SoundManager:
		SoundManager.play_click()

	# Reset all progress
	if StatsManager:
		StatsManager.reset_all_progress()

	if DifficultyManager:
		DifficultyManager.debug_reset_progress()

	if EquipmentManager:
		EquipmentManager.reset_all_equipment()

	if PermanentUpgrades:
		PermanentUpgrades.reset_all_upgrades()

	if PrincessManager:
		PrincessManager.reset_all_princesses()

	if UnlocksManager:
		UnlocksManager.reset_all_unlocks()

	# Hide dialogs and refresh display
	_hide_confirmation_dialog()
	_hide_settings_panel()
	_update_coin_display()
	_update_princess_button_state()
	_update_curse_display()

	# Reset missions too
	if MissionsManager:
		MissionsManager.reset_all_progress()
	if DailyLoginManager:
		DailyLoginManager.reset_all_data()

func _style_orange_button_small(button: Button) -> void:
	# Orange button for Missions (smaller)
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.9, 0.55, 0.2, 1)  # Orange
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 5
	style_normal.border_color = Color(0.5, 0.3, 0.1, 1)  # Dark orange
	style_normal.corner_radius_top_left = 5
	style_normal.corner_radius_top_right = 5
	style_normal.corner_radius_bottom_left = 5
	style_normal.corner_radius_bottom_right = 5

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.95, 0.65, 0.3, 1)  # Brighter orange
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 5
	style_hover.border_color = Color(0.55, 0.35, 0.15, 1)
	style_hover.corner_radius_top_left = 5
	style_hover.corner_radius_top_right = 5
	style_hover.corner_radius_bottom_left = 5
	style_hover.corner_radius_bottom_right = 5

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.8, 0.45, 0.15, 1)  # Darker orange
	style_pressed.border_width_left = 2
	style_pressed.border_width_right = 2
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 3
	style_pressed.border_color = Color(0.45, 0.25, 0.08, 1)
	style_pressed.corner_radius_top_left = 5
	style_pressed.corner_radius_top_right = 5
	style_pressed.corner_radius_bottom_left = 5
	style_pressed.corner_radius_bottom_right = 5

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)
	button.add_theme_color_override("font_color", Color(1, 0.98, 0.95, 1))
	button.add_theme_color_override("font_hover_color", Color(1, 1, 1, 1))
	button.add_theme_color_override("font_pressed_color", Color(0.95, 0.9, 0.85, 1))

func _check_daily_login() -> void:
	"""Check if daily login popup should be shown."""
	if not DailyLoginManager:
		return

	if DailyLoginManager.can_claim_reward():
		# Show daily login popup
		var popup_scene = load("res://scenes/daily_login_popup.tscn")
		if popup_scene:
			var popup = popup_scene.instantiate()
			add_child(popup)
			popup.show_popup()
			popup.closed.connect(func():
				_update_coin_display()
				_update_missions_badge()
			)

func _update_missions_badge() -> void:
	"""Update missions button to show red circle badge if rewards available."""
	# Remove existing badge
	if missions_badge:
		missions_badge.queue_free()
		missions_badge = null

	if not MissionsManager:
		return

	var unclaimed = MissionsManager.get_unclaimed_count()
	if unclaimed > 0:
		missions_badge = _create_notification_badge(unclaimed)
		missions_button.add_child(missions_badge)

func _update_upgrade_badge() -> void:
	"""Show red dot on upgrade button if user can afford new upgrades."""
	# Remove existing badge
	if upgrade_badge:
		upgrade_badge.queue_free()
		upgrade_badge = null

	if not PermanentUpgrades or not StatsManager:
		return

	# Check if user should see the badge
	if not _should_show_upgrade_badge():
		return

	# Check if any upgrade is affordable
	var can_afford_any = false
	for upgrade in PermanentUpgrades.get_all_upgrades():
		if PermanentUpgrades.can_purchase(upgrade.id):
			can_afford_any = true
			break

	if can_afford_any:
		upgrade_badge = _create_notification_badge(0)  # 0 = just show dot, no number
		shop_button.add_child(upgrade_badge)

func _should_show_upgrade_badge() -> bool:
	"""Check if upgrade badge should be shown (new coins earned since last shop visit)."""
	if not GameSettings or not StatsManager:
		return false

	var last_seen_coins = GameSettings.get_setting("last_shop_coins", -1)

	# First time - show badge if player has any coins
	if last_seen_coins == -1:
		return StatsManager.spendable_coins > 0

	# Show badge if we have more coins than when we last visited shop
	return StatsManager.spendable_coins > last_seen_coins

func _mark_upgrades_seen() -> void:
	"""Mark that user has visited the shop - hide badge until new coins earned."""
	if GameSettings and StatsManager:
		GameSettings.set_setting("last_shop_coins", StatsManager.spendable_coins)

func _create_notification_badge(count: int) -> Control:
	"""Create a red circle notification badge with optional white number."""
	var badge = Control.new()

	# Position in top-right corner of button - bigger size
	badge.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	badge.offset_left = -18
	badge.offset_right = 18
	badge.offset_top = -12
	badge.offset_bottom = 24

	# Red circle background with border for better visibility
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.95, 0.15, 0.15, 1.0)
	style.set_corner_radius_all(18)  # Fully rounded
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.5, 0.05, 0.05, 1.0)

	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.add_theme_stylebox_override("panel", style)
	badge.add_child(panel)

	# Add white number if count > 0, or white dot if count == 0
	if count > 0:
		var label = Label.new()
		label.text = str(count) if count < 100 else "99+"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.set_anchors_preset(Control.PRESET_FULL_RECT)
		if pixel_font:
			label.add_theme_font_override("font", pixel_font)
		label.add_theme_font_size_override("font_size", 14)
		label.add_theme_color_override("font_color", Color.WHITE)
		label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		label.add_theme_constant_override("shadow_offset_x", 1)
		label.add_theme_constant_override("shadow_offset_y", 1)
		badge.add_child(label)

		# Adjust badge size based on number width
		if count >= 10:
			badge.offset_left = -24
			badge.offset_right = 24
	else:
		# Add small white circle inside the red dot
		var inner_circle = PanelContainer.new()
		inner_circle.set_anchors_preset(Control.PRESET_CENTER)
		inner_circle.offset_left = -5
		inner_circle.offset_right = 5
		inner_circle.offset_top = -5
		inner_circle.offset_bottom = 5
		var inner_style = StyleBoxFlat.new()
		inner_style.bg_color = Color(1.0, 1.0, 1.0, 0.9)
		inner_style.set_corner_radius_all(5)  # Fully rounded
		inner_circle.add_theme_stylebox_override("panel", inner_style)
		badge.add_child(inner_circle)

	return badge
