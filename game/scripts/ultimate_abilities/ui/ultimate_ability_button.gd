extends Control
class_name UltimateAbilityButton

signal pressed()

# Visual configuration - Ultimate button is larger and more prominent
const BUTTON_SIZE := Vector2(120, 120)
const COOLDOWN_COLOR := Color(0.15, 0.12, 0.05, 0.85)  # Dark gold
const READY_COLOR := Color(1.0, 0.95, 0.8)  # Warm white
const ULTIMATE_GOLD := Color(1.0, 0.84, 0.0)  # Golden
const ULTIMATE_GLOW := Color(1.0, 0.9, 0.5, 0.6)  # Golden glow
const PRESSED_SCALE := 0.9
const BORDER_WIDTH := 4  # Thicker border for ultimate
const LONG_PRESS_TIME := 0.4

var ultimate: UltimateAbilityData = null
var is_ready: bool = false
var cooldown_percent: float = 0.0
var has_ultimate: bool = false

# UI elements
var icon_texture: TextureRect
var cooldown_label: Label
var touch_area: Control

# Tooltip
var tooltip_panel: PanelContainer = null
var tooltip_visible: bool = false
var touch_hold_timer: float = 0.0
var is_touch_held: bool = false
var touch_triggered_tooltip: bool = false

# Glow animation
var glow_phase: float = 0.0
var glow_intensity: float = 0.0

var pixel_font: Font = null
var desc_font: Font = null
var desc_bold_font: Font = null
var border_color: Color = Color(0.3, 0.25, 0.1, 0.5)
var bg_color: Color = Color(0.08, 0.06, 0.02, 0.95)

func _ready() -> void:
	custom_minimum_size = BUTTON_SIZE
	size = BUTTON_SIZE

	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load Quicksand fonts for descriptions
	if ResourceLoader.exists("res://assets/fonts/Quicksand/Quicksand-Medium.ttf"):
		desc_font = load("res://assets/fonts/Quicksand/Quicksand-Medium.ttf")
	if ResourceLoader.exists("res://assets/fonts/Quicksand/Quicksand-Bold.ttf"):
		desc_bold_font = load("res://assets/fonts/Quicksand/Quicksand-Bold.ttf")

	_create_ui()
	_connect_signals()

	# Start with button hidden until ultimate is acquired
	visible = false

func _create_ui() -> void:
	# Icon texture (hidden, drawn manually)
	icon_texture = TextureRect.new()
	icon_texture.visible = false
	icon_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon_texture)

	# Cooldown label
	cooldown_label = Label.new()
	cooldown_label.position = Vector2(0, BUTTON_SIZE.y / 2 - 14)
	cooldown_label.size = Vector2(BUTTON_SIZE.x, 28)
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 20)
	cooldown_label.add_theme_color_override("font_color", ULTIMATE_GOLD)
	if pixel_font:
		cooldown_label.add_theme_font_override("font", pixel_font)
	cooldown_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cooldown_label.visible = false
	add_child(cooldown_label)

	# Touch area
	touch_area = Control.new()
	touch_area.position = Vector2.ZERO
	touch_area.size = BUTTON_SIZE
	touch_area.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(touch_area)

	touch_area.gui_input.connect(_on_gui_input)
	touch_area.mouse_entered.connect(_on_mouse_entered)
	touch_area.mouse_exited.connect(_on_mouse_exited)

	_create_tooltip()

func _connect_signals() -> void:
	# Connect to UltimateAbilityManager
	if UltimateAbilityManager:
		UltimateAbilityManager.ultimate_acquired.connect(_on_ultimate_acquired)
		UltimateAbilityManager.ultimate_cooldown_updated.connect(_on_cooldown_updated)
		UltimateAbilityManager.ultimate_ready.connect(_on_ultimate_ready)

func _draw() -> void:
	var center = BUTTON_SIZE / 2
	var radius = BUTTON_SIZE.x / 2 - BORDER_WIDTH

	# Draw glow effect when ready
	if is_ready and has_ultimate:
		var glow_radius = radius + BORDER_WIDTH + 6 + glow_intensity * 4
		var glow_color = ULTIMATE_GLOW
		glow_color.a = 0.3 + glow_intensity * 0.3
		draw_circle(center, glow_radius, glow_color)

	# Draw outer border circle (golden when has ultimate)
	draw_circle(center, radius + BORDER_WIDTH, border_color)

	# Draw inner background
	draw_circle(center, radius, bg_color)

	# Draw icon clipped to circle
	if icon_texture.texture:
		var tex = icon_texture.texture
		var icon_color = icon_texture.modulate if icon_texture.modulate else Color.WHITE
		_draw_texture_clipped_to_circle(tex, center, radius, icon_color)

	# Draw cooldown overlay
	if cooldown_percent > 0:
		var start_angle = -PI / 2
		var end_angle = start_angle + (TAU * cooldown_percent)
		_draw_filled_arc(center, radius, start_angle, end_angle, COOLDOWN_COLOR)

	# Draw "READY" shimmer effect when ready
	if is_ready and has_ultimate:
		var shimmer_alpha = 0.1 + glow_intensity * 0.15
		var shimmer_color = Color(1.0, 1.0, 1.0, shimmer_alpha)
		draw_circle(center, radius, shimmer_color)

