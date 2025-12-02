extends CanvasLayer

# Princesses Screen - Allows players to view unlocked princesses and toggle curses

# State
var selected_index: int = -1
var princess_list: Array = []
var selector_buttons: Array = []
var selector_sprites: Array = []
var animation_timer: float = 0.0

# UI References
var header: PanelContainer
var back_button: Button
var title_label: Label
var coin_display: HBoxContainer
var coin_amount: Label
var preview_panel: PanelContainer
var selector_container: GridContainer
var clear_button: Button
var multiplier_label: Label

# Preview elements
var preview_sprite: Sprite2D
var preview_name_label: Label
var preview_curse_name_label: Label
var preview_curse_desc_label: Label
var preview_bonus_label: Label
var preview_status_label: Label
var toggle_button: Button

# Fonts
var pixel_font: Font = null
var pixelify_font: Font = null

const ANIMATION_SPEED: float = 8.0

func _ready() -> void:
	# Load fonts
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
	if ResourceLoader.exists("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf"):
		pixelify_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	_build_ui()
	_load_princess_data()
	_create_selector_buttons()
	_update_multiplier_display()

	# Keep menu music playing
	if SoundManager:
		SoundManager.play_menu_music()

	# Select first unlocked princess if any
	if PrincessManager and PrincessManager.get_unlocked_count() > 0:
		for i in princess_list.size():
			if PrincessManager.is_princess_unlocked(princess_list[i].id):
				_select_princess(i)
				break

func _process(delta: float) -> void:
	# Animate selector sprites
	animation_timer += delta * ANIMATION_SPEED
	for i in selector_sprites.size():
		if i < princess_list.size():
			var princess = princess_list[i]
			var sprite: Sprite2D = selector_sprites[i]
			if sprite and PrincessManager:
				var anim_info = PrincessManager.get_animation_info(princess.sprite_character, "idle")
				var frame_count = anim_info["frames"]
				var current_frame = int(animation_timer) % frame_count
				var region = PrincessManager.get_sprite_region(princess.sprite_character, "idle", current_frame)
				sprite.region_rect = region

	# Animate preview sprite
	if preview_sprite and selected_index >= 0 and selected_index < princess_list.size():
		var princess = princess_list[selected_index]
		if PrincessManager:
			var anim_info = PrincessManager.get_animation_info(princess.sprite_character, "idle")
			var frame_count = anim_info["frames"]
			var current_frame = int(animation_timer) % frame_count
			var region = PrincessManager.get_sprite_region(princess.sprite_character, "idle", current_frame)
			preview_sprite.region_rect = region

