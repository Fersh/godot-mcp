extends CanvasLayer

signal resumed
signal gave_up

var pixel_font: Font = null

# RPG Colors
const COLOR_BG = Color(0.08, 0.06, 0.1, 0.95)
const COLOR_PANEL = Color(0.12, 0.10, 0.15, 1.0)
const COLOR_BORDER = Color(0.35, 0.28, 0.18, 1.0)
const COLOR_TEXT = Color(0.9, 0.85, 0.75, 1.0)
const COLOR_TEXT_DIM = Color(0.55, 0.50, 0.42, 1.0)

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var powerups_label: Label = $Panel/VBoxContainer/PowerupsLabel
@onready var powerups_container: VBoxContainer = $Panel/VBoxContainer/PowerupsMargin/PowerupsScroll/PowerupsContainer
@onready var resume_button: Button = $Panel/VBoxContainer/ButtonContainer/ResumeButton
@onready var give_up_button: Button = $Panel/VBoxContainer/ButtonContainer/GiveUpButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	resume_button.pressed.connect(_on_resume_pressed)
	give_up_button.pressed.connect(_on_give_up_pressed)

	_setup_style()

func _setup_style() -> void:
	# Style the main panel
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL
	panel_style.border_width_left = 4
	panel_style.border_width_right = 4
	panel_style.border_width_top = 4
	panel_style.border_width_bottom = 6
	panel_style.border_color = COLOR_BORDER
	panel_style.corner_radius_top_left = 4
	panel_style.corner_radius_top_right = 4
	panel_style.corner_radius_bottom_left = 4
	panel_style.corner_radius_bottom_right = 4
	panel_style.shadow_color = Color(0, 0, 0, 0.6)
	panel_style.shadow_size = 12
	panel.add_theme_stylebox_override("panel", panel_style)

	# Style title
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	title_label.add_theme_font_size_override("font_size", 28)
	title_label.add_theme_color_override("font_color", COLOR_TEXT)

	# Style powerups label
	if pixel_font:
		powerups_label.add_theme_font_override("font", pixel_font)
	powerups_label.add_theme_font_size_override("font_size", 18)
	powerups_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)

	# Style buttons
	_style_button(resume_button, Color(0.2, 0.5, 0.3))
	_style_button(give_up_button, Color(0.5, 0.2, 0.2))

func _style_button(button: Button, base_color: Color) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = base_color
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_width_top = 2
	style.border_width_bottom = 4
	style.border_color = base_color.darkened(0.4)
	style.corner_radius_top_left = 2
	style.corner_radius_top_right = 2
	style.corner_radius_bottom_left = 2
	style.corner_radius_bottom_right = 2

	var style_hover = style.duplicate()
	style_hover.bg_color = base_color.lightened(0.15)

	var style_pressed = style.duplicate()
	style_pressed.bg_color = base_color.darkened(0.2)
	style_pressed.border_width_top = 4
	style_pressed.border_width_bottom = 2

	button.add_theme_stylebox_override("normal", style)
	button.add_theme_stylebox_override("hover", style_hover)
	button.add_theme_stylebox_override("pressed", style_pressed)
	button.add_theme_stylebox_override("focus", style)

	if pixel_font:
		button.add_theme_font_override("font", pixel_font)
	button.add_theme_font_size_override("font_size", 20)
	button.add_theme_color_override("font_color", COLOR_TEXT)

func show_menu() -> void:
	_populate_powerups()
	visible = true
	get_tree().paused = true

func hide_menu() -> void:
	visible = false
	get_tree().paused = false

func _populate_powerups() -> void:
	# Clear existing
	for child in powerups_container.get_children():
		child.queue_free()

	# Get acquired abilities from AbilityManager
	if not AbilityManager:
		_add_no_powerups_label()
		return

	var abilities = AbilityManager.acquired_abilities
	if abilities.size() == 0:
		_add_no_powerups_label()
		return

	# Count abilities (for stacking display)
	var ability_counts: Dictionary = {}
	for ability in abilities:
		if ability_counts.has(ability.id):
			ability_counts[ability.id].count += 1
		else:
			ability_counts[ability.id] = {"ability": ability, "count": 1}

	# Create rows for each unique ability
	for ability_id in ability_counts:
		var data = ability_counts[ability_id]
		var row = _create_powerup_row(data.ability, data.count)
		powerups_container.add_child(row)

func _add_no_powerups_label() -> void:
	var label = Label.new()
	label.text = "No powerups yet!"
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	label.add_theme_font_size_override("font_size", 16)
	label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	powerups_container.add_child(label)

func _create_powerup_row(ability: AbilityData, count: int) -> Control:
	var container = VBoxContainer.new()
	container.add_theme_constant_override("separation", 2)

	var row = HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)

	# Get rarity color (static method requires rarity parameter)
	var rarity_color = AbilityData.get_rarity_color(ability.rarity)

	# Icon placeholder (colored square based on rarity)
	var icon_bg = ColorRect.new()
	icon_bg.custom_minimum_size = Vector2(12, 12)
	icon_bg.color = rarity_color
	row.add_child(icon_bg)

	# Name with count if stacked
	var name_label = Label.new()
	if count > 1:
		name_label.text = "%s x%d" % [ability.name, count]
	else:
		name_label.text = ability.name
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	name_label.add_theme_font_size_override("font_size", 12)
	name_label.add_theme_color_override("font_color", rarity_color)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(name_label)

	container.add_child(row)

	# Description below the name
	var desc_label = Label.new()
	desc_label.text = ability.description
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	desc_label.add_theme_font_size_override("font_size", 9)
	desc_label.add_theme_color_override("font_color", COLOR_TEXT_DIM)
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	container.add_child(desc_label)

	return container

func _on_resume_pressed() -> void:
	hide_menu()
	emit_signal("resumed")

func _on_give_up_pressed() -> void:
	hide_menu()
	emit_signal("gave_up")

func _input(event: InputEvent) -> void:
	if not visible:
		return

	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_ESCAPE:
			_on_resume_pressed()
