extends Control
class_name ActiveAbilityButton

signal pressed()

# Visual configuration
var button_size := Vector2(120, 120)  # Configurable size, set by parent
const COOLDOWN_COLOR := Color(0.0, 0.0, 0.0, 0.95)  # 95% black overlay
const READY_COLOR := Color(1.0, 1.0, 1.0, 1.0)
const PRESSED_SCALE := 0.92
const PRESSED_OFFSET := Vector2(2, 4)  # Slight down-right offset when pressed
const PRESSED_DARKEN := 0.7  # Darken to 70% brightness when pressed
const DODGE_COLOR := Color(0.4, 0.8, 1.0)  # Cyan for dodge
const BORDER_WIDTH := 3
const LONG_PRESS_TIME := 2.0  # Time to hold before showing tooltip on touch
const SKILLSHOT_DRAG_THRESHOLD := 50.0  # Minimum drag distance to activate skillshot aiming
const SKILLSHOT_AIM_LINE_LENGTH := 100.0  # Length of the aim indicator line (halved to stay on screen)

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
var charge_label: Label  # Shows x2 for dodge charges

# Tooltip elements
var tooltip_panel: PanelContainer = null
var tooltip_visible: bool = false
var touch_hold_timer: float = 0.0
var is_touch_held: bool = false
var touch_triggered_tooltip: bool = false

# Skillshot aiming state
var skillshot_active: bool = false
var skillshot_start_pos: Vector2 = Vector2.ZERO
var skillshot_current_pos: Vector2 = Vector2.ZERO
var skillshot_aim_direction: Vector2 = Vector2.ZERO
var aim_indicator: Node2D = null

# Pressed state for visual feedback
var is_button_pressed: bool = false
var press_visual_amount: float = 0.0  # 0 = not pressed, 1 = fully pressed

var pixel_font: Font = null
var desc_font: Font = null
var desc_bold_font: Font = null

func _ready() -> void:
	custom_minimum_size = button_size
	size = button_size

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load Quicksand fonts for descriptions
	if ResourceLoader.exists("res://assets/fonts/Quicksand/Quicksand-Medium.ttf"):
		desc_font = load("res://assets/fonts/Quicksand/Quicksand-Medium.ttf")
	if ResourceLoader.exists("res://assets/fonts/Quicksand/Quicksand-Bold.ttf"):
		desc_bold_font = load("res://assets/fonts/Quicksand/Quicksand-Bold.ttf")

	_create_ui()

func _create_ui() -> void:
	# We'll use custom drawing for the circular button
	# Icon will be drawn in _draw() to clip it to the circle

	# Icon texture rect (hidden, we use it just to hold the texture)
	icon_texture = TextureRect.new()
	icon_texture.visible = false  # We draw it manually in _draw()
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)

	# Cooldown text (centered) - bright white with bold outline
	cooldown_label = Label.new()
	cooldown_label.position = Vector2(0, button_size.y / 2 - 12)
	cooldown_label.size = Vector2(button_size.x, 24)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", int(button_size.x * 0.2))  # Larger font
	cooldown_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))  # Bright white
	cooldown_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))  # Black outline
	cooldown_label.add_theme_constant_override("outline_size", 4)  # Bold outline
	cooldown_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	cooldown_label.add_theme_constant_override("shadow_offset_x", 2)
	cooldown_label.add_theme_constant_override("shadow_offset_y", 2)
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

	# Store border color for drawing - white for all buttons
	border_color = Color(1.0, 1.0, 1.0, 1.0)
	bg_color = Color(0.1, 0.1, 0.15, 1.0)

	# Charge indicator label (top right corner, for dodge with Double Charge)
	charge_label = Label.new()
	charge_label.position = Vector2(button_size.x - 36, 4)  # Top right corner
	charge_label.size = Vector2(32, 24)
	charge_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	charge_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	charge_label.add_theme_font_size_override("font_size", int(button_size.x * 0.14))
	charge_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))  # Cyan
	charge_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	charge_label.add_theme_constant_override("outline_size", 3)
	if pixel_font:
		charge_label.add_theme_font_override("font", pixel_font)
	charge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	charge_label.visible = false
	charge_label.z_index = 10
	add_child(charge_label)

	# Create tooltip (initially hidden)
	_create_tooltip()

var border_color: Color = Color(1.0, 1.0, 1.0, 1.0)
var bg_color: Color = Color(0.1, 0.1, 0.15, 1.0)

