extends Control
class_name ActiveAbilityButton

signal pressed()

# Visual configuration
const BUTTON_SIZE := Vector2(160, 160)  # Doubled from 80
const COOLDOWN_COLOR := Color(0.2, 0.2, 0.2, 0.8)
const READY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const PRESSED_SCALE := 0.9
const DODGE_COLOR := Color(0.4, 0.8, 1.0)  # Cyan for dodge
const BORDER_WIDTH := 4

var ability: ActiveAbilityData = null
var slot_index: int = -1
var is_dodge: bool = false
var is_ready: bool = true
var cooldown_percent: float = 0.0

# UI elements
var background: ColorRect
var icon_texture: TextureRect
var cooldown_overlay: ColorRect
var cooldown_label: Label
var border: ColorRect
var touch_area: Control

var pixel_font: Font = null

func _ready() -> void:
	custom_minimum_size = BUTTON_SIZE
	size = BUTTON_SIZE

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_create_ui()

func _create_ui() -> void:
	# We'll use custom drawing for the circular button
	# Set clip to false so we can draw outside bounds if needed

	# Icon (centered, slightly smaller than button for border)
	icon_texture = TextureRect.new()
	var icon_margin = 24
	icon_texture.position = Vector2(icon_margin, icon_margin)
	icon_texture.size = BUTTON_SIZE - Vector2(icon_margin * 2, icon_margin * 2)
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)

	# Cooldown text (centered)
	cooldown_label = Label.new()
	cooldown_label.position = Vector2(0, BUTTON_SIZE.y / 2 - 16)
	cooldown_label.size = Vector2(BUTTON_SIZE.x, 32)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 24)
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		cooldown_label.add_theme_font_override("font", pixel_font)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.visible = false
	add_child(cooldown_label)

	# Touch area (invisible but captures input)
	touch_area = Control.new()
	touch_area.position = Vector2.ZERO
	touch_area.size = BUTTON_SIZE
	touch_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(touch_area)

	# Connect input
	touch_area.gui_input.connect(_on_gui_input)

	# Store border color for drawing
	border_color = Color(0.5, 0.5, 0.5, 1.0)
	bg_color = Color(0.1, 0.1, 0.15, 0.95)

var border_color: Color = Color(0.5, 0.5, 0.5, 1.0)
var bg_color: Color = Color(0.1, 0.1, 0.15, 0.95)

func _draw() -> void:
	var center = BUTTON_SIZE / 2
	var radius = BUTTON_SIZE.x / 2 - BORDER_WIDTH

	# Draw outer border circle
	draw_circle(center, radius + BORDER_WIDTH, border_color)

	# Draw inner background circle
	draw_circle(center, radius, bg_color)

	# Draw cooldown overlay as arc if on cooldown
	if cooldown_percent > 0:
		var overlay_color = COOLDOWN_COLOR
		# Draw from top, clockwise based on cooldown percent
		var start_angle = -PI / 2  # Start at top
		var end_angle = start_angle + (TAU * cooldown_percent)
		_draw_filled_arc(center, radius, start_angle, end_angle, overlay_color)

func _draw_filled_arc(center: Vector2, radius: float, start_angle: float, end_angle: float, color: Color) -> void:
	var points = PackedVector2Array()
	points.append(center)

	var segments = 32
	var angle_step = (end_angle - start_angle) / segments

	for i in range(segments + 1):
		var angle = start_angle + angle_step * i
		points.append(center + Vector2(cos(angle), sin(angle)) * radius)

	if points.size() > 2:
		draw_colored_polygon(points, color)

func setup_ability(p_ability: ActiveAbilityData, p_slot: int) -> void:
	"""Configure button for a specific ability."""
	ability = p_ability
	slot_index = p_slot
	is_dodge = false

	# Update visuals
	_update_border_color()
	_load_icon()
	update_cooldown(0.0)
	queue_redraw()

func setup_dodge() -> void:
	"""Configure button as the dodge button."""
	ability = null
	slot_index = -1
	is_dodge = true

	border_color = DODGE_COLOR
	_load_dodge_icon()
	update_cooldown(0.0)
	queue_redraw()

func setup_empty(p_slot: int) -> void:
	"""Configure button as empty slot."""
	ability = null
	slot_index = p_slot
	is_dodge = false

	border_color = Color(0.3, 0.3, 0.3, 0.5)
	icon_texture.texture = null

	# Show "?" or empty indicator
	cooldown_label.text = "?"
	cooldown_label.visible = true
	cooldown_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	queue_redraw()

func _update_border_color() -> void:
	if not ability:
		return

	border_color = ActiveAbilityData.get_rarity_color(ability.rarity)

func _load_icon() -> void:
	if not ability:
		icon_texture.texture = null
		return

	# Try to load ability-specific icon
	var icon_path = "res://assets/icons/abilities/" + ability.id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
		cooldown_label.visible = false
	else:
		# Fallback: use first letter as placeholder
		icon_texture.texture = null
		cooldown_label.text = ability.name.substr(0, 1).to_upper()
		cooldown_label.visible = true
		cooldown_label.add_theme_color_override("font_color", Color.WHITE)

func _load_dodge_icon() -> void:
	var icon_path = "res://assets/icons/abilities/dodge.png"
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
		cooldown_label.visible = false
	else:
		icon_texture.texture = null
		cooldown_label.text = "D"
		cooldown_label.visible = true
		cooldown_label.add_theme_color_override("font_color", DODGE_COLOR)

func update_cooldown(percent: float) -> void:
	"""Update the cooldown display. percent is 0 (ready) to 1 (just used)."""
	cooldown_percent = percent
	is_ready = percent <= 0

	if is_ready:
		cooldown_label.visible = false if icon_texture.texture else true

		# Restore icon color
		icon_texture.modulate = READY_COLOR
	else:
		# Show remaining time
		var remaining = _get_remaining_cooldown()
		if remaining > 0:
			cooldown_label.text = str(ceil(remaining))
			cooldown_label.visible = true
			cooldown_label.add_theme_color_override("font_color", Color.WHITE)

		# Dim icon
		icon_texture.modulate = Color(0.5, 0.5, 0.5, 1.0)

	queue_redraw()

func _get_remaining_cooldown() -> float:
	if is_dodge:
		return ActiveAbilityManager.dodge_cooldown_timer
	elif slot_index >= 0:
		return ActiveAbilityManager.get_cooldown_remaining(slot_index)
	return 0.0

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		if event.pressed:
			_on_button_pressed()

func _on_button_pressed() -> void:
	if not is_ready:
		return

	# Visual feedback
	_animate_press()

	# Emit signal
	emit_signal("pressed")

	# Execute ability or dodge
	if is_dodge:
		ActiveAbilityManager.perform_dodge()
	elif ability and slot_index >= 0:
		ActiveAbilityManager.use_ability(slot_index)

func _animate_press() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(PRESSED_SCALE, PRESSED_SCALE), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _process(_delta: float) -> void:
	# Update cooldown display
	if is_dodge:
		update_cooldown(ActiveAbilityManager.get_dodge_cooldown_percent())
	elif slot_index >= 0 and ability:
		update_cooldown(ActiveAbilityManager.get_cooldown_percent(slot_index))