func _build_ui() -> void:
	# Background
	var background = TextureRect.new()
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	if ResourceLoader.exists("res://assets/menu_princess1.png"):
		background.texture = load("res://assets/menu_princess1.png")
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.modulate = Color(1, 1, 1, 0.8)
	add_child(background)

	# Main VBox container (like shop)
	var main_vbox = VBoxContainer.new()
	main_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(main_vbox)

	# Header panel (like shop)
	header = PanelContainer.new()
	header.custom_minimum_size = Vector2(0, 95)
	_style_header()
	main_vbox.add_child(header)

	# Title centered in header
	title_label = Label.new()
	title_label.text = "PRINCESS PROBLEMS"
	title_label.set_anchors_preset(Control.PRESET_CENTER)
	title_label.offset_left = -100
	title_label.offset_right = 100
	title_label.offset_top = 5
	title_label.offset_bottom = 35
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", 20)
	title_label.add_theme_color_override("font_color", Color.WHITE)
	title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	title_label.add_theme_constant_override("shadow_offset_x", 2)
	title_label.add_theme_constant_override("shadow_offset_y", 2)
	header.add_child(title_label)

	# Coins container (right side of header, like shop)
	coin_display = HBoxContainer.new()
	coin_display.set_anchors_preset(Control.PRESET_CENTER_RIGHT)
	coin_display.offset_left = -160
	coin_display.offset_right = -40
	coin_display.offset_top = 5
	coin_display.offset_bottom = 35
	coin_display.add_theme_constant_override("separation", 6)
	coin_display.alignment = BoxContainer.ALIGNMENT_END
	header.add_child(coin_display)

	var coin_icon = Label.new()
	coin_icon.text = "●"
	if pixel_font:
		coin_icon.add_theme_font_override("font", pixel_font)
	coin_icon.add_theme_font_size_override("font_size", 20)
	coin_icon.add_theme_color_override("font_color", Color(1.0, 0.84, 0.0))
	coin_icon.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_display.add_child(coin_icon)

	coin_amount = Label.new()
	coin_amount.text = "0"
	if pixel_font:
		coin_amount.add_theme_font_override("font", pixel_font)
	coin_amount.add_theme_font_size_override("font_size", 16)
	coin_amount.add_theme_color_override("font_color", Color.WHITE)
	coin_amount.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.7))
	coin_amount.add_theme_constant_override("shadow_offset_x", 1)
	coin_amount.add_theme_constant_override("shadow_offset_y", 1)
	coin_amount.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	coin_display.add_child(coin_amount)

	if StatsManager:
		coin_amount.text = str(StatsManager.spendable_coins)

	# Back button (positioned like shop)
	back_button = Button.new()
	back_button.text = "< BACK"
	back_button.offset_left = 100
	back_button.offset_top = 25
	back_button.offset_right = 190
	back_button.offset_bottom = 70
	back_button.pressed.connect(_on_back_pressed)
	_style_back_button(back_button)
	add_child(back_button)

	# Curse explanation (funny copy)
	var explanation_label = Label.new()
	explanation_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	explanation_label.offset_top = 100
	explanation_label.offset_bottom = 118
	explanation_label.offset_left = 20
	explanation_label.offset_right = -20
	explanation_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	explanation_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		explanation_label.add_theme_font_override("font", pixel_font)
	explanation_label.add_theme_font_size_override("font_size", 14)
	explanation_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.95))
	explanation_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	explanation_label.add_theme_constant_override("shadow_offset_x", 1)
	explanation_label.add_theme_constant_override("shadow_offset_y", 1)
	explanation_label.text = "Enable princesses to make your life harder (but earn more stuff)"
	add_child(explanation_label)

	# Multiplier display (above the main content)
	multiplier_label = Label.new()
	multiplier_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	multiplier_label.offset_top = 118
	multiplier_label.offset_bottom = 140
	multiplier_label.offset_left = 20
	multiplier_label.offset_right = -20
	multiplier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	multiplier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		multiplier_label.add_theme_font_override("font", pixel_font)
	multiplier_label.add_theme_font_size_override("font_size", 14)
	multiplier_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	multiplier_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	multiplier_label.add_theme_constant_override("shadow_offset_x", 2)
	multiplier_label.add_theme_constant_override("shadow_offset_y", 2)
	add_child(multiplier_label)

	# Main container (positioned below header and multiplier)
	var main_container = HBoxContainer.new()
	main_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	main_container.offset_top = 145
	main_container.offset_left = 20
	main_container.offset_right = -20
	main_container.offset_bottom = -80
	main_container.add_theme_constant_override("separation", 20)
	main_container.alignment = BoxContainer.ALIGNMENT_CENTER
	add_child(main_container)

	# Left side - Preview panel (shrink to fit content)
	var left_side = VBoxContainer.new()
	left_side.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	left_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	main_container.add_child(left_side)

	preview_panel = PanelContainer.new()
	preview_panel.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	preview_panel.custom_minimum_size = Vector2(300, 380)
	preview_panel.set_deferred("size", Vector2(300, 380))
	_style_preview_panel()
	left_side.add_child(preview_panel)
	_setup_preview_content()

	# Right side - Selector grid + toggle button
	var right_side = VBoxContainer.new()
	right_side.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	right_side.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	right_side.add_theme_constant_override("separation", 15)
	main_container.add_child(right_side)

	# Selector grid (no scroll needed for 20 princesses in 5 columns = 4 rows)
	selector_container = GridContainer.new()
	selector_container.columns = 5
	selector_container.add_theme_constant_override("h_separation", 10)
	selector_container.add_theme_constant_override("v_separation", 10)
	right_side.add_child(selector_container)

	# Toggle button (below princess grid)
	toggle_button = Button.new()
	toggle_button.custom_minimum_size = Vector2(370, 50)
	toggle_button.pressed.connect(_on_toggle_pressed)
	right_side.add_child(toggle_button)

	# Bottom bar with clear button only
	var bottom_bar = HBoxContainer.new()
	bottom_bar.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bottom_bar.offset_top = -70
	bottom_bar.offset_left = 20
	bottom_bar.offset_right = -20
	bottom_bar.add_theme_constant_override("separation", 20)
	bottom_bar.alignment = BoxContainer.ALIGNMENT_END
	add_child(bottom_bar)

	# Clear all button (hidden for now)
	clear_button = Button.new()
	clear_button.text = "CLEAR ALL"
	clear_button.custom_minimum_size = Vector2(120, 40)
	clear_button.pressed.connect(_on_clear_all_pressed)
	_style_gray_button(clear_button)
	clear_button.visible = false
	bottom_bar.add_child(clear_button)

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.0)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 0.0)
	style.content_margin_left = 60
	style.content_margin_right = 60
	header.add_theme_stylebox_override("panel", style)