func _draw() -> void:
	var center = button_size / 2
	var radius = button_size.x / 2 - BORDER_WIDTH

	# Apply pressed offset to center
	var press_offset = PRESSED_OFFSET * press_visual_amount
	var draw_center = center + press_offset

	# Calculate pressed darkening
	var press_darken = lerp(1.0, PRESSED_DARKEN, press_visual_amount)

	# Draw drop shadow when pressed (appears behind button)
	if press_visual_amount > 0:
		var shadow_color = Color(0.0, 0.0, 0.0, 0.4 * press_visual_amount)
		var shadow_offset = Vector2(0, 2) * (1.0 - press_visual_amount)
		draw_circle(center + shadow_offset, radius + BORDER_WIDTH, shadow_color)

	# Draw outer border circle (darkened when pressed)
	var current_border_color = Color(
		border_color.r * press_darken,
		border_color.g * press_darken,
		border_color.b * press_darken,
		border_color.a
	)
	draw_circle(draw_center, radius + BORDER_WIDTH, current_border_color)

	# Draw inner background circle (darkened when pressed)
	var current_bg_color = Color(
		bg_color.r * press_darken,
		bg_color.g * press_darken,
		bg_color.b * press_darken,
		bg_color.a
	)
	draw_circle(draw_center, radius, current_bg_color)

	# Draw icon clipped to circle
	if icon_texture.texture:
		var tex = icon_texture.texture
		var tex_size = tex.get_size()

		# Calculate size to fill the circle (cover mode)
		var scale_factor = (radius * 2) / min(tex_size.x, tex_size.y)
		var draw_size = tex_size * scale_factor

		# Center the icon
		var draw_pos = draw_center - draw_size / 2

		# Draw the icon with circular clipping - apply pressed darkening
		var icon_color = icon_texture.modulate if icon_texture.modulate else Color.WHITE
		icon_color = Color(
			icon_color.r * press_darken,
			icon_color.g * press_darken,
			icon_color.b * press_darken,
			icon_color.a
		)
		_draw_texture_clipped_to_circle(tex, draw_center, radius, icon_color)

	# Draw skillshot indicator for abilities that support aiming
	if ability and ability.supports_skillshot():
		_draw_skillshot_indicator(draw_center, radius)

	# Draw cooldown overlay from top down (fills from bottom up as it becomes ready)
	if cooldown_percent > 0:
		var overlay_color = COOLDOWN_COLOR
		# Draw overlay covering top portion, shrinking as cooldown completes
		_draw_bottom_up_cooldown(draw_center, radius, cooldown_percent, overlay_color)

	# Draw inner shadow when pressed for depth effect
	if press_visual_amount > 0:
		var inner_shadow_alpha = 0.35 * press_visual_amount
		var inner_shadow_color = Color(0.0, 0.0, 0.0, inner_shadow_alpha)
		_draw_inner_shadow(draw_center, radius, inner_shadow_color)

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

	# UV inset to avoid sampling edge pixels (fixes white border artifacts)
	var uv_inset = 0.92

	for i in range(segments):
		var angle = (float(i) / segments) * TAU - PI / 2
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)

		# Calculate UV based on position relative to center
		var offset = point - center
		# Map from circle space to texture space (scaled inward to avoid edge artifacts)
		var uv = Vector2(0.5, 0.5) + (offset / scaled_size) * uv_inset
		uvs.append(uv)
		colors.append(modulate)

	# Draw the textured polygon
	if points.size() >= 3:
		draw_polygon(points, colors, uvs, tex)

