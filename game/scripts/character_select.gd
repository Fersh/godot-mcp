extends CanvasLayer

@onready var header: PanelContainer = $Header
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $Header/TitleLabel
@onready var preview_panel: PanelContainer = $CenterContainer/PreviewPanel
@onready var selector_container: HBoxContainer = $SelectorContainer
@onready var select_button: Button = $SelectButton

# Preview elements (created dynamically)
var preview_sprite: Sprite2D
var preview_name_label: Label
var preview_class_label: Label
var preview_desc_label: Label
var preview_stats_container: VBoxContainer
var preview_passive_container: VBoxContainer

var selector_buttons: Array = []
var selected_index: int = 0
var animation_timer: float = 0.0
var characters_list: Array = []

# Animation state
var is_playing_attack: bool = false
var attack_display_timer: float = 0.0
const IDLE_DURATION: float = 4.0  # Seconds of idle before attack
const ATTACK_ANIM_SPEED: float = 12.0

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	select_button.pressed.connect(_on_select_pressed)

	_style_header()
	_style_golden_button(select_button)
	_style_back_button(back_button)

	_setup_preview_panel()
	_create_selector_buttons()
	_select_current_character()

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 1)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.content_margin_left = 30
	style.content_margin_right = 30
	header.add_theme_stylebox_override("panel", style)

func _process(delta: float) -> void:
	# Update animation for preview sprite
	if preview_sprite and selected_index < characters_list.size():
		var char_data: CharacterData = characters_list[selected_index]

		if is_playing_attack:
			# Playing attack animation
			animation_timer += delta * ATTACK_ANIM_SPEED
			var frame_count = char_data.frames_attack
			var current_frame = int(animation_timer) % frame_count
			preview_sprite.frame = char_data.row_attack * char_data.hframes + current_frame

			# Check if attack animation completed
			if animation_timer >= frame_count:
				is_playing_attack = false
				animation_timer = 0.0
				attack_display_timer = 0.0
		else:
			# Playing idle animation
			animation_timer += delta * 8.0
			var frame_count = char_data.frames_idle
			var current_frame = int(animation_timer) % frame_count
			preview_sprite.frame = char_data.row_idle * char_data.hframes + current_frame

			# Check if it's time to play attack
			attack_display_timer += delta
			if attack_display_timer >= IDLE_DURATION:
				is_playing_attack = true
				animation_timer = 0.0

func _setup_preview_panel() -> void:
	# Style the preview panel - darker and less transparent like equipment screen
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.9)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	preview_panel.add_theme_stylebox_override("panel", style)

	# Create internal layout - use CenterContainer to center everything horizontally
	var outer_center = CenterContainer.new()
	outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.add_child(outer_center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)  # We'll add manual spacers
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_center.add_child(vbox)

	# Sprite preview - fixed height to match mage (32px * 2.5 = 80px)
	var sprite_center = CenterContainer.new()
	sprite_center.custom_minimum_size = Vector2(300, 100)
	sprite_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sprite_center)

	# Use a Control as parent to center the Sprite2D properly
	var sprite_holder = Control.new()
	sprite_holder.custom_minimum_size = Vector2(100, 100)
	sprite_holder.clip_contents = true
	sprite_center.add_child(sprite_holder)

	preview_sprite = Sprite2D.new()
	preview_sprite.centered = true
	preview_sprite.position = Vector2(50, 50)  # Center within the holder
	sprite_holder.add_child(preview_sprite)

	# Spacer after sprite
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer1)

	# Character name below sprite
	preview_name_label = Label.new()
	preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name_label.add_theme_font_size_override("font_size", 18)
	preview_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	vbox.add_child(preview_name_label)

	# Class label below name (same styling as STATS header)
	preview_class_label = Label.new()
	preview_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_class_label.add_theme_font_size_override("font_size", 14)
	preview_class_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
	vbox.add_child(preview_class_label)

	# Spacer after class
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer2)

	# Description - centered (above stats)
	var desc_container = MarginContainer.new()
	desc_container.custom_minimum_size = Vector2(340, 0)
	desc_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(desc_container)
	preview_desc_label = Label.new()
	preview_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_desc_label.add_theme_font_size_override("font_size", 12)
	preview_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	desc_container.add_child(preview_desc_label)

	# Spacer after description
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer3)

	# Stats section (below description)
	preview_stats_container = VBoxContainer.new()
	preview_stats_container.add_theme_constant_override("separation", 4)
	vbox.add_child(preview_stats_container)

	# Spacer after stats
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer4)

	# Passive section
	preview_passive_container = VBoxContainer.new()
	preview_passive_container.add_theme_constant_override("separation", 3)
	vbox.add_child(preview_passive_container)

	# Spacer after passive (bottom padding)
	var spacer5 = Control.new()
	spacer5.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer5)