func _style_preview_panel() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.98)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.4, 0.25, 0.45, 1)
	style.set_corner_radius_all(12)
	# Add extra padding to make the panel ~20% taller
	style.content_margin_top = 30
	style.content_margin_bottom = 30
	style.content_margin_left = 15
	style.content_margin_right = 15
	preview_panel.add_theme_stylebox_override("panel", style)

func _setup_preview_content() -> void:
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 12)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	preview_panel.add_child(vbox)

	# Sprite container
	var sprite_center = CenterContainer.new()
	sprite_center.custom_minimum_size = Vector2(0, 100)
	vbox.add_child(sprite_center)

	var sprite_holder = Control.new()
	sprite_holder.custom_minimum_size = Vector2(96, 96)
	sprite_center.add_child(sprite_holder)

	preview_sprite = Sprite2D.new()
	preview_sprite.centered = true
	preview_sprite.position = Vector2(48, 48)
	preview_sprite.scale = Vector2(2.5, 2.5)
	sprite_holder.add_child(preview_sprite)

	# Name label
	preview_name_label = Label.new()
	preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		preview_name_label.add_theme_font_override("font", pixel_font)
	preview_name_label.add_theme_font_size_override("font_size", 16)
	preview_name_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.9))
	vbox.add_child(preview_name_label)

	# Curse name
	preview_curse_name_label = Label.new()
	preview_curse_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		preview_curse_name_label.add_theme_font_override("font", pixel_font)
	preview_curse_name_label.add_theme_font_size_override("font_size", 12)
	preview_curse_name_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.6))
	vbox.add_child(preview_curse_name_label)

	# Curse description
	preview_curse_desc_label = Label.new()
	preview_curse_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_curse_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	preview_curse_desc_label.custom_minimum_size = Vector2(200, 40)
	preview_curse_desc_label.add_theme_font_size_override("font_size", 11)
	preview_curse_desc_label.add_theme_color_override("font_color", Color(0.75, 0.75, 0.8))
	vbox.add_child(preview_curse_desc_label)

	# Bonus label
	preview_bonus_label = Label.new()
	preview_bonus_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		preview_bonus_label.add_theme_font_override("font", pixel_font)
	preview_bonus_label.add_theme_font_size_override("font_size", 12)
	preview_bonus_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))
	vbox.add_child(preview_bonus_label)

	# Status label
	preview_status_label = Label.new()
	preview_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		preview_status_label.add_theme_font_override("font", pixel_font)
	preview_status_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(preview_status_label)

	# Add 20px margin below status label
	var status_spacer = Control.new()
	status_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(status_spacer)

func _load_princess_data() -> void:
	if not PrincessManager:
		return
	princess_list = PrincessManager.get_all_princesses()