func _draw_bottom_up_cooldown(center: Vector2, radius: float, percent: float, color: Color) -> void:
	# Black overlay on TOP portion, shrinking UPWARD as cooldown completes
	# Icon is revealed from BOTTOM UP
	# percent = 1 means full black (just used), percent = 0 means no black (ready)

	if percent <= 0:
		return  # No overlay when ready

	if percent >= 1:
		# Full overlay - draw entire circle
		var segments = 32
		var points = PackedVector2Array()
		for i in range(segments):
			var angle = (float(i) / segments) * TAU
			points.append(Vector2(center.x + cos(angle) * radius, center.y + sin(angle) * radius))
		draw_colored_polygon(points, color)
		return

	var points = PackedVector2Array()

	var top_y = center.y - radius
	var bottom_y = center.y + radius
	var diameter = bottom_y - top_y

	# cutoff_y = bottom edge of black overlay
	# At percent=1: cutoff at bottom_y (full black)
	# At percent=0.5: cutoff at center (top half black)
	# At percent=0: cutoff at top_y (no black)
	var cutoff_y = top_y + (diameter * percent)

	# If cutoff is at or above top, no overlay needed
	if cutoff_y <= top_y:
		return

	var dy = cutoff_y - center.y
	var dx_squared = radius * radius - dy * dy

	# If cutoff is at or below bottom, draw full circle
	if dx_squared <= 0 or cutoff_y >= bottom_y:
		var segments = 32
		for i in range(segments):
			var angle = (float(i) / segments) * TAU
			points.append(Vector2(center.x + cos(angle) * radius, center.y + sin(angle) * radius))
		draw_colored_polygon(points, color)
		return

	var dx = sqrt(dx_squared)
	var left_x = center.x - dx
	var right_x = center.x + dx

	# Build polygon for TOP portion (above cutoff_y):
	# Start at left intersection, go up and around the TOP to right intersection, close with line

	# Calculate angles (in Godot's Y-down coord system)
	var left_angle = atan2(dy, -dx)   # left intersection
	var right_angle = atan2(dy, dx)   # right intersection

	# We want to go from left intersection, COUNTERCLOCKWISE through the TOP, to right intersection
	# In Y-down coords, top of circle is at angle -PI/2
	# We need to traverse from left_angle to right_angle going through -PI/2

	points.append(Vector2(left_x, cutoff_y))

	# Ensure we go counterclockwise (through the top, which is -PI/2)
	# Normalize angles to be consistent
	var start_angle = left_angle
	var end_angle = right_angle

	# Calculate the arc going through the TOP of the circle
	# We need to go from left_angle to right_angle passing through -PI/2 (top in Y-down coords)
	var angle_diff = end_angle - start_angle
	if angle_diff < 0:
		angle_diff = angle_diff + TAU  # Go clockwise (positive direction) through the top

	var segments = 32
	for i in range(segments + 1):
		var t = float(i) / segments
		var angle = start_angle + angle_diff * t
		points.append(Vector2(center.x + cos(angle) * radius, center.y + sin(angle) * radius))

	points.append(Vector2(right_x, cutoff_y))

	if points.size() > 2:
		draw_colored_polygon(points, color)

func _draw_inner_shadow(center: Vector2, radius: float, color: Color) -> void:
	# Draw a gradient arc at the top of the circle to simulate pressed-in lighting
	# This creates the illusion of depth when the button is pressed
	var segments = 24
	var shadow_depth = radius * 0.15  # How far the shadow extends inward

	# Draw gradient from edge inward at the top portion of the circle
	for i in range(5):  # Multiple rings for gradient effect
		var t = float(i) / 5.0
		var inner_radius = radius - (shadow_depth * t)
		var ring_alpha = color.a * (1.0 - t)  # Fade out toward center
		var ring_color = Color(color.r, color.g, color.b, ring_alpha)

		# Draw only the top arc (from about 10 o'clock to 2 o'clock)
		var points = PackedVector2Array()
		var start_angle = -PI * 0.8  # Start at ~10 o'clock
		var end_angle = -PI * 0.2    # End at ~2 o'clock

		for j in range(segments + 1):
			var angle_t = float(j) / segments
			var angle = lerp(start_angle, end_angle, angle_t)
			points.append(center + Vector2(cos(angle), sin(angle)) * inner_radius)

		# Draw as polyline (just the arc, not filled)
		if points.size() > 1:
			draw_polyline(points, ring_color, 2.0)

func _draw_skillshot_indicator(center: Vector2, radius: float) -> void:
	# Subtle scope/reticle - 8 lines radiating from edge toward center
	var indicator_color = Color(1.0, 1.0, 1.0, 0.6)
	var outline_color = Color(0.0, 0.0, 0.0, 0.4)
	var line_length = radius * 0.25  # Base length for cardinal lines

	# 8 directions - 4 cardinal + 4 diagonal
	var angles = [
		0,           # Right (3pm)
		PI * 0.25,   # Bottom-right diagonal
		PI * 0.5,    # Bottom (6pm)
		PI * 0.75,   # Bottom-left diagonal
		PI,          # Left (9pm)
		PI * 1.25,   # Top-left diagonal
		PI * 1.5,    # Top (12pm)
		PI * 1.75    # Top-right diagonal
	]

	for i in range(angles.size()):
		var angle = angles[i]
		var dir = Vector2(cos(angle), sin(angle))
		var is_cardinal = (i % 2 == 0)  # 0, 2, 4, 6 are cardinal (12pm, 3pm, 6pm, 9pm)

		# Cardinal lines: thicker and longer; Diagonal lines: thinner and shorter
		var this_length = line_length if is_cardinal else line_length * 0.4
		var line_width = 3.0 if is_cardinal else 1.5
		var outline_width = 5.0 if is_cardinal else 3.0

		var start = center + dir * radius  # Touch the edge
		var end = center + dir * (radius - this_length)

		# Draw outline then line
		draw_line(start, end, outline_color, outline_width)
		draw_line(start, end, indicator_color, line_width)

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

	border_color = Color(1.0, 1.0, 1.0, 0.5)  # White but semi-transparent for empty
	icon_texture.texture = null

	# Show "?" or empty indicator
	cooldown_label.text = "?"
	cooldown_label.visible = true
	cooldown_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	queue_redraw()