func _create_selector_buttons() -> void:
	var all_chars = CharacterManager.get_all_characters()

	# Reorder to: ranger, knight, monk, mage, beast
	var order = ["archer", "knight", "monk", "mage", "beast"]
	characters_list = []
	for id in order:
		for char_data in all_chars:
			if char_data.id == id:
				characters_list.append(char_data)
				break

	for i in characters_list.size():
		var char_data: CharacterData = characters_list[i]
		var btn = _create_selector_button(char_data, i)
		selector_container.add_child(btn)
		selector_buttons.append(btn)

	# Add 2 locked placeholder slots
	selector_container.add_child(_create_placeholder_button())
	selector_container.add_child(_create_placeholder_button())

func _create_selector_button(char_data: CharacterData, index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(50, 50)  # Small square
	panel.set_meta("index", index)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.9)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	# Add character sprite preview in the square - use Control holder to center properly
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)

	var sprite_holder = Control.new()
	sprite_holder.custom_minimum_size = Vector2(46, 46)
	sprite_holder.clip_contents = true
	center.add_child(sprite_holder)

	var sprite = Sprite2D.new()
	sprite.texture = char_data.sprite_texture
	sprite.hframes = char_data.hframes
	sprite.vframes = char_data.vframes
	sprite.frame = char_data.row_idle * char_data.hframes
	sprite.centered = true
	# Manual scales to match mage visually
	var sprite_scale = 1.3
	var sprite_pos = Vector2(23, 23)
	match char_data.id:
		"knight":
			sprite_scale = 1.1
		"monk":
			sprite_scale = 1.1
		"beast":
			sprite_scale = 0.5
			sprite_pos = Vector2(23, 23)
			# Apply beast's sprite offset to center it properly
			sprite.offset = char_data.sprite_offset
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position = sprite_pos
	sprite_holder.add_child(sprite)

	# Clickable button overlay
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.pressed.connect(_on_selector_pressed.bind(index))
	panel.add_child(button)

	return panel

func _create_placeholder_button() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(50, 50)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.2, 0.2, 0.25, 0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	# Add a "?" label in the center
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)

	var label = Label.new()
	label.text = "?"
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.3, 0.3, 0.35, 0.6))
	center.add_child(label)

	return panel

func _select_current_character() -> void:
	var current = CharacterManager.get_selected_character()
	for i in characters_list.size():
		var char_data: CharacterData = characters_list[i]
		if char_data.id == current.id:
			_set_selected(i)
			break

func _set_selected(index: int) -> void:
	selected_index = index
	animation_timer = 0.0
	attack_display_timer = 0.0
	is_playing_attack = false

	# Update selector button highlights
	for i in selector_buttons.size():
		var panel: PanelContainer = selector_buttons[i]
		var style = panel.get_theme_stylebox("panel").duplicate()

		if i == index:
			style.border_color = Color(0.95, 0.75, 0.2, 1)  # Gold
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.bg_color = Color(0.12, 0.10, 0.08, 0.95)
		else:
			style.border_color = Color(0.15, 0.14, 0.2, 1)
			style.border_width_left = 2
			style.border_width_right = 2
			style.border_width_top = 2
			style.border_width_bottom = 2
			style.bg_color = Color(0.06, 0.055, 0.09, 0.9)

		panel.add_theme_stylebox_override("panel", style)

	# Update preview
	_update_preview()

