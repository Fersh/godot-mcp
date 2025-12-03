extends CanvasLayer

# Continue screen shown once per run when player dies
# Features archangel animation descending to offer revival

signal continue_chosen(accepted: bool)

# Archangel sprite configuration
const FRAME_SIZE := Vector2(96, 96)
const ROW_APPEAR := 0
const ROW_IDLE := 1
const ROW_MOVEMENT := 2
const ROW_CAST := 3
const ROW_ATTACK := 4
const ROW_DAMAGE := 5
const ROW_DISAPPEAR := 6

const FRAME_COUNTS := {
	ROW_APPEAR: 7,
	ROW_IDLE: 8,
	ROW_MOVEMENT: 8,
	ROW_CAST: 8,
	ROW_ATTACK: 4,
	ROW_DAMAGE: 8,
	ROW_DISAPPEAR: 7
}

const ANIMATION_SPEED := 12.0  # Frames per second

# References
var overlay: ColorRect
var archangel_sprite: Sprite2D
var continue_label: Label
var button_container: HBoxContainer
var yes_button: Button
var no_button: Button

var pixel_font: Font = null
var archangel_texture: Texture2D = null

# Animation state
var current_row: int = ROW_APPEAR
var current_frame: float = 0.0
var is_animating: bool = true
var animation_phase: String = "descend"  # descend, appear, idle, cast, disappear

# Position
var target_position: Vector2 = Vector2.ZERO
var player_ref: Node2D = null

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100  # Above everything
	add_to_group("continue_screen_ui")

	# Load resources
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	if ResourceLoader.exists("res://assets/sprites/Archangel Sprite Sheet.png"):
		archangel_texture = load("res://assets/sprites/Archangel Sprite Sheet.png")

	_create_ui()
	_start_animation()

func setup(player: Node2D) -> void:
	"""Setup with reference to player for positioning."""
	player_ref = player
	if player:
		# Position above the player
		target_position = player.global_position + Vector2(0, -80)

func _create_ui() -> void:
	# Semi-transparent dark overlay
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)  # Start transparent, fade in
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(overlay)

	# Create a Control node to hold the sprite (for proper positioning)
	var sprite_container = Control.new()
	sprite_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(sprite_container)

	# Archangel sprite
	archangel_sprite = Sprite2D.new()
	if archangel_texture:
		archangel_sprite.texture = archangel_texture
		archangel_sprite.hframes = 8  # Max frames in any row
		archangel_sprite.vframes = 7  # 7 rows
		archangel_sprite.frame = 0
	archangel_sprite.scale = Vector2(3.0, 3.0)  # Scale up for visibility
	archangel_sprite.modulate.a = 0  # Start invisible
	sprite_container.add_child(archangel_sprite)

	# Center container for text and buttons
	var center_container = CenterContainer.new()
	center_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_container)

	var vbox = VBoxContainer.new()
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_theme_constant_override("separation", 30)
	center_container.add_child(vbox)

	# Spacer to push content down a bit
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 150)
	vbox.add_child(spacer)

	# "CONTINUE?" label
	continue_label = Label.new()
	continue_label.text = "CONTINUE?"
	continue_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	continue_label.add_theme_font_size_override("font_size", 50)
	continue_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))  # Golden
	continue_label.add_theme_color_override("font_shadow_color", Color(0.4, 0.2, 0.0))
	continue_label.add_theme_constant_override("shadow_offset_x", 4)
	continue_label.add_theme_constant_override("shadow_offset_y", 4)
	if pixel_font:
		continue_label.add_theme_font_override("font", pixel_font)
	continue_label.modulate.a = 0  # Start invisible
	vbox.add_child(continue_label)

	# Button container
	button_container = HBoxContainer.new()
	button_container.alignment = BoxContainer.ALIGNMENT_CENTER
	button_container.add_theme_constant_override("separation", 40)
	button_container.modulate.a = 0  # Start invisible
	vbox.add_child(button_container)

	# YES button
	yes_button = Button.new()
	yes_button.text = "YES"
	yes_button.custom_minimum_size = Vector2(150, 60)
	yes_button.pressed.connect(_on_yes_pressed)
	_style_button(yes_button, Color(0.2, 0.7, 0.3), Color(0.1, 0.5, 0.2))
	button_container.add_child(yes_button)

	# NO button
	no_button = Button.new()
	no_button.text = "NO"
	no_button.custom_minimum_size = Vector2(150, 60)
	no_button.pressed.connect(_on_no_pressed)
	_style_button(no_button, Color(0.7, 0.2, 0.2), Color(0.5, 0.1, 0.1))
	button_container.add_child(no_button)

