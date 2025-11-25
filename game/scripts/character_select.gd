extends CanvasLayer

@onready var back_button: Button = $VBoxContainer/TopBar/BackButton
@onready var title_label: Label = $VBoxContainer/TopBar/TitleLabel
@onready var characters_container: HBoxContainer = $VBoxContainer/CharactersContainer
@onready var select_button: Button = $VBoxContainer/SelectButton

var character_cards: Array = []
var selected_index: int = 0
var animation_timers: Dictionary = {}

func _ready() -> void:
	back_button.pressed.connect(_on_back_pressed)
	select_button.pressed.connect(_on_select_pressed)

	_style_golden_button(select_button)
	_style_back_button(back_button)

	_create_character_cards()
	_select_current_character()

func _process(delta: float) -> void:
	# Update idle animations for all character previews
	for card in character_cards:
		var char_id = card.get_meta("character_id")
		if animation_timers.has(char_id):
			animation_timers[char_id] += delta * 8.0  # Animation speed
			var sprite: Sprite2D = card.get_node("Preview/CharacterSprite")
			var char_data: CharacterData = CharacterManager.get_character(char_id)
			if sprite and char_data:
				var frame_count = char_data.frames_idle
				var current_frame = int(animation_timers[char_id]) % frame_count
				sprite.frame = char_data.row_idle * char_data.hframes + current_frame

func _create_character_cards() -> void:
	# Clear existing cards
	for child in characters_container.get_children():
		child.queue_free()
	character_cards.clear()

	var characters = CharacterManager.get_all_characters()
	for i in characters.size():
		var char_data: CharacterData = characters[i]
		var card = _create_card(char_data, i)
		characters_container.add_child(card)
		character_cards.append(card)
		animation_timers[char_data.id] = 0.0

func _create_card(char_data: CharacterData, index: int) -> PanelContainer:
	var card = PanelContainer.new()
	card.custom_minimum_size = Vector2(400, 700)
	card.set_meta("character_id", char_data.id)
	card.set_meta("index", index)

	# Card styling
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.3, 0.3, 0.4, 1)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 12
	style.corner_radius_bottom_right = 12
	card.add_theme_stylebox_override("panel", style)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 15)
	card.add_child(vbox)

	# Character name
	var name_label = Label.new()
	name_label.text = char_data.display_name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 28)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	vbox.add_child(name_label)

	# Character preview container
	var preview_container = CenterContainer.new()
	preview_container.name = "Preview"
	preview_container.custom_minimum_size = Vector2(0, 200)
	vbox.add_child(preview_container)

	# Character sprite (idle animation)
	var sprite = Sprite2D.new()
	sprite.name = "CharacterSprite"
	sprite.texture = char_data.sprite_texture
	sprite.hframes = char_data.hframes
	sprite.vframes = char_data.vframes
	sprite.frame = char_data.row_idle * char_data.hframes

	# Scale sprite appropriately for preview
	if char_data.id == "knight":
		sprite.scale = Vector2(2.5, 2.5)
	else:
		sprite.scale = Vector2(4.0, 4.0)

	preview_container.add_child(sprite)

	# Description
	var desc_label = Label.new()
	desc_label.text = char_data.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.custom_minimum_size = Vector2(350, 0)
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	vbox.add_child(desc_label)

	# Stats section
	var stats_container = VBoxContainer.new()
	stats_container.add_theme_constant_override("separation", 8)
	vbox.add_child(stats_container)

	var stats_title = Label.new()
	stats_title.text = "STATS"
	stats_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stats_title.add_theme_font_size_override("font_size", 18)
	stats_title.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
	stats_container.add_child(stats_title)

	# Individual stats
	_add_stat_row(stats_container, "Health", "%.0f" % char_data.base_health, _get_stat_color(char_data.base_health, 25, 50))
	_add_stat_row(stats_container, "Speed", "%.0f" % char_data.base_speed, _get_stat_color(char_data.base_speed, 100, 200))
	_add_stat_row(stats_container, "Attack Speed", "%.2f/s" % (1.0 / char_data.base_attack_cooldown), _get_stat_color(1.0 / char_data.base_attack_cooldown, 0.8, 1.5))
	_add_stat_row(stats_container, "Damage", "x%.1f" % char_data.base_damage, _get_stat_color(char_data.base_damage, 0.8, 1.8))

	var attack_type_text = "Ranged" if char_data.attack_type == CharacterData.AttackType.RANGED else "Melee"
	_add_stat_row(stats_container, "Type", attack_type_text, Color(0.9, 0.9, 0.9, 1))

	# Passive ability section
	var passive_container = VBoxContainer.new()
	passive_container.add_theme_constant_override("separation", 5)
	vbox.add_child(passive_container)

	var passive_title = Label.new()
	passive_title.text = "PASSIVE: " + char_data.passive_name
	passive_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_title.add_theme_font_size_override("font_size", 16)
	passive_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1))
	passive_container.add_child(passive_title)

	var passive_desc = Label.new()
	passive_desc.text = char_data.passive_description
	passive_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_desc.custom_minimum_size = Vector2(350, 0)
	passive_desc.add_theme_font_size_override("font_size", 14)
	passive_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	passive_container.add_child(passive_desc)

	# Make card clickable
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.pressed.connect(_on_card_pressed.bind(index))
	card.add_child(button)

	return card

func _add_stat_row(container: VBoxContainer, stat_name: String, stat_value: String, color: Color) -> void:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 14)
	name_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	hbox.add_child(name_label)

	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 14)
	value_label.add_theme_color_override("font_color", color)
	hbox.add_child(value_label)

func _get_stat_color(value: float, low: float, high: float) -> Color:
	var t = clamp((value - low) / (high - low), 0.0, 1.0)
	# Red -> Yellow -> Green gradient
	if t < 0.5:
		return Color(1.0, t * 2, 0.2, 1)
	else:
		return Color(1.0 - (t - 0.5) * 2, 1.0, 0.2, 1)

func _select_current_character() -> void:
	var current = CharacterManager.get_selected_character()
	for i in character_cards.size():
		var card = character_cards[i]
		if card.get_meta("character_id") == current.id:
			_set_selected_card(i)
			break

func _set_selected_card(index: int) -> void:
	selected_index = index

	for i in character_cards.size():
		var card: PanelContainer = character_cards[i]
		var style = card.get_theme_stylebox("panel").duplicate()

		if i == index:
			style.border_color = Color(0.95, 0.75, 0.2, 1)  # Gold border for selected
			style.border_width_left = 6
			style.border_width_right = 6
			style.border_width_top = 6
			style.border_width_bottom = 6
		else:
			style.border_color = Color(0.3, 0.3, 0.4, 1)
			style.border_width_left = 4
			style.border_width_right = 4
			style.border_width_top = 4
			style.border_width_bottom = 4

		card.add_theme_stylebox_override("panel", style)

func _on_card_pressed(index: int) -> void:
	_set_selected_card(index)

func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_select_pressed() -> void:
	var selected_card = character_cards[selected_index]
	var char_id = selected_card.get_meta("character_id")
	CharacterManager.select_character(char_id)

	# Reset run stats and start game
	if StatsManager:
		StatsManager.reset_run()
	if AbilityManager:
		AbilityManager.reset()
		# Set ranged/melee character flag
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
