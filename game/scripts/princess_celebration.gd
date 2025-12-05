extends Node2D

# Princess Celebration - Handles princess unlock animation after beating a challenge

# Signals
signal completed()

# Configuration
const WALK_SPEED: float = 80.0
const SPEECH_CHANGE_INTERVAL: float = 1.5
const APPROACH_DISTANCE: float = 100.0

# Speech bubble messages
const SPEECH_MESSAGES: Array[String] = [
	"YOU SAVED ME!",
	"MY HERO!",
	"WOW!",
	"YAY!",
	"THANK YOU!",
	"AMAZING!",
]

# State
var princess_id: String = ""
var princess_data = null
var player_ref: Node2D = null
var target_position: Vector2 = Vector2.ZERO
var walking: bool = true
var speech_timer: float = 0.0
var current_speech_index: int = 0
var modal_shown: bool = false
var waiting_for_player: bool = false  # Prevents multiple concurrent approach timers
var idle_time: float = 0.0  # Time spent waiting for player approach
const MAX_IDLE_TIME: float = 5.0  # Auto-show modal after 5 seconds of waiting
var animation_frame: int = 0
var animation_timer: float = 0.0
var animation_fps: float = 8.0

# UI elements
var princess_sprite: Sprite2D = null
var speech_bubble: Control = null
var speech_label: Label = null
var unlock_modal: CanvasLayer = null
var pixel_font: Font = null

func _ready() -> void:
	# Ensure this node processes even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func setup(p_princess_id: String, p_player: Node2D) -> void:
	"""Initialize the celebration with princess and player references."""
	princess_id = p_princess_id
	player_ref = p_player

	if not PrincessManager:
		push_error("PrincessManager not found!")
		completed.emit()
		queue_free()
		return

	princess_data = PrincessManager.get_princess(princess_id)
	if not princess_data:
		push_error("Princess not found: " + princess_id)
		completed.emit()
		queue_free()
		return

	# Get viewport center for target position
	var viewport_rect = get_viewport_rect()
	target_position = Vector2(viewport_rect.size.x / 2, viewport_rect.size.y / 2)

	# Create princess sprite at top center
	_create_princess_sprite()

	# Create speech bubble
	_create_speech_bubble()

	# Play celebration effects
	if JuiceManager:
		JuiceManager.shake_small()
	if HapticManager:
		HapticManager.light()

func _process(delta: float) -> void:
	if modal_shown:
		return

	# Update animation
	_update_animation(delta)

	if walking:
		_update_walking(delta)
	else:
		# Track idle time and auto-show modal after timeout
		idle_time += delta
		if idle_time >= MAX_IDLE_TIME:
			_show_unlock_modal()
			return
		_check_player_approach()

	# Update speech bubble
	_update_speech(delta)

func _update_animation(delta: float) -> void:
	animation_timer += delta
	if animation_timer >= 1.0 / animation_fps:
		animation_timer = 0.0
		animation_frame += 1

		# Get frame count for current animation
		var anim_name = "walk" if walking else "idle"
		var anim_info = PrincessManager.get_animation_info(princess_data.sprite_character, anim_name)
		animation_frame = animation_frame % anim_info["frames"]

		# Update sprite region
		_update_sprite_frame(anim_name)

func _update_sprite_frame(anim_name: String) -> void:
	if not princess_sprite:
		return

	var region = PrincessManager.get_sprite_region(
		princess_data.sprite_character,
		anim_name,
		animation_frame
	)
	princess_sprite.region_rect = region

func _update_walking(delta: float) -> void:
	# Move princess toward target
	var direction = (target_position - global_position).normalized()
	global_position += direction * WALK_SPEED * delta

	# Check if reached target
	if global_position.distance_to(target_position) < 5.0:
		walking = false
		global_position = target_position
		animation_frame = 0  # Reset to idle

func _check_player_approach() -> void:
	# Guard against multiple concurrent timers from being started
	if waiting_for_player:
		return

	if not player_ref or not is_instance_valid(player_ref):
		# If no player, show modal after a delay (only start one timer)
		waiting_for_player = true
		await get_tree().create_timer(2.0).timeout
		if not modal_shown:
			_show_unlock_modal()
		return

	var distance = global_position.distance_to(player_ref.global_position)
	if distance < APPROACH_DISTANCE:
		_show_unlock_modal()