func _style_button(button: Button, bg_color: Color, border_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = bg_color
	style.border_color = border_color
	style.set_border_width_all(4)
	style.set_corner_radius_all(8)
	button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = bg_color.lightened(0.2)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = bg_color.darkened(0.2)
	button.add_theme_stylebox_override("pressed", pressed_style)

	button.add_theme_font_size_override("font_size", 26)
	button.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		button.add_theme_font_override("font", pixel_font)

func _start_animation() -> void:
	"""Start the archangel descend and appear sequence."""
	animation_phase = "descend"

	# Pause the game
	get_tree().paused = true

	# Fade in overlay
	var overlay_tween = create_tween()
	overlay_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	overlay_tween.tween_property(overlay, "color:a", 0.7, 0.5)

	# Position archangel above screen, then descend
	var viewport_size = get_viewport().get_visible_rect().size
	var center_x = viewport_size.x / 2

	# Start position (above screen)
	archangel_sprite.position = Vector2(center_x, -100)
	archangel_sprite.modulate.a = 1.0

	# Target position (upper-center of screen)
	var end_y = viewport_size.y * 0.3

	# Descend animation
	var descend_tween = create_tween()
	descend_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	descend_tween.tween_property(archangel_sprite, "position:y", end_y, 1.0).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	descend_tween.tween_callback(_on_descend_complete)

	# Play movement animation during descend
	current_row = ROW_MOVEMENT
	current_frame = 0

func _on_descend_complete() -> void:
	"""Called when archangel finishes descending."""
	animation_phase = "appear"
	current_row = ROW_APPEAR
	current_frame = 0

func _process(delta: float) -> void:
	if not is_animating:
		return

	# Animate sprite
	current_frame += delta * ANIMATION_SPEED
	var frame_count = FRAME_COUNTS.get(current_row, 8)

	if current_frame >= frame_count:
		# Animation loop/transition
		match animation_phase:
			"descend":
				current_frame = fmod(current_frame, frame_count)
			"appear":
				# After appear, go to idle
				animation_phase = "idle"
				current_row = ROW_IDLE
				current_frame = 0
				_show_ui()
			"idle":
				current_frame = fmod(current_frame, frame_count)
			"cast":
				# After cast, go to disappear
				animation_phase = "disappear_yes"
				current_row = ROW_DISAPPEAR
				current_frame = 0
			"disappear_yes":
				is_animating = false
				_finish_continue(true)
			"disappear_no":
				is_animating = false
				_finish_continue(false)

	# Update sprite frame (cap to valid range for the row)
	var max_frames_in_row = FRAME_COUNTS.get(current_row, 8)
	var actual_frame = min(int(current_frame), max_frames_in_row - 1)
	var frame_index = actual_frame + (current_row * 8)  # 8 columns per row
	archangel_sprite.frame = frame_index

func _show_ui() -> void:
	"""Show the CONTINUE? text and buttons."""
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)

	# Fade in label with scale pop
	continue_label.scale = Vector2(0.5, 0.5)
	continue_label.pivot_offset = continue_label.size / 2
	tween.tween_property(continue_label, "modulate:a", 1.0, 0.3)
	tween.tween_property(continue_label, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Fade in buttons
	tween.tween_property(button_container, "modulate:a", 1.0, 0.3).set_delay(0.2)

	# Screen shake for impact
	if JuiceManager:
		JuiceManager.shake_medium()

	# Haptic feedback
	if HapticManager:
		HapticManager.medium()

func _on_yes_pressed() -> void:
	"""Player chose to continue."""
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# Disable buttons
	yes_button.disabled = true
	no_button.disabled = true

	# Hide UI
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(continue_label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(button_container, "modulate:a", 0.0, 0.2)

	# Play cast animation, then disappear
	animation_phase = "cast"
	current_row = ROW_CAST
	current_frame = 0

func _on_no_pressed() -> void:
	"""Player chose not to continue."""
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	# Disable buttons
	yes_button.disabled = true
	no_button.disabled = true

	# Hide UI
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(continue_label, "modulate:a", 0.0, 0.2)
	tween.parallel().tween_property(button_container, "modulate:a", 0.0, 0.2)

	# Play disappear animation
	animation_phase = "disappear_no"
	current_row = ROW_DISAPPEAR
	current_frame = 0

func _finish_continue(accepted: bool) -> void:
	"""Finish the continue sequence."""
	# Fade out overlay
	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.tween_property(overlay, "color:a", 0.0, 0.3)
	tween.tween_property(archangel_sprite, "modulate:a", 0.0, 0.3)
	tween.tween_callback(func():
		emit_signal("continue_chosen", accepted)
		queue_free()
	)