func _draw_texture_clipped_to_circle(tex: Texture2D, center: Vector2, radius: float, modulate: Color) -> void:
	var segments = 64
	var points = PackedVector2Array()
	var uvs = PackedVector2Array()
	var colors = PackedColorArray()

	var tex_size = tex.get_size()
	var scale_factor = (radius * 2) / min(tex_size.x, tex_size.y)
	var scaled_size = tex_size * scale_factor

	for i in range(segments):
		var angle = (float(i) / segments) * TAU - PI / 2
		var point = center + Vector2(cos(angle), sin(angle)) * radius
		points.append(point)

		var offset = point - center
		var uv = Vector2(0.5, 0.5) + offset / scaled_size
		uvs.append(uv)
		colors.append(modulate)

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

func _process(delta: float) -> void:
	if not has_ultimate:
		return

	# Update cooldown from manager
	if UltimateAbilityManager:
		var percent = UltimateAbilityManager.get_cooldown_percent()
		_update_cooldown_display(percent)

	# Animate glow when ready
	if is_ready:
		glow_phase += delta * 2.0
		glow_intensity = (sin(glow_phase) + 1.0) / 2.0
		queue_redraw()

	# Handle touch hold for tooltip
	if is_touch_held and not touch_triggered_tooltip:
		touch_hold_timer += delta
		if touch_hold_timer >= LONG_PRESS_TIME:
			touch_triggered_tooltip = true
			_show_tooltip()

func setup_ultimate(p_ultimate: UltimateAbilityData) -> void:
	"""Configure button for the acquired ultimate."""
	ultimate = p_ultimate
	has_ultimate = true
	visible = true

	# Update visuals
	border_color = ULTIMATE_GOLD
	_load_icon()
	_update_cooldown_display(0.0)
	queue_redraw()

	# Play acquisition animation
	_animate_acquire()

func _load_icon() -> void:
	if not ultimate:
		icon_texture.texture = null
		return

	# Try to load ultimate-specific icon
	var icon_path = "res://assets/icons/ultimates/" + ultimate.id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_texture.texture = load(icon_path)
		cooldown_label.visible = false
	else:
		# Fallback: use first letter
		icon_texture.texture = null
		cooldown_label.text = ultimate.name.substr(0, 1).to_upper()
		cooldown_label.visible = true
		cooldown_label.add_theme_color_override("font_color", ULTIMATE_GOLD)

func _update_cooldown_display(percent: float) -> void:
	cooldown_percent = percent
	is_ready = percent <= 0

	if is_ready:
		cooldown_label.visible = false if icon_texture.texture else true
		if cooldown_label.visible:
			cooldown_label.text = ultimate.name.substr(0, 1).to_upper() if ultimate else "U"
			cooldown_label.add_theme_color_override("font_color", ULTIMATE_GOLD)
		icon_texture.modulate = READY_COLOR
	else:
		var remaining = UltimateAbilityManager.get_cooldown_remaining() if UltimateAbilityManager else 0.0
		if remaining > 0:
			cooldown_label.text = str(int(ceil(remaining)))
			cooldown_label.visible = true
			cooldown_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.3))
		icon_texture.modulate = Color(0.4, 0.35, 0.2, 1.0)

	queue_redraw()

func _animate_acquire() -> void:
	"""Animate button appearing when ultimate is acquired."""
	scale = Vector2(0.3, 0.3)
	modulate.a = 0.0

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	tween.set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.1, 1.1), 0.3)\
		.set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(self, "modulate:a", 1.0, 0.2)
	tween.chain().tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventScreenTouch:
		if event.pressed:
			is_touch_held = true
			touch_hold_timer = 0.0
			touch_triggered_tooltip = false
		else:
			is_touch_held = false
			if touch_triggered_tooltip:
				_hide_tooltip()
				touch_triggered_tooltip = false
			else:
				_on_button_pressed()
	elif event is InputEventMouseButton:
		if event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_button_pressed()

