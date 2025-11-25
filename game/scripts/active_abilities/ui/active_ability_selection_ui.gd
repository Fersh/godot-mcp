extends CanvasLayer
class_name ActiveAbilitySelectionUI

signal ability_selected(ability: ActiveAbilityData)

var current_choices: Array[ActiveAbilityData] = []
var ability_buttons: Array[Button] = []
var all_abilities_pool: Array[ActiveAbilityData] = []

# Slot machine state
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 1.0
var slots_settled: Array[bool] = [false, false, false]
var slot_settle_times: Array[float] = [0.6, 0.8, 1.0]
var current_roll_speed: float = 0.05
var roll_tick_timers: Array[float] = [0.0, 0.0, 0.0]

@onready var panel: PanelContainer
@onready var title_label: Label
@onready var subtitle_label: Label
@onready var choices_container: HBoxContainer

var pixel_font: Font = null

func _ready() -> void:
	visible = false
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS

	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_create_ui()

func _create_ui() -> void:
	# Full-screen panel (same as passive ability selection)
	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	# Style the panel with dark semi-transparent background
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.85)
	panel_style.set_corner_radius_all(20)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# Content VBox - centered
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 30)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "NEW ABILITY!"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 32)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(title_label)

	# Subtitle
	subtitle_label = Label.new()
	subtitle_label.name = "SubtitleLabel"
	subtitle_label.text = "Choose an active ability"
	subtitle_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle_label.add_theme_font_size_override("font_size", 14)
	subtitle_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	if pixel_font:
		subtitle_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(subtitle_label)

	# Choices container - centered horizontally
	choices_container = HBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 20)
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(choices_container)

func _process(delta: float) -> void:
	if not is_rolling:
		return

	roll_timer += delta

	# Update each slot
	for i in range(ability_buttons.size()):
		if slots_settled[i]:
			continue

		if roll_timer >= slot_settle_times[i]:
			slots_settled[i] = true
			_update_card_content(ability_buttons[i], current_choices[i])
			if SoundManager and SoundManager.has_method("play_ding"):
				SoundManager.play_ding()
		else:
			roll_tick_timers[i] += delta
			var progress = roll_timer / slot_settle_times[i]
			var current_speed = current_roll_speed * (1.0 + progress * 3.0)

			if roll_tick_timers[i] >= current_speed:
				roll_tick_timers[i] = 0.0
				if all_abilities_pool.size() > 0:
					var random_ability = all_abilities_pool[randi() % all_abilities_pool.size()]
					_update_card_content(ability_buttons[i], random_ability)

	# Check if all slots settled
	if slots_settled.all(func(s): return s):
		is_rolling = false
		for button in ability_buttons:
			button.disabled = false

func show_choices(abilities: Array[ActiveAbilityData], level: int) -> void:
	current_choices = abilities

	# Get pool for slot machine effect
	var is_melee = CharacterManager.get_selected_character().attack_type == CharacterData.AttackType.MELEE if CharacterManager else false
	all_abilities_pool = ActiveAbilityDatabase.get_abilities_for_class(is_melee)
	if all_abilities_pool.is_empty():
		all_abilities_pool = abilities

	# Update title based on level
	match level:
		1:
			title_label.text = "FIRST ABILITY!"
		5:
			title_label.text = "NEW ABILITY!"
		10:
			title_label.text = "ULTIMATE ABILITY!"
		_:
			title_label.text = "NEW ABILITY!"

	# Clear previous buttons
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()

	# Reset slot machine state
	is_rolling = true
	roll_timer = 0.0
	slots_settled = [false, false, false]
	roll_tick_timers = [0.0, 0.0, 0.0]

	# Create cards
	for i in abilities.size():
		var random_start = all_abilities_pool[randi() % all_abilities_pool.size()]
		var card = _create_ability_card(random_start, i)
		card.disabled = true
		choices_container.add_child(card)
		ability_buttons.append(card)

	visible = true
	get_tree().paused = true

	_animate_entrance()