func _update_border_color() -> void:
	# White border for all ability buttons
	border_color = Color(1.0, 1.0, 1.0, 1.0)

func _load_icon() -> void:
	if not ability:
		icon_texture.texture = null
		return

	# First check if ability has a custom icon_path set
	if ability.icon_path != "" and ResourceLoader.exists(ability.icon_path):
		icon_texture.texture = load(ability.icon_path)
		cooldown_label.visible = false
		return

	# Check if this is a tree ability - try to get base ability's icon
	if not ability.base_ability_id.is_empty():
		var base_ability = AbilityTreeRegistry.get_ability(ability.base_ability_id)
		if base_ability and base_ability.icon_path != "" and ResourceLoader.exists(base_ability.icon_path):
			icon_texture.texture = load(base_ability.icon_path)
			cooldown_label.visible = false
			return

	# Try assets/icons/abilities path using base ability ID
	var icon_id = ability.get_icon_ability_id()
	var icon_path = "res://assets/icons/abilities/" + icon_id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
		cooldown_label.visible = false
	else:
		# Fallback: use first letter of base_name as placeholder
		icon_texture.texture = null
		var display_letter = ability.base_name.substr(0, 1).to_upper() if not ability.base_name.is_empty() else ability.name.substr(0, 1).to_upper()
		cooldown_label.text = display_letter
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

var was_on_cooldown: bool = false  # Track previous state for ready flash (#8)

func update_cooldown(percent: float) -> void:
	"""Update the cooldown display. percent is 0 (ready) to 1 (just used)."""
	var was_cooling = cooldown_percent > 0
	cooldown_percent = percent
	is_ready = percent <= 0

	if is_ready:
		cooldown_label.visible = false if icon_texture.texture else true

		# Restore icon color
		icon_texture.modulate = READY_COLOR

		# ABILITY READY FLASH (#8) - Flash when ability becomes ready
		if was_on_cooldown and was_cooling:
			_flash_ability_ready()
		was_on_cooldown = false
	else:
		was_on_cooldown = true

		# Show remaining time
		var remaining = _get_remaining_cooldown()
		if remaining > 0:
			cooldown_label.text = str(int(ceil(remaining)))
			cooldown_label.visible = true
			cooldown_label.add_theme_color_override("font_color", Color.WHITE)

		# Keep icon at full brightness - the overlay handles the cooldown visual
		icon_texture.modulate = READY_COLOR

	queue_redraw()

func _get_remaining_cooldown() -> float:
	if is_dodge:
		return ActiveAbilityManager.dodge_cooldown_timer
	elif slot_index >= 0:
		return ActiveAbilityManager.get_cooldown_remaining(slot_index)
	return 0.0

