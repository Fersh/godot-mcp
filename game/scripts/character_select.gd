extends CanvasLayer

@onready var back_button: Button = $VBoxContainer/TopBar/BackButton
@onready var title_label: Label = $VBoxContainer/TopBar/TitleLabel
@onready var preview_panel: PanelContainer = $VBoxContainer/PreviewPanel
@onready var selector_container: HBoxContainer = $VBoxContainer/SelectorContainer
@onready var select_button: Button = $VBoxContainer/SelectButton

# Preview elements (created dynamically)
var preview_sprite: Sprite2D
var preview_name_label: Label
var preview_desc_label: Label
var preview_stats_container: VBoxContainer
var preview_passive_container: VBoxContainer

var selector_buttons: Array = []
var selected_index: int = 0
var animation_timer: float = 0.0
var characters_list: Array = []

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	select_button.pressed.connect(_on_select_pressed)

	_style_golden_button(select_button)
	_style_back_button(back_button)

	_setup_preview_panel()
	_create_selector_buttons()
	_select_current_character()

func _process(delta: float) -> void:
	# Update idle animation for preview sprite
	if preview_sprite and selected_index < characters_list.size():
		var char_data: CharacterData = characters_list[selected_index]
		animation_timer += delta * 8.0
		var frame_count = char_data.frames_idle
		var current_frame = int(animation_timer) % frame_count
		preview_sprite.frame = char_data.row_idle * char_data.hframes + current_frame

func _setup_preview_panel() -> void:
	# Style the preview panel
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.12, 0.18, 0.95)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.3, 0.3, 0.4, 1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	preview_panel.add_theme_stylebox_override("panel", style)

	# Create internal layout
	var margin = MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 40)
	margin.add_theme_constant_override("margin_right", 40)
	margin.add_theme_constant_override("margin_top", 30)
	margin.add_theme_constant_override("margin_bottom", 30)
	preview_panel.add_child(margin)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 20)
	margin.add_child(vbox)

	# Character name at top
	preview_name_label = Label.new()
	preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name_label.add_theme_font_size_override("font_size", 36)
	preview_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	vbox.add_child(preview_name_label)

	# Sprite preview in center
	var sprite_center = CenterContainer.new()
	sprite_center.custom_minimum_size = Vector2(0, 250)
	vbox.add_child(sprite_center)

	preview_sprite = Sprite2D.new()
	sprite_center.add_child(preview_sprite)

	# Description
	preview_desc_label = Label.new()
	preview_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_desc_label.add_theme_font_size_override("font_size", 18)
	preview_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(preview_desc_label)

	# Stats section
	preview_stats_container = VBoxContainer.new()
	preview_stats_container.add_theme_constant_override("separation", 10)
	vbox.add_child(preview_stats_container)

	# Passive section
	preview_passive_container = VBoxContainer.new()
	preview_passive_container.add_theme_constant_override("separation", 5)
	vbox.add_child(preview_passive_container)

func _create_selector_buttons() -> void:
	characters_list = CharacterManager.get_all_characters()

	for i in characters_list.size():
		var char_data: CharacterData = characters_list[i]
		var btn = _create_selector_button(char_data, i)
		selector_container.add_child(btn)
		selector_buttons.append(btn)