func _update_speech(delta: float) -> void:
	speech_timer += delta
	if speech_timer >= SPEECH_CHANGE_INTERVAL:
		speech_timer = 0.0
		current_speech_index = (current_speech_index + 1) % SPEECH_MESSAGES.size()
		if speech_label:
			speech_label.text = SPEECH_MESSAGES[current_speech_index]

			# Pop animation
			var tween = create_tween()
			tween.tween_property(speech_bubble, "scale", Vector2(1.1, 1.1), 0.08)
			tween.tween_property(speech_bubble, "scale", Vector2(1.0, 1.0), 0.08)

func _create_princess_sprite() -> void:
	princess_sprite = Sprite2D.new()

	# Load sprite sheet
	var texture = PrincessManager.get_sprite_sheet()
	if texture:
		princess_sprite.texture = texture
		princess_sprite.region_enabled = true

		# Set initial frame (walk animation)
		var region = PrincessManager.get_sprite_region(princess_data.sprite_character, "walk", 0)
		princess_sprite.region_rect = region

	# Scale up for visibility (32x32 is small) - reduced 70% from original 3.0
	princess_sprite.scale = Vector2(0.9, 0.9)

	# Position at top center
	var viewport_rect = get_viewport_rect()
	global_position = Vector2(viewport_rect.size.x / 2, -50)

	add_child(princess_sprite)

func _create_speech_bubble() -> void:
	# Create a container for the speech bubble
	speech_bubble = Control.new()
	speech_bubble.set_anchors_preset(Control.PRESET_CENTER)
	speech_bubble.position = Vector2(0, -80)
	speech_bubble.z_index = 10

	# Background panel
	var panel = PanelContainer.new()
	var style = StyleBoxFlat.new()
	style.bg_color = Color(1, 1, 1, 0.95)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.2, 0.2)
	style.set_corner_radius_all(8)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	panel.add_theme_stylebox_override("panel", style)

	# Speech text
	speech_label = Label.new()
	speech_label.text = SPEECH_MESSAGES[0]
	speech_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		speech_label.add_theme_font_override("font", pixel_font)
	speech_label.add_theme_font_size_override("font_size", 14)
	speech_label.add_theme_color_override("font_color", Color(0.15, 0.15, 0.15))

	panel.add_child(speech_label)
	speech_bubble.add_child(panel)

	# Center the bubble above princess
	panel.position = Vector2(-panel.size.x / 2, 0)

	add_child(speech_bubble)

	# Animate bubble appearance
	speech_bubble.modulate.a = 0
	speech_bubble.scale = Vector2(0.5, 0.5)
	var tween = create_tween()
	tween.tween_property(speech_bubble, "modulate:a", 1.0, 0.3)
	tween.parallel().tween_property(speech_bubble, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK)