func _on_gui_input(event: InputEvent) -> void:
	# Handle touch events for skillshot aiming and long-press tooltip
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touch_held = true
			touch_hold_timer = 0.0
			touch_triggered_tooltip = false
			# Visual press feedback
			_set_pressed(true)
			# Start tracking for potential skillshot
			if _can_skillshot():
				skillshot_start_pos = event.position
				skillshot_current_pos = event.position
				skillshot_active = false
				skillshot_aim_direction = Vector2.ZERO
		else:
			# Touch released
			is_touch_held = false
			# Visual release feedback
			_set_pressed(false)
			# Always hide tooltip on release
			_hide_tooltip()
			if skillshot_active:
				# Skillshot was active - fire with aim direction
				_fire_skillshot()
				_hide_aim_indicator()
				skillshot_active = false
			elif touch_triggered_tooltip:
				# Was showing tooltip, don't trigger ability
				touch_triggered_tooltip = false
			else:
				# Quick tap, trigger ability with auto-aim
				_on_button_pressed()

	# Handle touch drag for skillshot aiming
	elif event is InputEventScreenDrag:
		if is_touch_held and _can_skillshot():
			skillshot_current_pos = event.position
			var drag_vector = skillshot_current_pos - skillshot_start_pos
			var drag_distance = drag_vector.length()

			if drag_distance >= SKILLSHOT_DRAG_THRESHOLD:
				# Activate skillshot aiming mode
				if not skillshot_active:
					skillshot_active = true
					touch_triggered_tooltip = false  # Cancel tooltip if we're aiming
					_hide_tooltip()
					_show_aim_indicator()

				# Update aim direction (inverted - drag away to aim that direction)
				skillshot_aim_direction = drag_vector.normalized()
				_update_aim_indicator()

	# Handle mouse clicks (immediate action, tooltip handled by hover)
	elif event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				# Visual press feedback
				_set_pressed(true)
				# Start tracking for potential skillshot
				if _can_skillshot():
					skillshot_start_pos = get_global_mouse_position()
					skillshot_current_pos = skillshot_start_pos
					skillshot_active = false
					skillshot_aim_direction = Vector2.ZERO
					is_touch_held = true
			else:
				# Mouse released
				is_touch_held = false
				# Visual release feedback
				_set_pressed(false)
				# Always hide tooltip on release
				_hide_tooltip()
				if skillshot_active:
					_fire_skillshot()
					_hide_aim_indicator()
					skillshot_active = false
				else:
					_on_button_pressed()

	# Handle mouse motion for skillshot aiming
	elif event is InputEventMouseMotion:
		if is_touch_held and _can_skillshot():
			skillshot_current_pos = get_global_mouse_position()
			var drag_vector = skillshot_current_pos - skillshot_start_pos
			var drag_distance = drag_vector.length()

			if drag_distance >= SKILLSHOT_DRAG_THRESHOLD:
				if not skillshot_active:
					skillshot_active = true
					_show_aim_indicator()

				skillshot_aim_direction = drag_vector.normalized()
				_update_aim_indicator()

func _on_button_pressed() -> void:
	if not is_ready:
		return

	# Visual feedback
	_animate_press()

	# Haptic feedback
	if HapticManager:
		HapticManager.light()

	# Emit signal
	emit_signal("pressed")

	# Execute ability or dodge
	if is_dodge:
		ActiveAbilityManager.perform_dodge()
	elif ability and slot_index >= 0:
		ActiveAbilityManager.use_ability(slot_index)

func _animate_press() -> void:
	# Quick bounce animation after button action (in addition to held press state)
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(PRESSED_SCALE, PRESSED_SCALE), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _set_pressed(pressed: bool) -> void:
	"""Set the visual pressed state with smooth animation."""
	is_button_pressed = pressed

	# Animate press_visual_amount for smooth press/release
	var tween = create_tween()
	tween.set_ease(Tween.EASE_OUT if pressed else Tween.EASE_IN)
	tween.set_trans(Tween.TRANS_QUAD)

	if pressed:
		# Quick press down
		tween.tween_property(self, "press_visual_amount", 1.0, 0.06)
		tween.parallel().tween_property(self, "scale", Vector2(PRESSED_SCALE, PRESSED_SCALE), 0.06)
	else:
		# Slightly slower release with subtle bounce
		tween.tween_property(self, "press_visual_amount", 0.0, 0.1)
		tween.parallel().tween_property(self, "scale", Vector2(1.02, 1.02), 0.05)
		tween.tween_property(self, "scale", Vector2.ONE, 0.08)

	# Trigger redraw during animation
	tween.tween_callback(queue_redraw)

func _process(delta: float) -> void:
	# Update cooldown display
	if is_dodge:
		update_cooldown(ActiveAbilityManager.get_dodge_cooldown_percent())
		# Update charge indicator for Double Charge
		_update_charge_indicator()
	elif slot_index >= 0 and ability:
		update_cooldown(ActiveAbilityManager.get_cooldown_percent(slot_index))

	# Redraw when pressed visual is animating
	if press_visual_amount > 0.01 or is_button_pressed:
		queue_redraw()

	# Handle touch hold for tooltip (only if not dragging for skillshot)
	if is_touch_held and not touch_triggered_tooltip and not skillshot_active:
		touch_hold_timer += delta
		if touch_hold_timer >= LONG_PRESS_TIME:
			touch_triggered_tooltip = true
			_show_tooltip()

