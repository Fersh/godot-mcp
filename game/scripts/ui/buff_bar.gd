extends CanvasLayer

# Buff bar - displays active temporary buffs below the XP bar
# Shows icons with cooldown overlay and tooltip on hold

const ICON_SIZE := Vector2(40, 40)
const ICON_SPACING := 8
const MARGIN_TOP := 70  # Below XP bar
const LONG_PRESS_TIME := 0.3
const RUNE_BG_PATH := "res://assets/sprites/runes/Background/runes+bricks+effects/"
const RUNE_BG_COUNT := 48

var player: Node2D = null
var rune_textures: Array[Texture2D] = []
var buff_container: HBoxContainer = null
var buff_icons: Dictionary = {}  # buff_id -> Control
var pixel_font: Font = null

# Tooltip
var tooltip_panel: PanelContainer = null
var tooltip_visible: bool = false
var held_buff_id: String = ""
var hold_timer: float = 0.0
var is_holding: bool = false

func _ready() -> void:
	layer = 45  # Below ability bar but above game

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load rune background textures
	_load_rune_textures()

	_create_ui()
	_create_tooltip()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("buff_changed", _on_buff_changed)

func _load_rune_textures() -> void:
	# Load all rune background textures
	for i in range(1, RUNE_BG_COUNT + 1):
		var path = RUNE_BG_PATH + "Icon%d.png" % i
		if ResourceLoader.exists(path):
			var texture = load(path)
			if texture:
				rune_textures.append(texture)

func _get_random_rune_texture() -> Texture2D:
	if rune_textures.size() > 0:
		return rune_textures[randi() % rune_textures.size()]
	return null

func _create_ui() -> void:
	# Center container at top
	var center_container = Control.new()
	center_container.name = "CenterContainer"
	center_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center_container.offset_top = MARGIN_TOP
	center_container.offset_bottom = MARGIN_TOP + ICON_SIZE.y + 20
	add_child(center_container)

	# HBox for buff icons (centered)
	buff_container = HBoxContainer.new()
	buff_container.name = "BuffContainer"
	buff_container.alignment = BoxContainer.ALIGNMENT_CENTER
	buff_container.add_theme_constant_override("separation", ICON_SPACING)
	buff_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	buff_container.offset_top = 0
	buff_container.offset_bottom = ICON_SIZE.y
	center_container.add_child(buff_container)

func _create_tooltip() -> void:
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "BuffTooltip"
	tooltip_panel.visible = false
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 100

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	style.border_color = Color(0.5, 0.5, 0.5)
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(10)
	tooltip_panel.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)
	tooltip_panel.add_child(vbox)

	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 12)
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 10)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	var time_label = Label.new()
	time_label.name = "TimeLabel"
	time_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	time_label.add_theme_font_size_override("font_size", 9)
	time_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if pixel_font:
		time_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(time_label)

	add_child(tooltip_panel)

func _on_buff_changed(buffs: Dictionary) -> void:
	# Remove icons for expired buffs
	var to_remove = []
	for buff_id in buff_icons:
		if not buffs.has(buff_id):
			to_remove.append(buff_id)

	for buff_id in to_remove:
		if buff_icons.has(buff_id):
			buff_icons[buff_id].queue_free()
			buff_icons.erase(buff_id)

	# Add/update icons for active buffs
	for buff_id in buffs:
		var buff_data = buffs[buff_id]
		if not buff_icons.has(buff_id):
			_create_buff_icon(buff_id, buff_data)
		else:
			_update_buff_icon(buff_id, buff_data)