func _show_unlock_modal() -> void:
	if modal_shown:
		return
	modal_shown = true

	# Hide speech bubble
	if speech_bubble:
		var hide_tween = create_tween()
		hide_tween.tween_property(speech_bubble, "modulate:a", 0.0, 0.2)

	# Play effects
	if JuiceManager:
		JuiceManager.shake_medium()
	if HapticManager:
		HapticManager.heavy()
	if SoundManager and SoundManager.has_method("play_level_up"):
		SoundManager.play_level_up()

	# Create modal
	unlock_modal = CanvasLayer.new()
	unlock_modal.layer = 105
	unlock_modal.process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().root.add_child(unlock_modal)

	# Background
	var bg = ColorRect.new()
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.color = Color(0, 0, 0, 0.8)
	bg.mouse_filter = Control.MOUSE_FILTER_STOP
	unlock_modal.add_child(bg)

	# Main container
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_CENTER)
	container.grow_horizontal = Control.GROW_DIRECTION_BOTH
	container.grow_vertical = Control.GROW_DIRECTION_BOTH
	container.alignment = BoxContainer.ALIGNMENT_CENTER
	container.add_theme_constant_override("separation", 20)
	unlock_modal.add_child(container)

	# Title
	var title = Label.new()
	title.text = "PRINCESS UNLOCKED!"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		title.add_theme_font_override("font", pixel_font)
	title.add_theme_font_size_override("font_size", 38)
	title.add_theme_color_override("font_color", Color(1.0, 0.7, 0.85))
	title.add_theme_color_override("font_shadow_color", Color(0.4, 0.15, 0.25, 1.0))
	title.add_theme_constant_override("shadow_offset_x", 3)
	title.add_theme_constant_override("shadow_offset_y", 3)
	container.add_child(title)

	# Princess portrait
	var portrait_container = CenterContainer.new()
	var portrait = Sprite2D.new()
	var texture = PrincessManager.get_sprite_sheet()
	if texture:
		portrait.texture = texture
		portrait.region_enabled = true
		# Use idle animation first frame
		var region = PrincessManager.get_sprite_region(princess_data.sprite_character, "idle", 0)
		portrait.region_rect = region
	portrait.scale = Vector2(4.0, 4.0)

	# Add glow effect with modulate
	portrait.modulate = Color(1.2, 1.1, 1.2)

	var portrait_wrapper = Control.new()
	portrait_wrapper.custom_minimum_size = Vector2(128, 128)
	portrait_wrapper.add_child(portrait)
	portrait.position = Vector2(64, 64)  # Center in wrapper
	portrait_container.add_child(portrait_wrapper)
	container.add_child(portrait_container)

	# Princess name
	var name_label = Label.new()
	name_label.text = princess_data.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color(1.0, 0.95, 0.8))
	container.add_child(name_label)

	# Curse info panel
	var curse_panel = PanelContainer.new()
	var curse_style = StyleBoxFlat.new()
	curse_style.bg_color = Color(0.15, 0.12, 0.18, 0.9)
	curse_style.border_width_left = 2
	curse_style.border_width_right = 2
	curse_style.border_width_top = 2
	curse_style.border_width_bottom = 2
	curse_style.border_color = Color(0.5, 0.3, 0.5)
	curse_style.set_corner_radius_all(8)
	curse_style.content_margin_left = 20
	curse_style.content_margin_right = 20
	curse_style.content_margin_top = 15
	curse_style.content_margin_bottom = 15
	curse_panel.add_theme_stylebox_override("panel", curse_style)

	var curse_vbox = VBoxContainer.new()
	curse_vbox.add_theme_constant_override("separation", 8)

	var curse_name = Label.new()
	curse_name.text = "Problem: %s" % princess_data.curse_name
	curse_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		curse_name.add_theme_font_override("font", pixel_font)
	curse_name.add_theme_font_size_override("font_size", 16)
	curse_name.add_theme_color_override("font_color", Color(0.9, 0.5, 0.6))
	curse_vbox.add_child(curse_name)

	var curse_desc = Label.new()
	curse_desc.text = princess_data.curse_description
	curse_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	curse_desc.autowrap_mode = TextServer.AUTOWRAP_WORD
	curse_desc.custom_minimum_size = Vector2(300, 0)
	if pixel_font:
		curse_desc.add_theme_font_override("font", pixel_font)
	curse_desc.add_theme_font_size_override("font_size", 14)
	curse_desc.add_theme_color_override("font_color", Color(0.8, 0.8, 0.85))
	curse_vbox.add_child(curse_desc)

	var bonus_label = Label.new()
	bonus_label.text = "+.5x More Points & Coins"
	bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		bonus_label.add_theme_font_override("font", pixel_font)
	bonus_label.add_theme_font_size_override("font_size", 14)
	bonus_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	curse_vbox.add_child(bonus_label)

	curse_panel.add_child(curse_vbox)
	container.add_child(curse_panel)

	# Continue button
	var continue_btn = Button.new()
	continue_btn.text = "Continue"
	continue_btn.custom_minimum_size = Vector2(200, 50)
	continue_btn.pressed.connect(_on_continue_pressed)
	_style_button(continue_btn, Color(0.65, 0.4, 0.7))
	container.add_child(continue_btn)

	# Animate entry
	container.modulate.a = 0.0
	container.scale = Vector2(0.7, 0.7)
	container.pivot_offset = container.size / 2

	var tween = create_tween()
	tween.tween_property(container, "modulate:a", 1.0, 0.25)
	tween.parallel().tween_property(container, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

func _style_button(button: Button, color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 6
	style.border_color = color.darkened(0.4)
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = color.lightened(0.15)
	button.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = color.darkened(0.15)
	pressed.border_width_top = 5
	pressed.border_width_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 16)
	button.add_theme_color_override("font_color", Color.WHITE)

func _on_continue_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	# Clean up
	if unlock_modal:
		unlock_modal.queue_free()

	completed.emit()
	queue_free()