func _update_charge_indicator() -> void:
	"""Update the charge indicator for dodge with Double Charge."""
	if not is_dodge or not charge_label:
		return

	var max_charges = ActiveAbilityManager.get_max_dodge_charges()
	var current_charges = ActiveAbilityManager.get_dodge_charges()

	if max_charges > 1:
		charge_label.visible = true
		charge_label.text = "x" + str(current_charges)
		# Color based on charges available
		if current_charges >= 2:
			charge_label.add_theme_color_override("font_color", Color(0.4, 1.0, 1.0))  # Cyan when full
		elif current_charges == 1:
			charge_label.add_theme_color_override("font_color", Color(1.0, 1.0, 0.4))  # Yellow when 1
		else:
			charge_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))  # Gray when empty
	else:
		charge_label.visible = false

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
	style.bg_color = Color(0.08, 0.06, 0.10, 1.0)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(12)
	style.content_margin_top = 18  # Extra top margin for rarity tag
	tooltip_panel.add_theme_stylebox_override("panel", style)

	# Content VBox
	var vbox = VBoxContainer.new()
	vbox.name = "VBox"
	vbox.add_theme_constant_override("separation", 4)
	tooltip_panel.add_child(vbox)

	# Name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Margin spacer (replaces separator)
	var spacer = Control.new()
	spacer.name = "Spacer"
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Description label (with padding via MarginContainer)
	var desc_margin = MarginContainer.new()
	desc_margin.name = "DescMargin"
	desc_margin.add_theme_constant_override("margin_left", 10)
	desc_margin.add_theme_constant_override("margin_right", 10)

	var desc_label = RichTextLabel.new()
	desc_label.name = "DescLabel"
	desc_label.bbcode_enabled = true
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 200
	desc_label.add_theme_font_size_override("normal_font_size", 15)
	desc_label.add_theme_font_size_override("bold_font_size", 15)
	desc_label.add_theme_color_override("default_color", Color.WHITE)
	if desc_font:
		desc_label.add_theme_font_override("normal_font", desc_font)
	if desc_bold_font:
		desc_label.add_theme_font_override("bold_font", desc_bold_font)
	desc_margin.add_child(desc_label)
	vbox.add_child(desc_margin)

	# Cooldown spacer
	var cd_spacer = Control.new()
	cd_spacer.name = "CooldownSpacer"
	cd_spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(cd_spacer)

	# Cooldown label
	var cd_label = Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.add_theme_font_size_override("font_size", 14)
	cd_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if desc_font:
		cd_label.add_theme_font_override("font", desc_font)
	vbox.add_child(cd_label)

	# Add tooltip to button
	add_child(tooltip_panel)

	# Rarity tag (positioned on the border, added after tooltip_panel)
	var rarity_tag = PanelContainer.new()
	rarity_tag.name = "RarityTag"
	rarity_tag.visible = false
	rarity_tag.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rarity_tag.z_index = 101

	var rarity_label = Label.new()
	rarity_label.name = "RarityLabel"
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 11)
	if pixel_font:
		rarity_label.add_theme_font_override("font", pixel_font)
	rarity_tag.add_child(rarity_label)

	add_child(rarity_tag)