func _update_preview() -> void:
	if selected_index >= characters_list.size():
		return

	var char_data: CharacterData = characters_list[selected_index]

	# Update name
	preview_name_label.text = char_data.display_name

	# Update class label
	var class_type_text = "Ranger"
	match char_data.id:
		"archer":
			class_type_text = "Ranger"
		"knight":
			class_type_text = "Knight"
		"beast":
			class_type_text = "???"
		"mage":
			class_type_text = "Mage"
		"monk":
			class_type_text = "Monk"
	preview_class_label.text = class_type_text

	# Update sprite
	preview_sprite.texture = char_data.sprite_texture
	preview_sprite.hframes = char_data.hframes
	preview_sprite.vframes = char_data.vframes
	preview_sprite.frame = char_data.row_idle * char_data.hframes

	# Manual scales to match mage visually
	var preview_scale = 2.5
	var preview_pos = Vector2(50, 50)
	var preview_offset = Vector2(0, 0)
	match char_data.id:
		"knight":
			preview_scale = 2.1
		"monk":
			preview_scale = 2.1
		"beast":
			preview_scale = 1.2
			preview_pos = Vector2(50, 50)
			# Apply beast's sprite offset to center it properly
			preview_offset = char_data.sprite_offset
	preview_sprite.scale = Vector2(preview_scale, preview_scale)
	preview_sprite.position = preview_pos
	preview_sprite.offset = preview_offset

	# Update description
	preview_desc_label.text = char_data.description

	# Update stats
	for child in preview_stats_container.get_children():
		child.queue_free()

	# Fixed width container for stats to keep alignment consistent
	var stats_box = VBoxContainer.new()
	stats_box.custom_minimum_size = Vector2(150, 0)
	stats_box.add_theme_constant_override("separation", 2)
	preview_stats_container.add_child(stats_box)

	var attack_type_text = "Ranged" if char_data.attack_type == CharacterData.AttackType.RANGED else "Melee"
	_add_stat_row_to_container(stats_box, "Type", attack_type_text, Color(0.9, 0.9, 0.9, 1))

	_add_stat_row_to_container(stats_box, "Health", "%.0f" % char_data.base_health, _get_stat_color(char_data.base_health, 25, 50))
	_add_stat_row_to_container(stats_box, "Speed", "%.0f" % char_data.base_speed, _get_stat_color(char_data.base_speed, 100, 200))
	_add_stat_row_to_container(stats_box, "Attack Speed", "%.2f/s" % (1.0 / char_data.base_attack_cooldown), _get_stat_color(1.0 / char_data.base_attack_cooldown, 0.8, 1.5))
	_add_stat_row_to_container(stats_box, "Damage", "x%.1f" % char_data.base_damage, _get_stat_color(char_data.base_damage, 0.8, 1.8))

	# Combat stats
	_add_stat_row_to_container(stats_box, "Crit Rate", "%d%%" % int(char_data.base_crit_rate * 100), _get_stat_color(char_data.base_crit_rate, 0.0, 0.15))
	_add_stat_row_to_container(stats_box, "Block Rate", "%d%%" % int(char_data.base_block_rate * 100), _get_stat_color(char_data.base_block_rate, 0.0, 0.10))
	_add_stat_row_to_container(stats_box, "Dodge Rate", "%d%%" % int(char_data.base_dodge_rate * 100), _get_stat_color(char_data.base_dodge_rate, 0.0, 0.15))

	# Update passive
	for child in preview_passive_container.get_children():
		child.queue_free()

	var passive_title_container = MarginContainer.new()
	passive_title_container.custom_minimum_size = Vector2(340, 0)
	passive_title_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_passive_container.add_child(passive_title_container)
	var passive_title = Label.new()
	passive_title.text = "PASSIVE: " + char_data.passive_name
	passive_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_title.add_theme_font_size_override("font_size", 12)
	passive_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1))
	passive_title_container.add_child(passive_title)

	var passive_desc_container = MarginContainer.new()
	passive_desc_container.custom_minimum_size = Vector2(340, 0)
	passive_desc_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_passive_container.add_child(passive_desc_container)
	var passive_desc = Label.new()
	passive_desc.text = char_data.passive_description
	passive_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_desc.add_theme_font_size_override("font_size", 10)
	passive_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	passive_desc_container.add_child(passive_desc)

func _add_stat_row_to_container(container: VBoxContainer, stat_name: String, stat_value: String, color: Color) -> void:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 11)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
	hbox.add_child(name_label)

	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 11)
	value_label.add_theme_color_override("font_color", color)
	hbox.add_child(value_label)

func _get_stat_color(value: float, low: float, high: float) -> Color:
	var t = clamp((value - low) / (high - low), 0.0, 1.0)
	if t < 0.5:
		return Color(1.0, t * 2, 0.2, 1)
	else:
		return Color(1.0 - (t - 0.5) * 2, 1.0, 0.2, 1)

func _on_selector_pressed(index: int) -> void:
	_set_selected(index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_select_pressed() -> void:
	var char_data: CharacterData = characters_list[selected_index]
	CharacterManager.select_character(char_data.id)

	# Reset run stats and start game
	if StatsManager:
		StatsManager.reset_run()
	if AbilityManager:
		AbilityManager.reset()
		AbilityManager.is_ranged_character = CharacterManager.is_ranged_character()

	get_tree().change_scene_to_file("res://scenes/main.tscn")

func _style_golden_button(button: Button) -> void:
	var style_normal = StyleBoxFlat.new()
	style_normal.bg_color = Color(0.85, 0.65, 0.2, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 8
	style_normal.border_color = Color(0.45, 0.3, 0.15, 1)
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.92, 0.72, 0.25, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 8
	style_hover.border_color = Color(0.5, 0.35, 0.18, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.75, 0.55, 0.15, 1)
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 6
	style_pressed.border_width_bottom = 5
	style_pressed.border_color = Color(0.4, 0.25, 0.1, 1)
	style_pressed.corner_radius_top_left = 6
	style_pressed.corner_radius_top_right = 6
	style_pressed.corner_radius_bottom_left = 6
	style_pressed.corner_radius_bottom_right = 6

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style_normal)

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

	button.add_theme_stylebox_override("normal", style_normal)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_normal)
	button.add_theme_stylebox_override("focus", style_normal)
