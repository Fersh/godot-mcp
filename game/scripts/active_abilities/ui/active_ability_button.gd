extends Control
class_name ActiveAbilityButton

signal pressed()

# Visual configuration
var button_size := Vector2(120, 120)  # Configurable size, set by parent
const COOLDOWN_COLOR := Color(0.2, 0.2, 0.2, 0.8)
const READY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const PRESSED_SCALE := 0.9
const DODGE_COLOR := Color(0.4, 0.8, 1.0)  # Cyan for dodge
const BORDER_WIDTH := 3
const LONG_PRESS_TIME := 0.4  # Time to hold before showing tooltip on touch

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

# Tooltip elements
var tooltip_panel: PanelContainer = null
var tooltip_visible: bool = false
var touch_hold_timer: float = 0.0
var is_touch_held: bool = false
var touch_triggered_tooltip: bool = false

var pixel_font: Font = null

func _ready() -> void:
	custom_minimum_size = button_size
	size = button_size

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_create_ui()

func _create_ui() -> void:
	# We'll use custom drawing for the circular button
	# Icon will be drawn in _draw() to clip it to the circle

	# Icon texture rect (hidden, we use it just to hold the texture)
	icon_texture = TextureRect.new()
	icon_texture.visible = false  # We draw it manually in _draw()
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)

	# Cooldown text (centered)
	cooldown_label = Label.new()
	cooldown_label.position = Vector2(0, button_size.y / 2 - 12)
	cooldown_label.size = Vector2(button_size.x, 24)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", int(button_size.x * 0.15))
	cooldown_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		cooldown_label.add_theme_font_override("font", pixel_font)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.visible = false
	add_child(cooldown_label)

	# Touch area (invisible but captures input)
	touch_area = Control.new()
	touch_area.position = Vector2.ZERO
	touch_area.size = button_size
	touch_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(touch_area)

	# Connect input
	touch_area.gui_input.connect(_on_gui_input)
	touch_area.mouse_entered.connect(_on_mouse_entered)
	touch_area.mouse_exited.connect(_on_mouse_exited)

	# Store border color for drawing
	border_color = Color(0.5, 0.5, 0.5, 1.0)
	bg_color = Color(0.1, 0.1, 0.15, 0.95)

	# Create tooltip (initially hidden)
	_create_tooltip()

var border_color: Color = Color(0.5, 0.5, 0.5, 1.0)
var bg_color: Color = Color(0.1, 0.1, 0.15, 0.95)

func _draw() -> void:
	var center = button_size / 2
	var radius = button_size.x / 2 - BORDER_WIDTH

	# Draw outer border circle
	draw_circle(center, radius + BORDER_WIDTH, border_color)

	# Draw inner background circle
	draw_circle(center, radius, bg_color)

	# Draw icon clipped to circle
	if icon_texture.texture:
		var tex = icon_texture.texture
		var tex_size = tex.get_size()

		# Calculate size to fill the circle (cover mode)
		var scale_factor = (radius * 2) / min(tex_size.x, tex_size.y)
		var draw_size = tex_size * scale_factor

		# Center the icon
		var draw_pos = center - draw_size / 2

		# Draw the icon with circular clipping using stencil technique
		# We'll draw the texture and then use the polygon to mask it
		var icon_color = icon_texture.modulate if icon_texture.modulate else Color.WHITE
		_draw_texture_clipped_to_circle(tex, center, radius, icon_color)

	# Draw cooldown overlay as arc if on cooldown
	if cooldown_percent > 0:
		var overlay_color = COOLDOWN_COLOR
		# Draw from top, clockwise based on cooldown percent
		var start_angle = -PI / 2  # Start at top
		var end_angle = start_angle + (TAU * cooldown_percent)
		_draw_filled_arc(center, radius, start_angle, end_angle, overlay_color)

func _draw_texture_clipped_to_circle(tex: Texture2D, center: Vector2, radius: float, modulate: Color) -> void:
	# Create circular UV mapping to draw texture clipped to circle
	var segments = 64
	var points = PackedVector2Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()

	var tex_size = tex.get_size()
	# Scale to fill circle (cover mode - may crop)
	var scale_factor = (radius * 2) / min(tex_size.x, tex_size.y)
	var scaled_size = tex_size * scale_factor

	for i in range(segments):
		var angle = (float(i) / segments) * TAU - PI / 2
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)

		# Calculate UV based on position relative to center
		var offset = point - center
		# Map from circle space to texture space
		var uv = Vector2(0.5, 0.5) + offset / scaled_size
		uvs.append(uv)
		colors.append(modulate)

	# Draw the textured polygon
	if points.size() >= 3:
		draw_polygon(points, colors, uvs, tex)

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
	# Handle touch events for long-press tooltip
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touch_held = true
			touch_hold_timer = 0.0
			touch_triggered_tooltip = false
		else:
			# Touch released
			is_touch_held = false
			if touch_triggered_tooltip:
				# Was showing tooltip, hide it and don't trigger ability
				_hide_tooltip()
				touch_triggered_tooltip = false
			else:
				# Quick tap, trigger ability
				_on_button_pressed()

	# Handle mouse clicks (immediate action, tooltip handled by hover)
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