func _create_buff_icon(buff_id: String, buff_data: Dictionary) -> void:
	var icon_container = Control.new()
	icon_container.name = "Buff_" + buff_id
	icon_container.custom_minimum_size = ICON_SIZE
	icon_container.mouse_filter = Control.MOUSE_FILTER_STOP

	# Background - use rune texture if available
	var rune_texture = _get_random_rune_texture()
	if rune_texture:
		var bg = TextureRect.new()
		bg.name = "Background"
		bg.texture = rune_texture
		bg.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		bg.size = ICON_SIZE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Tint with buff color
		bg.modulate = buff_data.get("color", Color.WHITE).lerp(Color.WHITE, 0.5)
		icon_container.add_child(bg)
	else:
		# Fallback to ColorRect
		var bg = ColorRect.new()
		bg.name = "Background"
		bg.color = Color(0.1, 0.1, 0.15, 0.9)
		bg.size = ICON_SIZE
		bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_container.add_child(bg)

	# Border (colored by buff)
	var border = ColorRect.new()
	border.name = "Border"
	border.color = buff_data.get("color", Color.WHITE)
	border.size = ICON_SIZE
	border.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(border)

	# Inner - use same rune texture with darker tint
	if rune_texture:
		var inner = TextureRect.new()
		inner.name = "Inner"
		inner.texture = rune_texture
		inner.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		inner.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		inner.position = Vector2(3, 3)
		inner.size = ICON_SIZE - Vector2(6, 6)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		inner.modulate = buff_data.get("color", Color.WHITE).darkened(0.3)
		icon_container.add_child(inner)
	else:
		var inner = ColorRect.new()
		inner.name = "Inner"
		inner.color = Color(0.15, 0.15, 0.2, 0.95)
		inner.position = Vector2(3, 3)
		inner.size = ICON_SIZE - Vector2(6, 6)
		inner.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_container.add_child(inner)

	# Letter label (first letter of buff name)
	var letter = Label.new()
	letter.name = "Letter"
	var buff_name = buff_data.get("name", "?")
	letter.text = buff_name.substr(0, 1).to_upper()
	letter.add_theme_font_size_override("font_size", 18)
	letter.add_theme_color_override("font_color", buff_data.get("color", Color.WHITE))
	if pixel_font:
		letter.add_theme_font_override("font", pixel_font)
	letter.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	letter.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	letter.size = ICON_SIZE
	letter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(letter)

	# Stack counter (for buffs with stacks like "Flow x3")
	var stack_label = Label.new()
	stack_label.name = "StackLabel"
	stack_label.add_theme_font_size_override("font_size", 10)
	stack_label.add_theme_color_override("font_color", Color.WHITE)
	stack_label.add_theme_color_override("font_shadow_color", Color.BLACK)
	stack_label.add_theme_constant_override("shadow_offset_x", 1)
	stack_label.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		stack_label.add_theme_font_override("font", pixel_font)
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	stack_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	stack_label.position = Vector2(0, 2)
	stack_label.size = Vector2(ICON_SIZE.x - 4, 14)
	stack_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Extract stack count from name like "Flow x3"
	if " x" in buff_name:
		var parts = buff_name.split(" x")
		if parts.size() > 1:
			stack_label.text = "x" + parts[1]
	icon_container.add_child(stack_label)

	# Cooldown overlay (drawn on top, partially transparent)
	var cooldown_overlay = ColorRect.new()
	cooldown_overlay.name = "CooldownOverlay"
	cooldown_overlay.color = Color(0.0, 0.0, 0.0, 0.6)
	cooldown_overlay.position = Vector2(3, 3)
	cooldown_overlay.size = Vector2(ICON_SIZE.x - 6, 0)  # Start empty
	cooldown_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(cooldown_overlay)

	# Timer label
	var timer_label = Label.new()
	timer_label.name = "TimerLabel"
	timer_label.add_theme_font_size_override("font_size", 10)
	timer_label.add_theme_color_override("font_color", Color.WHITE)
	if pixel_font:
		timer_label.add_theme_font_override("font", pixel_font)
	timer_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	timer_label.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
	timer_label.position = Vector2(0, ICON_SIZE.y - 14)
	timer_label.size = Vector2(ICON_SIZE.x, 14)
	timer_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon_container.add_child(timer_label)

	# Store buff data in icon
	icon_container.set_meta("buff_id", buff_id)
	icon_container.set_meta("buff_data", buff_data)

	# Connect hover signals for tooltip
	icon_container.mouse_entered.connect(_on_icon_mouse_entered.bind(buff_id))
	icon_container.mouse_exited.connect(_on_icon_mouse_exited)

	# Connect input for touch/long press (mobile)
	icon_container.gui_input.connect(_on_icon_input.bind(buff_id))

	buff_container.add_child(icon_container)
	buff_icons[buff_id] = icon_container

	# Animate appearance
	icon_container.scale = Vector2(0.5, 0.5)
	icon_container.modulate.a = 0.0
	icon_container.pivot_offset = ICON_SIZE / 2
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(icon_container, "scale", Vector2.ONE, 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	tween.tween_property(icon_container, "modulate:a", 1.0, 0.15)

	_update_buff_icon(buff_id, buff_data)

func _update_buff_icon(buff_id: String, buff_data: Dictionary) -> void:
	if not buff_icons.has(buff_id):
		return

	var icon = buff_icons[buff_id]
	var timer = buff_data.get("timer", 0.0)
	var duration = buff_data.get("duration", 1.0)
	var is_conditional = timer < 0  # Conditional buffs have timer = -1
	var percent = 1.0 if is_conditional else (timer / duration if duration > 0 else 0.0)

	# Update cooldown overlay (fills from bottom as time runs out)
	# Hide overlay for conditional buffs (always active while condition met)
	var overlay = icon.get_node_or_null("CooldownOverlay")
	if overlay:
		var fill_height = (ICON_SIZE.y - 6) * (1.0 - percent)
		overlay.size.y = fill_height

	# Update timer label (hide for conditional buffs)
	var timer_label = icon.get_node_or_null("TimerLabel")
	if timer_label:
		if is_conditional:
			timer_label.visible = false
		else:
			timer_label.visible = true
			timer_label.text = str(int(ceil(timer))) + "s"

	# Update stack label for buffs with stacks
	var stack_label = icon.get_node_or_null("StackLabel")
	if stack_label:
		var buff_name = buff_data.get("name", "")
		if " x" in buff_name:
			var parts = buff_name.split(" x")
			if parts.size() > 1:
				stack_label.text = "x" + parts[1]
		else:
			stack_label.text = ""

	# Update stored data
	icon.set_meta("buff_data", buff_data)

func _on_icon_mouse_entered(buff_id: String) -> void:
	# Show tooltip immediately on hover
	_show_tooltip(buff_id)

func _on_icon_mouse_exited() -> void:
	# Hide tooltip when mouse leaves
	_hide_tooltip()

func _on_icon_input(event: InputEvent, buff_id: String) -> void:
	# Show tooltip immediately on touch/click
	if event is InputEventScreenTouch or event is InputEventMouseButton:
		var pressed = false
		if event is InputEventScreenTouch:
			pressed = event.pressed
		elif event is InputEventMouseButton:
			pressed = event.pressed and event.button_index == MOUSE_BUTTON_LEFT

		if pressed:
			is_holding = true
			held_buff_id = buff_id
			hold_timer = 0.0
			# Show tooltip immediately on press
			_show_tooltip(buff_id)
		else:
			is_holding = false
			held_buff_id = ""
			_hide_tooltip()

func _process(delta: float) -> void:
	# Update hold timer for tooltip
	if is_holding and held_buff_id != "":
		hold_timer += delta
		if hold_timer >= LONG_PRESS_TIME and not tooltip_visible:
			_show_tooltip(held_buff_id)

	# Update buff timers in icons
	if player and player.active_buffs.size() > 0:
		for buff_id in buff_icons:
			if player.active_buffs.has(buff_id):
				_update_buff_icon(buff_id, player.active_buffs[buff_id])

func _show_tooltip(buff_id: String) -> void:
	if not buff_icons.has(buff_id):
		return

	var icon = buff_icons[buff_id]
	var buff_data = icon.get_meta("buff_data")

	# Update tooltip content
	var vbox = tooltip_panel.get_child(0)
	var name_label = vbox.get_node("NameLabel") as Label
	var desc_label = vbox.get_node("DescLabel") as Label
	var time_label = vbox.get_node("TimeLabel") as Label

	if name_label:
		name_label.text = buff_data.get("name", "Buff")
		name_label.add_theme_color_override("font_color", buff_data.get("color", Color.WHITE))
	if desc_label:
		desc_label.text = buff_data.get("description", "")
	if time_label:
		var timer = buff_data.get("timer", 0.0)
		time_label.text = "%ds remaining" % int(ceil(timer))

	# Update border color
	var style = tooltip_panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.border_color = buff_data.get("color", Color.WHITE)
	tooltip_panel.add_theme_stylebox_override("panel", style)

	# Position below the icon
	tooltip_panel.reset_size()
	await get_tree().process_frame

	var icon_global = icon.global_position
	var tooltip_x = icon_global.x + (ICON_SIZE.x - tooltip_panel.size.x) / 2
	var tooltip_y = icon_global.y + ICON_SIZE.y + 10

	# Clamp to screen
	var viewport_size = get_viewport().get_visible_rect().size
	tooltip_x = clamp(tooltip_x, 10, viewport_size.x - tooltip_panel.size.x - 10)

	tooltip_panel.global_position = Vector2(tooltip_x, tooltip_y)
	tooltip_panel.visible = true
	tooltip_visible = true

	# Animate
	tooltip_panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(tooltip_panel, "modulate:a", 1.0, 0.15)

func _hide_tooltip() -> void:
	if not tooltip_visible:
		return

	tooltip_visible = false
	var tween = create_tween()
	tween.tween_property(tooltip_panel, "modulate:a", 0.0, 0.1)
	tween.tween_callback(func(): tooltip_panel.visible = false)

func reset_for_new_run() -> void:
	# Clear all buff icons
	for buff_id in buff_icons:
		buff_icons[buff_id].queue_free()
	buff_icons.clear()
	_hide_tooltip()
