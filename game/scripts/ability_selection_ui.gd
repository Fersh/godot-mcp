extends CanvasLayer

signal ability_selected(ability: AbilityData)

var current_choices: Array[AbilityData] = []
var ability_buttons: Array[Button] = []

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var choices_container: HBoxContainer = $Panel/VBoxContainer/ChoicesContainer

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused

func show_choices(abilities: Array[AbilityData]) -> void:
	current_choices = abilities

	# Clear previous buttons
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()

	# Create buttons for each ability
	for i in abilities.size():
		var ability = abilities[i]
		var card = create_ability_card(ability, i)
		choices_container.add_child(card)
		ability_buttons.append(card)

	# Show and pause
	visible = true
	get_tree().paused = true

func create_ability_card(ability: AbilityData, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(280, 380)
	button.focus_mode = Control.FOCUS_ALL

	# Create container for card content
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 12)

	# Rarity label
	var rarity_label = Label.new()
	rarity_label.text = AbilityData.get_rarity_name(ability.rarity)
	rarity_label.add_theme_color_override("font_color", AbilityData.get_rarity_color(ability.rarity))
	rarity_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rarity_label.add_theme_font_size_override("font_size", 14)
	vbox.add_child(rarity_label)

	# Ability name
	var name_label = Label.new()
	name_label.text = ability.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 22)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)

	# Separator
	var separator = HSeparator.new()
	separator.add_theme_stylebox_override("separator", create_separator_style(ability.rarity))
	vbox.add_child(separator)

	# Description
	var desc_label = Label.new()
	desc_label.text = ability.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 16)
	desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(desc_label)

	# Spacer
	var spacer = Control.new()
	spacer.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(spacer)

	# Select hint
	var hint_label = Label.new()
	hint_label.text = "[Click to Select]"
	hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint_label.add_theme_font_size_override("font_size", 12)
	hint_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	vbox.add_child(hint_label)

	# Add margin container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 16)
	margin.add_theme_constant_override("margin_right", 16)
	margin.add_theme_constant_override("margin_top", 16)
	margin.add_theme_constant_override("margin_bottom", 16)
	margin.add_child(vbox)

	button.add_child(margin)

	# Style the button
	style_button(button, ability.rarity)

	# Connect click
	button.pressed.connect(_on_ability_selected.bind(index))

	return button

func style_button(button: Button, rarity: AbilityData.Rarity) -> void:
	var style = StyleBoxFlat.new()

	# Background based on rarity
	match rarity:
		AbilityData.Rarity.COMMON:
			style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
			style.border_color = Color(0.4, 0.4, 0.4)
		AbilityData.Rarity.RARE:
			style.bg_color = Color(0.1, 0.15, 0.25, 0.95)
			style.border_color = Color(0.3, 0.5, 1.0)
		AbilityData.Rarity.LEGENDARY:
			style.bg_color = Color(0.2, 0.15, 0.1, 0.95)
			style.border_color = Color(1.0, 0.8, 0.2)

	style.set_border_width_all(3)
	style.set_corner_radius_all(12)

	button.add_theme_stylebox_override("normal", style)

	# Hover style
	var hover_style = style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)

	# Pressed style
	var pressed_style = style.duplicate()
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)

func create_separator_style(rarity: AbilityData.Rarity) -> StyleBoxLine:
	var style = StyleBoxLine.new()
	style.color = AbilityData.get_rarity_color(rarity)
	style.thickness = 2
	return style

func _on_ability_selected(index: int) -> void:
	if index >= 0 and index < current_choices.size():
		var ability = current_choices[index]

		# Acquire the ability
		AbilityManager.acquire_ability(ability)

		# Play buff sound
		if SoundManager:
			SoundManager.play_buff()

		# Emit signal
		emit_signal("ability_selected", ability)

		# Hide and unpause
		hide_selection()

func hide_selection() -> void:
	visible = false
	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible:
		return

	# Keyboard shortcuts for selection (1, 2, 3)
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1:
				if current_choices.size() > 0:
					_on_ability_selected(0)
			KEY_2:
				if current_choices.size() > 1:
					_on_ability_selected(1)
			KEY_3:
				if current_choices.size() > 2:
					_on_ability_selected(2)