func _create_selector_buttons() -> void:
	selector_buttons.clear()
	selector_sprites.clear()

	for child in selector_container.get_children():
		child.queue_free()

	for i in princess_list.size():
		var princess = princess_list[i]
		var is_unlocked = PrincessManager.is_princess_unlocked(princess.id) if PrincessManager else false

		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(64, 64)

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.07, 0.1, 0.95)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2

		if is_unlocked:
			var is_enabled = PrincessManager.is_curse_enabled(princess.id) if PrincessManager else false
			if is_enabled:
				style.border_color = Color(0.9, 0.5, 0.6)  # Pink for enabled
				style.bg_color = Color(0.15, 0.08, 0.12, 0.98)
			else:
				style.border_color = Color(0.4, 0.35, 0.45)  # Gray for unlocked but disabled
		else:
			style.border_color = Color(0.2, 0.2, 0.25)
			style.bg_color = Color(0.05, 0.05, 0.07, 0.9)

		style.set_corner_radius_all(6)
		panel.add_theme_stylebox_override("panel", style)

		if is_unlocked:
			# Show sprite
			var sprite = Sprite2D.new()
			sprite.texture = PrincessManager.get_sprite_sheet_for_character(princess.sprite_character)
			sprite.region_enabled = true
			var region = PrincessManager.get_sprite_region(princess.sprite_character, "idle", 0)
			sprite.region_rect = region
			sprite.scale = Vector2(1.8, 1.8)
			sprite.centered = true
			sprite.position = Vector2(32, 32)

			var sprite_holder = Control.new()
			sprite_holder.custom_minimum_size = Vector2(64, 64)
			sprite_holder.add_child(sprite)
			panel.add_child(sprite_holder)
			selector_sprites.append(sprite)
		else:
			# Show locked indicator
			var locked_label = Label.new()
			locked_label.text = "?"
			locked_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			locked_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
			if pixelify_font:
				locked_label.add_theme_font_override("font", pixelify_font)
			locked_label.add_theme_font_size_override("font_size", 28)
			locked_label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35))

			var center = CenterContainer.new()
			center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			center.size_flags_vertical = Control.SIZE_EXPAND_FILL
			center.add_child(locked_label)
			panel.add_child(center)
			selector_sprites.append(null)

		# Button overlay
		var button = Button.new()
		button.flat = true
		button.set_anchors_preset(Control.PRESET_FULL_RECT)
		button.pressed.connect(_on_princess_selected.bind(i))
		button.disabled = not is_unlocked
		panel.add_child(button)

		selector_container.add_child(panel)
		selector_buttons.append({"panel": panel, "button": button})

func _select_princess(index: int) -> void:
	if index < 0 or index >= princess_list.size():
		return

	var princess = princess_list[index]
	if not PrincessManager or not PrincessManager.is_princess_unlocked(princess.id):
		return

	selected_index = index

	# Update preview
	if preview_sprite and PrincessManager:
		preview_sprite.texture = PrincessManager.get_sprite_sheet_for_character(princess.sprite_character)
		preview_sprite.region_enabled = true
		var region = PrincessManager.get_sprite_region(princess.sprite_character, "idle", 0)
		preview_sprite.region_rect = region

	preview_name_label.text = princess.name
	preview_curse_name_label.text = "Curse: %s" % princess.curse_name
	preview_curse_desc_label.text = princess.curse_description

	preview_bonus_label.text = "+1x Points & Coins"

	_update_toggle_button()
	_update_selector_visuals()

func _update_toggle_button() -> void:
	if selected_index < 0 or selected_index >= princess_list.size():
		toggle_button.visible = false
		preview_status_label.visible = false
		return

	toggle_button.visible = true
	preview_status_label.visible = true

	var princess = princess_list[selected_index]
	var is_enabled = PrincessManager.is_curse_enabled(princess.id) if PrincessManager else false

	if is_enabled:
		toggle_button.text = "DISABLE %s" % princess.curse_name.to_upper()
		_style_red_button(toggle_button)
		preview_status_label.text = "ACTIVE"
		preview_status_label.add_theme_color_override("font_color", Color(0.9, 0.5, 0.6))
	else:
		toggle_button.text = "ENABLE %s" % princess.curse_name.to_upper()
		_style_pink_button(toggle_button)
		preview_status_label.text = "INACTIVE"
		preview_status_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55))