func _create_selector_button(char_data: CharacterData, index: int) -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(200, 80)
	panel.set_meta("index", index)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.3, 0.3, 0.4, 1)
	style.corner_radius_top_left = 8
	style.corner_radius_top_right = 8
	style.corner_radius_bottom_left = 8
	style.corner_radius_bottom_right = 8
	panel.add_theme_stylebox_override("panel", style)

	var center = CenterContainer.new()
	panel.add_child(center)

	var label = Label.new()
	label.text = char_data.display_name
	label.add_theme_font_size_override("font_size", 20)
	label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.9, 1))
	center.add_child(label)

	# Clickable button overlay
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.pressed.connect(_on_selector_pressed.bind(index))
	panel.add_child(button)

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

	# Update selector button highlights
	for i in selector_buttons.size():
		var panel: PanelContainer = selector_buttons[i]
		var style = panel.get_theme_stylebox("panel").duplicate()

		if i == index:
			style.border_color = Color(0.95, 0.75, 0.2, 1)  # Gold
			style.border_width_left = 4
			style.border_width_right = 4
			style.border_width_top = 4
			style.border_width_bottom = 4
			style.bg_color = Color(0.2, 0.18, 0.12, 0.95)
		else:
			style.border_color = Color(0.3, 0.3, 0.4, 1)
			style.border_width_left = 3
			style.border_width_right = 3
			style.border_width_top = 3
			style.border_width_bottom = 3
			style.bg_color = Color(0.15, 0.15, 0.2, 0.9)

		panel.add_theme_stylebox_override("panel", style)

	# Update preview
	_update_preview()

func _update_preview() -> void:
	if selected_index >= characters_list.size():
		return

	var char_data: CharacterData = characters_list[selected_index]

	# Update name
	preview_name_label.text = char_data.display_name

	# Update sprite
	preview_sprite.texture = char_data.sprite_texture
	preview_sprite.hframes = char_data.hframes
	preview_sprite.vframes = char_data.vframes
	preview_sprite.frame = char_data.row_idle * char_data.hframes

	if char_data.id == "knight":
		preview_sprite.scale = Vector2(3.0, 3.0)
	else:
		preview_sprite.scale = Vector2(5.0, 5.0)

	# Update description
	preview_desc_label.text = char_data.description

	# Update stats
	for child in preview_stats_container.get_children():
		child.queue_free()

	var stats_title = Label.new()
	stats_title.text = "STATS"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 20)
	stats_title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
	preview_stats_container.add_child(stats_title)

	var stats_grid = GridContainer.new()
	stats_grid.columns = 2
	stats_grid.add_theme_constant_override("h_separation", 40)
	stats_grid.add_theme_constant_override("v_separation", 8)
	preview_stats_container.add_child(stats_grid)

	_add_stat_to_grid(stats_grid, "Health", "%.0f" % char_data.base_health, _get_stat_color(char_data.base_health, 25, 50))
	_add_stat_to_grid(stats_grid, "Speed", "%.0f" % char_data.base_speed, _get_stat_color(char_data.base_speed, 100, 200))
	_add_stat_to_grid(stats_grid, "Attack Speed", "%.2f/s" % (1.0 / char_data.base_attack_cooldown), _get_stat_color(1.0 / char_data.base_attack_cooldown, 0.8, 1.5))
	_add_stat_to_grid(stats_grid, "Damage", "x%.1f" % char_data.base_damage, _get_stat_color(char_data.base_damage, 0.8, 1.8))

	var attack_type_text = "Ranged" if char_data.attack_type == CharacterData.AttackType.RANGED else "Melee"
	_add_stat_to_grid(stats_grid, "Type", attack_type_text, Color(0.9, 0.9, 0.9, 1))

	# Update passive
	for child in preview_passive_container.get_children():
		child.queue_free()

	var passive_title = Label.new()
	passive_title.text = "PASSIVE: " + char_data.passive_name
	passive_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_title.add_theme_font_size_override("font_size", 18)
	passive_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1))
	preview_passive_container.add_child(passive_title)

	var passive_desc = Label.new()
	passive_desc.text = char_data.passive_description
	passive_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_desc.add_theme_font_size_override("font_size", 16)
	passive_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	preview_passive_container.add_child(passive_desc)

func _add_stat_to_grid(grid: GridContainer, stat_name: String, stat_value: String, color: Color) -> void:
	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	grid.add_child(name_label)

	var value_label = Label.new()
	value_label.text = stat_value
	value_label.add_theme_font_size_override("font_size", 16)
	value_label.add_theme_color_override("font_color", color)
	grid.add_child(value_label)

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