func _update_tooltip_content() -> void:
	if not tooltip_panel:
		return

	var vbox = tooltip_panel.get_node("VBox") as VBoxContainer
	var rarity_tag = get_node_or_null("RarityTag") as PanelContainer
	if not vbox:
		return

	var name_label = vbox.get_node("NameLabel") as Label
	var desc_margin = vbox.get_node_or_null("DescMargin") as MarginContainer
	var desc_label = desc_margin.get_node("DescLabel") as RichTextLabel if desc_margin else null
	var cd_label = vbox.get_node("CooldownLabel") as Label
	var rarity_label = rarity_tag.get_node("RarityLabel") as Label if rarity_tag else null

	if is_dodge:
		# Dodge button tooltip
		if rarity_tag:
			rarity_tag.visible = false
		if name_label:
			name_label.text = "Dodge"
			name_label.add_theme_color_override("font_color", DODGE_COLOR.lightened(0.3))
		if desc_label:
			desc_label.text = DescriptionFormatter.format("Quickly dash backward away from the nearest enemy. Brief invulnerability during the dodge.")
		if cd_label:
			cd_label.text = "5s cooldown"

		# Update border color
		var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = DODGE_COLOR
		tooltip_panel.add_theme_stylebox_override("panel", style)

	elif ability:
		# Ability tooltip - show rank based on tier
		var rank = 1
		match ability.tier:
			ActiveAbilityData.AbilityTier.BASE:
				rank = 1
			ActiveAbilityData.AbilityTier.BRANCH:
				rank = 2
			ActiveAbilityData.AbilityTier.SIGNATURE:
				rank = 3

		# Rank colors: 1=white, 2=blue, 3=gold
		var rank_colors = [
			Color(0.9, 0.9, 0.9),    # Rank 1 - White
			Color(0.3, 0.5, 1.0),    # Rank 2 - Blue
			Color(1.0, 0.85, 0.0),   # Rank 3 - Gold
		]
		var rank_color = rank_colors[rank - 1]

		if rarity_tag and rarity_label:
			rarity_label.text = "Rank " + str(rank)
			# Use black text for rank 1 (light background), white for others
			var label_color = Color.BLACK if rank == 1 else Color.WHITE
			rarity_label.add_theme_color_override("font_color", label_color)

			# Style the rank tag
			var tag_style = StyleBoxFlat.new()
			tag_style.bg_color = rank_color
			tag_style.set_corner_radius_all(4)
			tag_style.content_margin_left = 8
			tag_style.content_margin_right = 8
			tag_style.content_margin_top = 2
			tag_style.content_margin_bottom = 2
			rarity_tag.add_theme_stylebox_override("panel", tag_style)

		if name_label:
			name_label.text = ability.name
			name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White for all active abilities
		if desc_label:
			desc_label.text = DescriptionFormatter.format(ability.description)
		if cd_label:
			cd_label.text = str(int(ability.cooldown)) + "s cooldown"

		# Update border color to match rank
		var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = rank_color
		tooltip_panel.add_theme_stylebox_override("panel", style)
	else:
		# Empty slot
		if rarity_tag:
			rarity_tag.visible = false
		if name_label:
			name_label.text = "Empty Slot"
			name_label.add_theme_color_override("font_color", Color.WHITE)
		if desc_label:
			desc_label.text = "No ability equipped in this slot yet."  # No formatting needed for this simple text
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

	# Position rarity tag on the top border
	var rarity_tag = get_node_or_null("RarityTag") as PanelContainer
	if rarity_tag and ability:
		rarity_tag.visible = true
		rarity_tag.reset_size()
		await get_tree().process_frame  # Wait for rarity tag size
		rarity_tag.position = Vector2(
			tooltip_pos.x + (tooltip_panel.size.x - rarity_tag.size.x) / 2,  # Center horizontally on tooltip
			tooltip_pos.y - rarity_tag.size.y / 2  # Half above the top border
		)
	elif rarity_tag:
		rarity_tag.visible = false

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

	# Hide rarity tag
	var rarity_tag = get_node_or_null("RarityTag") as PanelContainer
	if rarity_tag:
		rarity_tag.visible = false

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

# ============================================
# ABILITY READY FLASH (#8)
# ============================================

func _flash_ability_ready() -> void:
	"""Flash effect when ability comes off cooldown and is ready to use."""
	# Scale pulse
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(1.3, 1.3), 0.1).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "scale", Vector2(1.0, 1.0), 0.15).set_ease(Tween.EASE_IN_OUT)

	# Brief glow effect - temporarily brighten the border
	var original_border = border_color
	var flash_color = Color(1.0, 1.0, 1.0, 1.0)  # White flash
	if is_dodge:
		flash_color = Color(0.6, 1.0, 1.0, 1.0)  # Cyan flash for dodge

	border_color = flash_color
	queue_redraw()

	var color_tween = create_tween()
	color_tween.tween_callback(func():
		border_color = original_border
		queue_redraw()
	).set_delay(0.15)

	# Play ready sound (subtle)
	if SoundManager and SoundManager.has_method("play_ding"):
		SoundManager.play_ding()

	# Light haptic feedback
	if HapticManager:
		HapticManager.light()

# ============================================
# SKILLSHOT AIMING FUNCTIONS
# ============================================

func _can_skillshot() -> bool:
	"""Check if this button's ability supports skillshot aiming."""
	if is_dodge:
		return false
	if not ability:
		return false
	if not is_ready:
		return false
	return ability.supports_skillshot()

func _fire_skillshot() -> void:
	"""Fire the ability with the current aim direction."""
	if not is_ready or not ability:
		return

	# Visual feedback
	_animate_press()

	# Haptic feedback
	if HapticManager:
		HapticManager.light()

	# Emit signal
	emit_signal("pressed")

	# Execute ability with aim direction
	if slot_index >= 0:
		ActiveAbilityManager.use_ability_aimed(slot_index, skillshot_aim_direction)

func _show_aim_indicator() -> void:
	"""Create and show the aim indicator."""
	if aim_indicator:
		return

	# Create the aim indicator as a child of the scene root (below player sprite)
	aim_indicator = Node2D.new()
	aim_indicator.name = "SkillshotAimIndicator"
	aim_indicator.z_index = -1  # Below player sprite

	# Add to scene tree at root level
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(aim_indicator)

	# Light haptic when entering aim mode
	if HapticManager:
		HapticManager.light()