func _process(delta: float) -> void:
	# Update cooldown display
	if is_dodge:
		update_cooldown(ActiveAbilityManager.get_dodge_cooldown_percent())
	elif slot_index >= 0 and ability:
		update_cooldown(ActiveAbilityManager.get_cooldown_percent(slot_index))

	# Handle touch hold for tooltip
	if is_touch_held and not touch_triggered_tooltip:
		touch_hold_timer += delta
		if touch_hold_timer >= LONG_PRESS_TIME:
			touch_triggered_tooltip = true
			_show_tooltip()

# ============================================
# TOOLTIP FUNCTIONS
# ============================================

func _create_tooltip() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "Tooltip"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 100

	# Style the tooltip panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	tooltip_panel.add_theme_stylebox_override("panel", style)

	# Content VBox
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 6)
	tooltip_panel.add_child(vbox)

	# Rarity label
	var rarity_label = Label.new()
	rarity_label.name = "RarityLabel"
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 10)
	if pixel_font:
		rarity_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(rarity_label)

	# Name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Separator
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Description label
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 200
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	# Cooldown label
	var cd_label = Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.add_theme_font_size_override("font_size", 10)
	cd_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if pixel_font:
		cd_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(cd_label)

	# Add to parent's parent (the bar's grid container) so it's not clipped
	# We'll position it manually
	add_child(tooltip_panel)

func _update_tooltip_content() -> void:
	if not tooltip_panel:
		return

	var vbox = tooltip_panel.get_child(0) as VBoxContainer
	if not vbox:
		return

	var rarity_label = vbox.get_node("RarityLabel") as Label
	var name_label = vbox.get_node("NameLabel") as Label
	var desc_label = vbox.get_node("DescLabel") as Label
	var cd_label = vbox.get_node("CooldownLabel") as Label

	if is_dodge:
		# Dodge button tooltip
		if rarity_label:
			rarity_label.text = "UTILITY"
			rarity_label.add_theme_color_override("font_color", DODGE_COLOR)
		if name_label:
			name_label.text = "Dodge"
		if desc_label:
			desc_label.text = "Quickly dash backward away from the nearest enemy. Brief invulnerability during the dodge."
		if cd_label:
			cd_label.text = "Cooldown: 5s"

		# Update border color
		var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = DODGE_COLOR
		tooltip_panel.add_theme_stylebox_override("panel", style)

	elif ability:
		# Ability tooltip
		if rarity_label:
			rarity_label.text = ActiveAbilityData.get_rarity_name(ability.rarity)
			rarity_label.add_theme_color_override("font_color", ActiveAbilityData.get_rarity_color(ability.rarity))
		if name_label:
			name_label.text = ability.name
		if desc_label:
			desc_label.text = ability.description
		if cd_label:
			cd_label.text = "Cooldown: " + str(int(ability.cooldown)) + "s"

		# Update border color
		var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = ActiveAbilityData.get_rarity_color(ability.rarity)
		tooltip_panel.add_theme_stylebox_override("panel", style)
	else:
		# Empty slot
		if rarity_label:
			rarity_label.text = ""
		if name_label:
			name_label.text = "Empty Slot"
		if desc_label:
			desc_label.text = "No ability equipped in this slot yet."
		if cd_label:
			cd_label.text = ""

func _show_tooltip() -> void:
	if tooltip_visible:
		return

	# Don't show tooltip for empty slots (unless they want to see the empty message)
	if not ability and not is_dodge:
		return

	_update_tooltip_content()

	# Position tooltip above the button
	tooltip_panel.reset_size()  # Let it calculate its size
	await get_tree().process_frame  # Wait for size calculation

	var tooltip_pos = Vector2.ZERO
	tooltip_pos.x = (button_size.x - tooltip_panel.size.x) / 2  # Center horizontally
	tooltip_pos.y = -tooltip_panel.size.y - 10  # Above the button with padding

	# Clamp tooltip position to stay on screen
	var viewport_size = get_viewport().get_visible_rect().size
	var global_pos = global_position + tooltip_pos

	# Clamp right edge
	if global_pos.x + tooltip_panel.size.x > viewport_size.x - 10:
		tooltip_pos.x = viewport_size.x - 10 - global_position.x - tooltip_panel.size.x

	# Clamp left edge
	if global_pos.x < 10:
		tooltip_pos.x = 10 - global_position.x

	# If tooltip would go off top, show it below the button instead
	if global_pos.y < 10:
		tooltip_pos.y = button_size.y + 10

	tooltip_panel.position = tooltip_pos
	tooltip_panel.visible = true
	tooltip_visible = true

	# Animate tooltip appearance
	tooltip_panel.modulate.a = 0.0
	tooltip_panel.scale = Vector2(0.9, 0.9)
	tooltip_panel.pivot_offset = tooltip_panel.size / 2

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.15)
	tween.tween_property(tooltip_panel, "scale", Vector2.ONE, 0.15).set_ease(Tween.EASE_OUT)

func _hide_tooltip() -> void:
	if not tooltip_visible:
		return

	tooltip_visible = false

	# Animate tooltip disappearance
	var tween = create_tween()
	tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func():
		tooltip_panel.visible = false
	)

func _on_mouse_entered() -> void:
	_show_tooltip()

func _on_mouse_exited() -> void:
	_hide_tooltip()