func _create_ability_card(ability: ActiveAbilityData, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(260, 300)
	button.focus_mode = Control.FOCUS_ALL

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)

	# Rarity label
	var rarity_label = Label.new()
	rarity_label.name = "RarityLabel"
	rarity_label.text = ActiveAbilityData.get_rarity_name(ability.rarity)
	rarity_label.add_theme_color_override("font_color", ActiveAbilityData.get_rarity_color(ability.rarity))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 12)
	if pixel_font:
		rarity_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(rarity_label)

	# Type label (ACTIVE)
	var type_label = Label.new()
	type_label.name = "TypeLabel"
	type_label.text = "ACTIVE"
	type_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	type_label.add_theme_font_size_override("font_size", 10)
	type_label.add_theme_color_override("font_color", Color(0.4, 0.8, 1.0))
	if pixel_font:
		type_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(type_label)

	# Ability name
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = ability.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 16)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Separator
	var separator = HSeparator.new()
	separator.add_theme_stylebox_override("separator", _create_separator_style(ability.rarity))
	vbox.add_child(separator)

	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = ability.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	# Cooldown info
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.text = "Cooldown: " + str(int(ability.cooldown)) + "s"
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 10)
	cooldown_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if pixel_font:
		cooldown_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(cooldown_label)

	# Select hint
	var hint_label = Label.new()
	hint_label.text = "[TAP]"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 10)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	if pixel_font:
		hint_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(hint_label)

	# Margin container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_child(vbox)

	button.add_child(margin)

	_style_button(button, ability.rarity)

	button.pressed.connect(_on_ability_selected.bind(index))

	return button

func _style_button(button: Button, rarity: ActiveAbilityData.Rarity) -> void:
	var style = StyleBoxFlat.new()

	match rarity:
		ActiveAbilityData.Rarity.COMMON:
			style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
			style.border_color = Color(0.4, 0.4, 0.4)
		ActiveAbilityData.Rarity.RARE:
			style.bg_color = Color(0.1, 0.15, 0.25, 0.95)
			style.border_color = Color(0.3, 0.5, 1.0)
		ActiveAbilityData.Rarity.LEGENDARY:
			style.bg_color = Color(0.2, 0.15, 0.1, 0.95)
			style.border_color = Color(1.0, 0.8, 0.2)

	style.set_border_width_all(3)
	style.set_corner_radius_all(12)

	button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _create_separator_style(rarity: ActiveAbilityData.Rarity) -> StyleBoxLine:
	var style = StyleBoxLine.new()
	style.color = ActiveAbilityData.get_rarity_color(rarity)
	style.thickness = 2
	return style

func _update_card_content(button: Button, ability: ActiveAbilityData) -> void:
	var margin = button.get_child(0) as MarginContainer
	if not margin:
		return
	var vbox = margin.get_child(0) as VBoxContainer
	if not vbox:
		return

	# Update rarity (child 0)
	var rarity_label = vbox.get_child(0) as Label
	if rarity_label:
		rarity_label.text = ActiveAbilityData.get_rarity_name(ability.rarity)
		rarity_label.add_theme_color_override("font_color", ActiveAbilityData.get_rarity_color(ability.rarity))

	# Update name (child 2)
	var name_label = vbox.get_child(2) as Label
	if name_label:
		name_label.text = ability.name

	# Update separator (child 3)
	var separator = vbox.get_child(3) as HSeparator
	if separator:
		separator.add_theme_stylebox_override("separator", _create_separator_style(ability.rarity))

	# Update description (child 4)
	var desc_label = vbox.get_child(4) as Label
	if desc_label:
		desc_label.text = ability.description

	# Update cooldown (child 5)
	var cooldown_label = vbox.get_child(5) as Label
	if cooldown_label:
		cooldown_label.text = "Cooldown: " + str(int(ability.cooldown)) + "s"

	_style_button(button, ability.rarity)

func _on_ability_selected(index: int) -> void:
	if is_rolling:
		return

	if index >= 0 and index < current_choices.size():
		var ability = current_choices[index]

		# Acquire the ability
		ActiveAbilityManager.acquire_ability(ability)

		# Play sound
		if SoundManager and SoundManager.has_method("play_buff"):
			SoundManager.play_buff()

		emit_signal("ability_selected", ability)

		hide_selection()

func hide_selection() -> void:
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible or is_rolling:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_J, KEY_Q:
				if current_choices.size() > 0:
					_on_ability_selected(0)
			KEY_2, KEY_K, KEY_W:
				if current_choices.size() > 1:
					_on_ability_selected(1)
			KEY_3, KEY_L, KEY_E:
				if current_choices.size() > 2:
					_on_ability_selected(2)

func _animate_entrance() -> void:
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		panel.modulate.a = 0.0
		panel.pivot_offset = panel.size / 2

		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

	if title_label:
		title_label.scale = Vector2(1.5, 1.5)
		title_label.pivot_offset = Vector2(title_label.size.x / 2, title_label.size.y / 2)

		var title_tween = create_tween()
		title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	for i in ability_buttons.size():
		var button = ability_buttons[i]
		button.modulate.a = 0.0
		var original_pos = button.position
		button.position.y += 50

		var card_tween = create_tween()
		card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tween.tween_interval(0.1 * i)
		card_tween.set_parallel(true)
		card_tween.tween_property(button, "position:y", original_pos.y, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		card_tween.tween_property(button, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)
