extends Control
class_name ActiveAbilityButton

signal pressed()

# Visual configuration
const BUTTON_SIZE := Vector2(80, 80)
const COOLDOWN_COLOR := Color(0.2, 0.2, 0.2, 0.8)
const READY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const PRESSED_SCALE := 0.9
const DODGE_COLOR := Color(0.4, 0.8, 1.0)  # Cyan for dodge

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
	# Background
	background = ColorRect.new()
	background.size = BUTTON_SIZE
	background.color = Color(0.15, 0.15, 0.2, 0.9)
	add_child(background)

	# Border
	border = ColorRect.new()
	border.size = BUTTON_SIZE
	border.color = Color(0.5, 0.5, 0.5, 1.0)
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(border)

	# Inner background (creates border effect)
	var inner_bg = ColorRect.new()
	inner_bg.position = Vector2(3, 3)
	inner_bg.size = BUTTON_SIZE - Vector2(6, 6)
	inner_bg.color = Color(0.1, 0.1, 0.15, 0.95)
	inner_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(inner_bg)

	# Icon
	icon_texture = TextureRect.new()
	icon_texture.position = Vector2(8, 8)
	icon_texture.size = BUTTON_SIZE - Vector2(16, 16)
	icon_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)

	# Cooldown overlay (fills from bottom to top)
	cooldown_overlay = ColorRect.new()
	cooldown_overlay.position = Vector2(3, 3)
	cooldown_overlay.size = BUTTON_SIZE - Vector2(6, 6)
	cooldown_overlay.color = COOLDOWN_COLOR
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_overlay.visible = false
	add_child(cooldown_overlay)

	# Cooldown text
	cooldown_label = Label.new()
	cooldown_label.position = Vector2(0, BUTTON_SIZE.y / 2 - 10)
	cooldown_label.size = Vector2(BUTTON_SIZE.x, 20)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 14)
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

func setup_ability(p_ability: ActiveAbilityData, p_slot: int) -> void:
	"""Configure button for a specific ability."""
	ability = p_ability
	slot_index = p_slot
	is_dodge = false

	# Update visuals
	_update_border_color()
	_load_icon()
	update_cooldown(0.0)

func setup_dodge() -> void:
	"""Configure button as the dodge button."""
	ability = null
	slot_index = -1
	is_dodge = true

	border.color = DODGE_COLOR
	_load_dodge_icon()
	update_cooldown(0.0)

func setup_empty(p_slot: int) -> void:
	"""Configure button as empty slot."""
	ability = null
	slot_index = p_slot
	is_dodge = false

	border.color = Color(0.3, 0.3, 0.3, 0.5)
	icon_texture.texture = null

	# Show "?" or empty indicator
	cooldown_label.text = "?"
	cooldown_label.visible = true
	cooldown_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

func _update_border_color() -> void:
	if not ability:
		return

	border.color = ActiveAbilityData.get_rarity_color(ability.rarity)

func _load_icon() -> void:
	if not ability:
		icon_texture.texture = null
		return

	# Try to load ability-specific icon
	var icon_path = "res://assets/icons/abilities/" + ability.id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
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
		cooldown_overlay.visible = false
		cooldown_label.visible = false if icon_texture.texture else true
		background.color = Color(0.15, 0.15, 0.2, 0.9)

		# Restore icon color
		icon_texture.modulate = READY_COLOR
	else:
		# Show cooldown overlay
		cooldown_overlay.visible = true
		cooldown_overlay.size.y = (BUTTON_SIZE.y - 6) * percent
		cooldown_overlay.position.y = 3 + (BUTTON_SIZE.y - 6) * (1.0 - percent)

		# Show remaining time
		var remaining = _get_remaining_cooldown()
		if remaining > 0:
			cooldown_label.text = str(ceil(remaining))
			cooldown_label.visible = true
			cooldown_label.add_theme_color_override("font_color", Color.WHITE)

		# Dim icon
		icon_texture.modulate = Color(0.5, 0.5, 0.5, 1.0)

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
