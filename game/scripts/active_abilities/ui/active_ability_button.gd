extends Control
class_name ActiveAbilityButton

signal pressed()

# Visual configuration
var button_size := Vector2(120, 120)  # Configurable size, set by parent
const COOLDOWN_COLOR := Color(0.0, 0.0, 0.0, 0.85)  # Darker overlay for better visibility
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
var charge_label: Label  # Shows x2 for dodge charges

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

	# Store border color for drawing
	border_color = Color(0.5, 0.5, 0.5, 1.0)
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

var border_color: Color = Color(0.5, 0.5, 0.5, 1.0)
var bg_color: Color = Color(0.1, 0.1, 0.15, 1.0)

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

	# Draw cooldown overlay from top down (fills from bottom up as it becomes ready)
	if cooldown_percent > 0:
		var overlay_color = COOLDOWN_COLOR
		# Draw overlay covering top portion, shrinking as cooldown completes
		_draw_bottom_up_cooldown(center, radius, cooldown_percent, overlay_color)

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

func _draw_bottom_up_cooldown(center: Vector2, radius: float, percent: float, color: Color) -> void:
	# Draw cooldown overlay that covers from top down based on percent
	# percent = 1 means full coverage, percent = 0 means no coverage
	# This creates a "fill from bottom up" effect as cooldown completes

	var points = PackedVector2Array()

	# Calculate the y-level where the cooldown line should be
	# At percent=1, line is at bottom (full coverage)
	# At percent=0, line is at top (no coverage)
	var top_y = center.y - radius
	var bottom_y = center.y + radius
	var fill_height = (bottom_y - top_y) * percent
	var cutoff_y = top_y + fill_height

	# We need to draw the portion of the circle above cutoff_y
	# Find the angles where the circle intersects the cutoff line
	var dy = cutoff_y - center.y

	if dy <= -radius:
		# Cutoff is above circle, no overlay needed
		return
	elif dy >= radius:
		# Cutoff is below circle, draw full circle
		var segments = 32
		for i in range(segments):
			var angle = (float(i) / segments) * TAU
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)
	else:
		# Partial coverage - find intersection points
		var dx = sqrt(radius * radius - dy * dy)
		var left_x = center.x - dx
		var right_x = center.x + dx

		# Start from left intersection, go around top of circle to right intersection
		var start_angle = atan2(dy, -dx)
		var end_angle = atan2(dy, dx)

		# Add left intersection point
		points.append(Vector2(left_x, cutoff_y))

		# Add arc points from left to right going over the top
		var segments = 32
		var angle_range = end_angle - start_angle
		if angle_range > 0:
			angle_range -= TAU

		for i in range(segments + 1):
			var t = float(i) / segments
			var angle = start_angle + angle_range * t
			points.append(center + Vector2(cos(angle), sin(angle)) * radius)

		# Add right intersection point (closes the polygon)
		points.append(Vector2(right_x, cutoff_y))

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
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(PRESSED_SCALE, PRESSED_SCALE), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _process(delta: float) -> void:
	# Update cooldown display
	if is_dodge:
		update_cooldown(ActiveAbilityManager.get_dodge_cooldown_percent())
		# Update charge indicator for Double Charge
		_update_charge_indicator()
	elif slot_index >= 0 and ability:
		update_cooldown(ActiveAbilityManager.get_cooldown_percent(slot_index))

	# Handle touch hold for tooltip
	if is_touch_held and not touch_triggered_tooltip:
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
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Margin spacer (replaces separator)
	var spacer = Control.new()
	spacer.name = "Spacer"
	spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(spacer)

	# Description label
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 11)
	desc_label.add_theme_color_override("font_color", Color.WHITE)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size.x = 200
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	# Cooldown spacer
	var cd_spacer = Control.new()
	cd_spacer.name = "CooldownSpacer"
	cd_spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(cd_spacer)

	# Cooldown label
	var cd_label = Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.add_theme_font_size_override("font_size", 10)
	cd_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if pixel_font:
		cd_label.add_theme_font_override("font", pixel_font)
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
	rarity_label.add_theme_font_size_override("font_size", 9)
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
	var desc_label = vbox.get_node("DescLabel") as Label
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
			desc_label.text = "Quickly dash backward away from the nearest enemy. Brief invulnerability during the dodge."
		if cd_label:
			cd_label.text = "5s Cooldown"

		# Update border color
		var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = DODGE_COLOR
		tooltip_panel.add_theme_stylebox_override("panel", style)

	elif ability:
		# Ability tooltip
		var rarity_color = ActiveAbilityData.get_rarity_color(ability.rarity)

		if rarity_tag and rarity_label:
			rarity_label.text = ActiveAbilityData.get_rarity_name(ability.rarity)
			rarity_label.add_theme_color_override("font_color", Color.WHITE)

			# Style the rarity tag
			var tag_style = StyleBoxFlat.new()
			tag_style.bg_color = rarity_color
			tag_style.set_corner_radius_all(4)
			tag_style.content_margin_left = 8
			tag_style.content_margin_right = 8
			tag_style.content_margin_top = 2
			tag_style.content_margin_bottom = 2
			rarity_tag.add_theme_stylebox_override("panel", tag_style)

		if name_label:
			name_label.text = ability.name
			name_label.add_theme_color_override("font_color", rarity_color.lightened(0.3))
		if desc_label:
			desc_label.text = ability.description
		if cd_label:
			cd_label.text = str(int(ability.cooldown)) + "s Cooldown"

		# Update border color
		var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
		style.border_color = rarity_color
		tooltip_panel.add_theme_stylebox_override("panel", style)
	else:
		# Empty slot
		if rarity_tag:
			rarity_tag.visible = false
		if name_label:
			name_label.text = "Empty Slot"
			name_label.add_theme_color_override("font_color", Color.WHITE)
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