func _on_button_pressed() -> void:
	if not is_ready or not has_ultimate:
		return

	_animate_press()

	if HapticManager:
		HapticManager.medium()

	emit_signal("pressed")

	# Trigger ultimate
	if UltimateAbilityManager:
		UltimateAbilityManager.use_ultimate()

func _animate_press() -> void:
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(PRESSED_SCALE, PRESSED_SCALE), 0.05)
	tween.tween_property(self, "scale", Vector2.ONE, 0.1)

func _on_ultimate_acquired(ability: UltimateAbilityData) -> void:
	setup_ultimate(ability)

func _on_cooldown_updated(_remaining: float, _total: float) -> void:
	# Handled in _process
	pass

func _on_ultimate_ready() -> void:
	is_ready = true
	glow_phase = 0.0
	queue_redraw()

# ============================================
# TOOLTIP
# ============================================

func _create_tooltip() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "UltimateTooltip"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.02, 0.98)
	style.border_color = ULTIMATE_GOLD
	style.set_border_width_all(3)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(14)
	tooltip_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	tooltip_panel.add_child(vbox)

	# "ULTIMATE" label
	var ultimate_label = Label.new()
	ultimate_label.name = "UltimateLabel"
	ultimate_label.text = "ULTIMATE"
	ultimate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ultimate_label.add_theme_font_size_override("font_size", 12)
	ultimate_label.add_theme_color_override("font_color", ULTIMATE_GOLD)
	if pixel_font:
		ultimate_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(ultimate_label)

	# Name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Separator
	var separator = HSeparator.new()
	vbox.add_child(separator)

	# Description (with padding via MarginContainer)
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
	desc_label.custom_minimum_size.x = 250
	desc_label.add_theme_font_size_override("normal_font_size", 15)
	desc_label.add_theme_font_size_override("bold_font_size", 15)
	desc_label.add_theme_color_override("default_color", Color(0.85, 0.8, 0.7))
	if desc_font:
		desc_label.add_theme_font_override("normal_font", desc_font)
	if desc_bold_font:
		desc_label.add_theme_font_override("bold_font", desc_bold_font)
	desc_margin.add_child(desc_label)
	vbox.add_child(desc_margin)

	# Cooldown label
	var cd_label = Label.new()
	cd_label.name = "CooldownLabel"
	cd_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cd_label.add_theme_font_size_override("font_size", 14)
	cd_label.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	if desc_font:
		cd_label.add_theme_font_override("font", desc_font)
	vbox.add_child(cd_label)

	add_child(tooltip_panel)

func _update_tooltip_content() -> void:
	if not tooltip_panel or not ultimate:
		return

	var vbox = tooltip_panel.get_child(0) as VBoxContainer
	if not vbox:
		return

	var name_label = vbox.get_node("NameLabel") as Label
	var desc_margin = vbox.get_node_or_null("DescMargin") as MarginContainer
	var desc_label = desc_margin.get_node("DescLabel") as RichTextLabel if desc_margin else null
	var cd_label = vbox.get_node("CooldownLabel") as Label

	if name_label:
		name_label.text = ultimate.name
	if desc_label:
		desc_label.text = DescriptionFormatter.format(ultimate.description)
	if cd_label:
		cd_label.text = str(int(ultimate.cooldown)) + "s cooldown"

func _show_tooltip() -> void:
	if tooltip_visible or not has_ultimate:
		return

	_update_tooltip_content()

	tooltip_panel.reset_size()
	await get_tree().process_frame

	var tooltip_pos = Vector2.ZERO
	tooltip_pos.x = (BUTTON_SIZE.x - tooltip_panel.size.x) / 2
	tooltip_pos.y = -tooltip_panel.size.y - 12

	var viewport_size = get_viewport().get_visible_rect().size
	var global_pos = global_position + tooltip_pos

	if global_pos.x + tooltip_panel.size.x > viewport_size.x - 10:
		tooltip_pos.x = viewport_size.x - 10 - global_position.x - tooltip_panel.size.x
	if global_pos.x < 10:
		tooltip_pos.x = 10 - global_position.x
	if global_pos.y < 10:
		tooltip_pos.y = BUTTON_SIZE.y + 12

	tooltip_panel.position = tooltip_pos
	tooltip_panel.visible = true
	tooltip_visible = true

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

	var tween = create_tween()
	tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): tooltip_panel.visible = false)

func _on_mouse_entered() -> void:
	_show_tooltip()

func _on_mouse_exited() -> void:
	_hide_tooltip()

func reset_for_new_run() -> void:
	"""Reset button for new game run."""
	ultimate = null
	has_ultimate = false
	is_ready = false
	cooldown_percent = 0.0
	visible = false
	icon_texture.texture = null