func _update_selector_visuals() -> void:
	for i in selector_buttons.size():
		if i >= princess_list.size():
			continue

		var princess = princess_list[i]
		var panel = selector_buttons[i]["panel"]
		var is_unlocked = PrincessManager.is_princess_unlocked(princess.id) if PrincessManager else false

		if not is_unlocked:
			continue

		var style = StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.07, 0.1, 0.95)
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.set_corner_radius_all(6)

		var is_enabled = PrincessManager.is_curse_enabled(princess.id) if PrincessManager else false
		var is_selected = (i == selected_index)

		if is_enabled:
			style.border_color = Color(0.9, 0.5, 0.6)
			style.bg_color = Color(0.15, 0.08, 0.12, 0.98)
		else:
			style.border_color = Color(0.4, 0.35, 0.45)

		if is_selected:
			# Use bright yellow border
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.border_color = Color(1.0, 0.95, 0.2)  # Bright yellow

		panel.add_theme_stylebox_override("panel", style)

func _update_multiplier_display() -> void:
	if not PrincessManager:
		multiplier_label.text = "No curses active"
		return

	var count = PrincessManager.get_enabled_curse_count()
	if count == 0:
		multiplier_label.text = "No curses active"
		multiplier_label.add_theme_color_override("font_color", Color.WHITE)
	else:
		var total_mult = PrincessManager.get_total_bonus_multiplier()
		var mult_str = "%.1fx" % total_mult if fmod(total_mult, 1.0) != 0 else "%dx" % int(total_mult)
		multiplier_label.text = "%d curse%s active: %s Points & Coins" % [count, "s" if count > 1 else "", mult_str]
		multiplier_label.add_theme_color_override("font_color", Color(0.4, 0.9, 0.5))

func _on_princess_selected(index: int) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	_select_princess(index)

func _on_toggle_pressed() -> void:
	if selected_index < 0 or selected_index >= princess_list.size():
		return

	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.medium()

	var princess = princess_list[selected_index]
	if PrincessManager:
		PrincessManager.toggle_curse(princess.id)

	_update_toggle_button()
	_update_selector_visuals()
	_update_multiplier_display()

func _on_clear_all_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if PrincessManager:
		PrincessManager.disable_all_curses()

	_update_toggle_button()
	_update_selector_visuals()
	_update_multiplier_display()

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _style_back_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.25, 0.25, 0.3, 1)
	style_normal.border_width_left = 2
	style_normal.border_width_right = 2
	style_normal.border_width_top = 2
	style_normal.border_width_bottom = 4
	style_normal.border_color = Color(0.15, 0.15, 0.2, 1)
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6
	style_normal.content_margin_left = 16
	style_normal.content_margin_right = 16

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.35, 0.35, 0.4, 1)
	style_hover.border_width_left = 2
	style_hover.border_width_right = 2
	style_hover.border_width_top = 2
	style_hover.border_width_bottom = 4
	style_hover.border_color = Color(0.2, 0.2, 0.25, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6
	style_hover.content_margin_left = 16
	style_hover.content_margin_right = 16

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)

	button.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 12)

func _style_pink_button(button: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.7, 0.4, 0.6, 1)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 6
	style.border_color = Color(0.4, 0.2, 0.35, 1)
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.8, 0.5, 0.7, 1)
	button.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.55, 0.3, 0.5, 1)
	pressed.border_width_top = 5
	pressed.border_width_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color.WHITE)

func _style_red_button(button: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.6, 0.25, 0.3, 1)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 6
	style.border_color = Color(0.35, 0.12, 0.18, 1)
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.7, 0.35, 0.4, 1)
	button.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.5, 0.2, 0.25, 1)
	pressed.border_width_top = 5
	pressed.border_width_bottom = 4
	button.add_theme_stylebox_override("pressed", pressed)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 12)
	button.add_theme_color_override("font_color", Color.WHITE)

func _style_gray_button(button: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.35, 0.33, 0.4, 1)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 5
	style.border_color = Color(0.2, 0.18, 0.25, 1)
	style.set_corner_radius_all(6)
	button.add_theme_stylebox_override("normal", style)

	var hover = style.duplicate()
	hover.bg_color = Color(0.45, 0.43, 0.5, 1)
	button.add_theme_stylebox_override("hover", hover)

	var pressed = style.duplicate()
	pressed.bg_color = Color(0.28, 0.26, 0.32, 1)
	pressed.border_width_top = 4
	pressed.border_width_bottom = 3
	button.add_theme_stylebox_override("pressed", pressed)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 10)
	button.add_theme_color_override("font_color", Color(0.85, 0.85, 0.9))