func _update_aim_indicator() -> void:
	"""Update the aim indicator position and direction."""
	if not aim_indicator:
		return

	# Get player position for aim origin
	var player = ActiveAbilityManager.player
	if not player:
		return

	var start_pos = player.global_position

	# Calculate end position based on aim direction
	var line_length = SKILLSHOT_AIM_LINE_LENGTH
	if ability and ability.range_distance > 0:
		line_length = min(ability.range_distance, 200.0)  # Cap at 200 to stay on screen

	var end_pos = start_pos + skillshot_aim_direction * line_length

	# Redraw the indicator
	aim_indicator.queue_redraw()

	# Connect draw signal if not already connected
	if not aim_indicator.draw.is_connected(_draw_aim_indicator):
		aim_indicator.draw.connect(_draw_aim_indicator)

	# Store data for drawing
	aim_indicator.set_meta("start_pos", start_pos)
	aim_indicator.set_meta("end_pos", end_pos)
	aim_indicator.set_meta("direction", skillshot_aim_direction)

func _draw_aim_indicator() -> void:
	"""Draw the aim line with arrow - gradient from transparent to opaque."""
	if not aim_indicator:
		return

	var start_pos: Vector2 = aim_indicator.get_meta("start_pos", Vector2.ZERO)
	var end_pos: Vector2 = aim_indicator.get_meta("end_pos", Vector2.ZERO)
	var direction: Vector2 = aim_indicator.get_meta("direction", Vector2.RIGHT)

	if start_pos == Vector2.ZERO or end_pos == Vector2.ZERO:
		return

	# Draw settings
	var line_width = 3.0
	var arrow_size = 20.0  # 10% bigger than 18
	var arrow_extension = 12.0  # How far past the line the arrow tip extends

	# Offset start position down 10px (below player sprite)
	start_pos = start_pos + Vector2(0, 10)

	# Draw gradient line as a polygon with smooth color interpolation
	# Line width grows from thin at player to thick at arrow
	var start_width = 1.0  # Thin at player
	var end_width = line_width  # Full width at arrow end
	var perpendicular_dir = Vector2(-direction.y, direction.x)

	# Build a quad strip for smooth gradient (no visible segments)
	var points = PackedVector2Array()
	var colors = PackedColorArray()
	var segments = 64  # High segment count for smooth gradient

	for i in range(segments + 1):
		var t = float(i) / segments
		var pos = start_pos.lerp(end_pos, t)
		var alpha = lerp(0.2, 1.0, t)
		var color = Color(1.0, 1.0, 1.0, alpha)

		# Interpolate width from thin to thick
		var current_width = lerp(start_width, end_width, t) / 2.0
		var perpendicular = perpendicular_dir * current_width

		# Add two points (top and bottom of line width)
		points.append(pos + perpendicular)
		points.append(pos - perpendicular)
		colors.append(color)
		colors.append(color)

	# Draw as triangle strip by building triangles
	for i in range(segments):
		var idx = i * 2
		var tri1_points = PackedVector2Array([points[idx], points[idx + 1], points[idx + 2]])
		var tri1_colors = PackedColorArray([colors[idx], colors[idx + 1], colors[idx + 2]])
		var tri2_points = PackedVector2Array([points[idx + 1], points[idx + 3], points[idx + 2]])
		var tri2_colors = PackedColorArray([colors[idx + 1], colors[idx + 3], colors[idx + 2]])

		aim_indicator.draw_polygon(tri1_points, tri1_colors)
		aim_indicator.draw_polygon(tri2_points, tri2_colors)

	# Arrow tip extends PAST the line end
	var arrow_tip = end_pos + direction * arrow_extension
	var arrow_angle = direction.angle()
	var arrow_point1 = arrow_tip + Vector2(cos(arrow_angle + PI * 0.8), sin(arrow_angle + PI * 0.8)) * arrow_size
	var arrow_point2 = arrow_tip + Vector2(cos(arrow_angle - PI * 0.8), sin(arrow_angle - PI * 0.8)) * arrow_size

	# Draw filled arrow head at full opacity
	var arrow_color = Color(1.0, 1.0, 1.0, 1.0)
	var arrow_points = PackedVector2Array([arrow_tip, arrow_point1, arrow_point2])
	aim_indicator.draw_colored_polygon(arrow_points, arrow_color)

func _hide_aim_indicator() -> void:
	"""Hide and remove the aim indicator."""
	if aim_indicator:
		aim_indicator.queue_free()
		aim_indicator = null
