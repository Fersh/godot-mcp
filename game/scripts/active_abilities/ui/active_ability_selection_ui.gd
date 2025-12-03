extends CanvasLayer
class_name ActiveAbilitySelectionUI

signal ability_selected(ability: ActiveAbilityData)

var current_choices: Array[ActiveAbilityData] = []
var ability_buttons: Array[Button] = []
var all_abilities_pool: Array[ActiveAbilityData] = []

# Reroll state
var reroll_button: Button = null
var reroll_used: bool = false
var current_level: int = 1

# Slot machine state
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 1.0
var slots_settled: Array[bool] = []
var slot_settle_times: Array[float] = []  # Dynamically set based on ability count
var current_roll_speed: float = 0.05
var roll_tick_timers: Array[float] = []

@onready var panel: PanelContainer
@onready var title_label: Label
@onready var subtitle_label: Label
@onready var subtitle_prefix_label: Label
@onready var choices_container: HBoxContainer

var pixel_font: Font = null
var rarity_particle_shader: Shader = null
var particle_containers: Array[Control] = []

func _ready() -> void:
	visible = false
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("active_ability_selection_ui")

	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load rarity particle shader
	if ResourceLoader.exists("res://shaders/rarity_particles.gdshader"):
		rarity_particle_shader = load("res://shaders/rarity_particles.gdshader")

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
	panel_style.bg_color = Color(0, 0, 0, 0.92)
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
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(title_label)

	# Subtitle container for colored text
	var subtitle_container = HBoxContainer.new()
	subtitle_container.alignment = BoxContainer.ALIGNMENT_CENTER

	var subtitle_prefix = Label.new()
	subtitle_prefix.name = "SubtitlePrefix"
	subtitle_prefix.text = "Choose your first "
	subtitle_prefix.add_theme_font_size_override("font_size", 20)
	subtitle_prefix.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	if pixel_font:
		subtitle_prefix.add_theme_font_override("font", pixel_font)
	subtitle_container.add_child(subtitle_prefix)
	subtitle_prefix_label = subtitle_prefix

	var subtitle_active = Label.new()
	subtitle_active.text = "ACTIVE"
	subtitle_active.add_theme_font_size_override("font_size", 20)
	subtitle_active.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2))  # Orange highlight
	if pixel_font:
		subtitle_active.add_theme_font_override("font", pixel_font)
	subtitle_container.add_child(subtitle_active)

	var subtitle_suffix = Label.new()
	subtitle_suffix.text = " ability"
	subtitle_suffix.add_theme_font_size_override("font_size", 20)
	subtitle_suffix.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	if pixel_font:
		subtitle_suffix.add_theme_font_override("font", pixel_font)
	subtitle_container.add_child(subtitle_suffix)

	vbox.add_child(subtitle_container)

	# Keep reference (not used but maintain compatibility)
	subtitle_label = subtitle_prefix

	# Spacer to push cards down
	var cards_spacer = Control.new()
	cards_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(cards_spacer)

	# Choices container - centered horizontally
	choices_container = HBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 20)
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(choices_container)

	# Spacer before reroll button
	var reroll_spacer = Control.new()
	reroll_spacer.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(reroll_spacer)

	# Reroll button - red with white font like Refund All
	reroll_button = Button.new()
	reroll_button.name = "RerollButton"
	reroll_button.text = "Reroll Abilities"
	reroll_button.custom_minimum_size = Vector2(180, 44)
	reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	if pixel_font:
		reroll_button.add_theme_font_override("font", pixel_font)
	reroll_button.add_theme_font_size_override("font_size", 15)

	# Style the reroll button - red background, white text, more padding
	var reroll_style = StyleBoxFlat.new()
	reroll_style.bg_color = Color(0.7, 0.15, 0.15, 0.95)
	reroll_style.border_color = Color(0.9, 0.3, 0.3)
	reroll_style.set_border_width_all(2)
	reroll_style.set_corner_radius_all(6)
	reroll_style.content_margin_left = 20
	reroll_style.content_margin_right = 20
	reroll_style.content_margin_top = 8
	reroll_style.content_margin_bottom = 8
	reroll_button.add_theme_stylebox_override("normal", reroll_style)

	var reroll_hover = reroll_style.duplicate()
	reroll_hover.bg_color = Color(0.85, 0.2, 0.2, 0.95)
	reroll_button.add_theme_stylebox_override("hover", reroll_hover)

	var reroll_pressed = reroll_style.duplicate()
	reroll_pressed.bg_color = Color(0.5, 0.1, 0.1, 0.95)
	reroll_button.add_theme_stylebox_override("pressed", reroll_pressed)

	var reroll_disabled = reroll_style.duplicate()
	reroll_disabled.bg_color = Color(0.3, 0.3, 0.3, 0.7)
	reroll_disabled.border_color = Color(0.4, 0.4, 0.4)
	reroll_button.add_theme_stylebox_override("disabled", reroll_disabled)

	reroll_button.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))
	reroll_button.add_theme_color_override("font_disabled_color", Color(0.6, 0.6, 0.6))

	reroll_button.pressed.connect(_on_reroll_pressed)
	vbox.add_child(reroll_button)

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
			_update_card_content(ability_buttons[i], current_choices[i], true)  # true = final reveal
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
		# Enable reroll button if not used yet
		if reroll_button and not reroll_used:
			reroll_button.disabled = false

func show_choices(abilities: Array[ActiveAbilityData], level: int) -> void:
	current_choices = abilities
	current_level = level

	# Reset reroll state for this selection
	reroll_used = false
	if reroll_button:
		reroll_button.disabled = true  # Disabled during rolling
		reroll_button.text = "Reroll"

	# Get pool for slot machine effect
	var is_melee = CharacterManager.get_selected_character().attack_type == CharacterData.AttackType.MELEE if CharacterManager else false
	all_abilities_pool = ActiveAbilityDatabase.get_abilities_for_class(is_melee)
	if all_abilities_pool.is_empty():
		all_abilities_pool = abilities

	# Update title and subtitle based on level
	match level:
		1:
			title_label.text = "FIRST ABILITY!"
			if subtitle_prefix_label:
				subtitle_prefix_label.text = "Choose your first "
		5:
			title_label.text = "NEW ABILITY!"
			if subtitle_prefix_label:
				subtitle_prefix_label.text = "Choose your second "
		10:
			title_label.text = "ULTIMATE ABILITY!"
			if subtitle_prefix_label:
				subtitle_prefix_label.text = "Choose your third "
		_:
			title_label.text = "NEW ABILITY!"
			if subtitle_prefix_label:
				subtitle_prefix_label.text = "Choose your "

	# Clear previous buttons and particle containers
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()
	particle_containers.clear()

	# Reset slot machine state - dynamically sized based on ability count
	is_rolling = true
	roll_timer = 0.0
	slots_settled = []
	roll_tick_timers = []
	slot_settle_times = []
	for i in abilities.size():
		slots_settled.append(false)
		roll_tick_timers.append(0.0)
		# Stagger settle times: first card settles at 0.6s, subsequent cards 0.2s apart
		slot_settle_times.append(0.6 + i * 0.2)

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
	button.custom_minimum_size = Vector2(312, 360)  # Increased by 20%
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = false

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)

	# Spacer above ability name (for rarity tag)
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(top_spacer)

	# Ability name (moved to top since rarity is now a tag)
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = ability.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color.WHITE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = ability.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
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
	cooldown_label.add_theme_font_size_override("font_size", 12)
	cooldown_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if pixel_font:
		cooldown_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(cooldown_label)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(bottom_spacer)

	# Margin container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 12)
	margin.add_theme_constant_override("margin_right", 12)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 12)
	margin.add_child(vbox)

	button.add_child(margin)

	# Rarity tag pinned to top (half above, half inside card)
	var rarity_tag = _create_rarity_tag(ability.rarity)
	rarity_tag.name = "RarityTag"
	button.add_child(rarity_tag)

	# Add particle effect container (starts hidden, shown after card settles)
	var particle_container = _create_particle_container(ability.rarity)
	particle_container.name = "ParticleContainer"
	particle_container.visible = false  # Hide until card is revealed
	button.add_child(particle_container)
	particle_containers.append(particle_container)

	_style_button(button, ability.rarity)

	button.pressed.connect(_on_ability_selected.bind(index))

	return button

func _create_rarity_tag(rarity: ActiveAbilityData.Rarity) -> CenterContainer:
	# Use CenterContainer to properly center the tag
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 0
	center.offset_top = -12  # Half above the card
	center.offset_bottom = 12

	var tag = PanelContainer.new()

	# Style the tag
	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = ActiveAbilityData.get_rarity_color(rarity)
	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 10
	tag_style.content_margin_right = 10
	tag_style.content_margin_top = 4
	tag_style.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_style)

	# Rarity label inside tag
	var label = Label.new()
	label.name = "RarityLabel"
	label.text = ActiveAbilityData.get_rarity_name(rarity)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	# Use black text for common (light background), white for others
	var label_color = Color.BLACK if rarity == ActiveAbilityData.Rarity.COMMON else Color.WHITE
	label.add_theme_color_override("font_color", label_color)
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	tag.add_child(label)

	center.add_child(tag)
	return center

func _style_button(button: Button, rarity: ActiveAbilityData.Rarity) -> void:
	var style = StyleBoxFlat.new()

	# Reduced transparency (0.98 instead of 0.95)
	match rarity:
		ActiveAbilityData.Rarity.COMMON:
			style.bg_color = Color(0.15, 0.15, 0.18, 0.98)
			style.border_color = Color(0.4, 0.4, 0.4)
		ActiveAbilityData.Rarity.RARE:
			style.bg_color = Color(0.1, 0.15, 0.25, 0.98)
			style.border_color = Color(0.3, 0.5, 1.0)
		ActiveAbilityData.Rarity.EPIC:
			style.bg_color = Color(0.15, 0.1, 0.2, 0.98)  # Purple-tinted background
			style.border_color = ActiveAbilityData.get_rarity_color(rarity)
		ActiveAbilityData.Rarity.LEGENDARY:
			style.bg_color = Color(0.2, 0.18, 0.1, 0.98)  # Yellow-tinted background
			style.border_color = ActiveAbilityData.get_rarity_color(rarity)
		ActiveAbilityData.Rarity.MYTHIC:
			style.bg_color = Color(0.18, 0.08, 0.1, 0.98)  # Dark red-tinted background
			style.border_color = ActiveAbilityData.get_rarity_color(rarity)
		_:
			# Fallback for unknown rarity
			style.bg_color = Color(0.15, 0.15, 0.18, 0.98)
			style.border_color = Color(0.4, 0.4, 0.4)

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
	var color = ActiveAbilityData.get_rarity_color(rarity)
	color.a = 0.4  # More transparent
	style.color = color
	style.thickness = 1
	return style

func _update_card_content(button: Button, ability: ActiveAbilityData, is_final_reveal: bool = false) -> void:
	var margin = button.get_child(0) as MarginContainer
	if not margin:
		return
	var vbox = margin.get_child(0) as VBoxContainer
	if not vbox:
		return

	# Children: 0=top_spacer, 1=name, 2=desc, 3=cooldown
	# Update name (child 1)
	var name_label = vbox.get_child(1) as Label
	if name_label:
		name_label.text = ability.name

	# Update description (child 2)
	var desc_label = vbox.get_child(2) as Label
	if desc_label:
		desc_label.text = ability.description

	# Update cooldown (child 3)
	var cooldown_label = vbox.get_child(3) as Label
	if cooldown_label:
		cooldown_label.text = "Cooldown: " + str(int(ability.cooldown)) + "s"

	# Update rarity tag (child 1 of button is CenterContainer, which contains PanelContainer)
	var center_container = button.get_child(1) as CenterContainer
	if center_container:
		var rarity_tag = center_container.get_child(0) as PanelContainer
		if rarity_tag:
			var tag_style = rarity_tag.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			tag_style.bg_color = ActiveAbilityData.get_rarity_color(ability.rarity)
			rarity_tag.add_theme_stylebox_override("panel", tag_style)
			var rarity_label = rarity_tag.get_child(0) as Label
			if rarity_label:
				rarity_label.text = ActiveAbilityData.get_rarity_name(ability.rarity)
				# Use black text for common (light background), white for others
				var label_color = Color.BLACK if ability.rarity == ActiveAbilityData.Rarity.COMMON else Color.WHITE
				rarity_label.add_theme_color_override("font_color", label_color)

	# Update particle container - only show on final reveal
	var particle_container = button.get_node_or_null("ParticleContainer") as Control
	if particle_container:
		if is_final_reveal:
			_update_particle_container(particle_container, ability.rarity)
		else:
			particle_container.visible = false

	_style_button(button, ability.rarity)

func _on_ability_selected(index: int) -> void:
	if is_rolling:
		return

	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

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
	_safe_unpause()

func _safe_unpause() -> void:
	"""Only unpause if no modal UI is open."""
	# Check if player is dead - never unpause after death
	var player = get_tree().get_first_node_in_group("player")
	if player and player.is_dead:
		return

	# Check if game over UI is visible
	var game_over_ui = get_tree().get_first_node_in_group("game_over_ui")
	if game_over_ui:
		return

	# Check if continue screen is visible
	var continue_ui = get_tree().get_first_node_in_group("continue_screen_ui")
	if continue_ui:
		return

	# Check if pause menu is visible
	var pause_menu = get_tree().get_first_node_in_group("pause_menu")
	if pause_menu and pause_menu.visible:
		return

	# Check if passive ability selection UI is visible
	var ability_ui = get_tree().get_first_node_in_group("ability_selection_ui")
	if ability_ui and ability_ui.visible:
		return

	# Check if item pickup UI is visible
	var item_ui = get_tree().get_first_node_in_group("item_pickup_ui")
	if item_ui and item_ui.visible:
		return

	# Check if ultimate selection UI is visible
	var ultimate_ui = get_tree().get_first_node_in_group("ultimate_selection_ui")
	if ultimate_ui and ultimate_ui.visible:
		return

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
			KEY_R:
				# Keyboard shortcut for reroll
				if not reroll_used:
					_on_reroll_pressed()

func _on_reroll_pressed() -> void:
	"""Reroll all 3 ability choices. Can only be used once per selection."""
	if reroll_used or is_rolling:
		return

	# Mark as used
	reroll_used = true
	if reroll_button:
		reroll_button.disabled = true

	# Play sound
	if SoundManager and SoundManager.has_method("play_click"):
		SoundManager.play_click()

	# Get new random abilities
	var is_melee = CharacterManager.get_selected_character().attack_type == CharacterData.AttackType.MELEE if CharacterManager else false
	var new_choices = ActiveAbilityManager.get_random_abilities_for_level(current_level, is_melee, 3)

	if new_choices.is_empty():
		return

	current_choices = new_choices

	# Restart the slot machine animation with new choices
	is_rolling = true
	roll_timer = 0.0
	# Reset arrays based on current choices count
	slots_settled = []
	roll_tick_timers = []
	slot_settle_times = []
	for i in current_choices.size():
		slots_settled.append(false)
		roll_tick_timers.append(0.0)
		slot_settle_times.append(0.6 + i * 0.2)

	# Disable ability buttons during rolling
	for button in ability_buttons:
		button.disabled = true

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

# ============================================
# PARTICLE EFFECTS
# ============================================

func _create_particle_container(rarity: ActiveAbilityData.Rarity) -> Control:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = -1  # Render behind card content
	container.clip_contents = false

	# Only add particles for non-common rarities
	if rarity == ActiveAbilityData.Rarity.COMMON:
		container.visible = false
		return container

	# Get rarity color and settings based on rarity
	var rarity_color = ActiveAbilityData.get_rarity_color(rarity)
	var intensity = _get_particle_intensity(rarity)
	var density = _get_particle_density(rarity)

	# Create main top particle strip (behind card, rising above)
	var top_particles = ColorRect.new()
	top_particles.custom_minimum_size = Vector2(200, 130)
	top_particles.anchor_left = 0.5
	top_particles.anchor_right = 0.5
	top_particles.anchor_top = 0.0
	top_particles.anchor_bottom = 0.0
	top_particles.offset_left = -100
	top_particles.offset_right = 100
	top_particles.offset_top = -100
	top_particles.offset_bottom = 30
	top_particles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if rarity_particle_shader:
		var top_mat = ShaderMaterial.new()
		top_mat.shader = rarity_particle_shader
		top_mat.set_shader_parameter("rarity_color", rarity_color)
		top_mat.set_shader_parameter("intensity", intensity)
		top_mat.set_shader_parameter("speed", 1.2)
		top_mat.set_shader_parameter("particle_density", density)
		top_mat.set_shader_parameter("pixel_size", 0.07)
		top_particles.material = top_mat
	else:
		top_particles.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	container.add_child(top_particles)

	# Create top-left corner particle effect
	var top_left_particles = ColorRect.new()
	top_left_particles.custom_minimum_size = Vector2(80, 130)
	top_left_particles.anchor_left = 0.0
	top_left_particles.anchor_right = 0.0
	top_left_particles.anchor_top = 0.0
	top_left_particles.anchor_bottom = 0.0
	top_left_particles.offset_left = -30
	top_left_particles.offset_right = 50
	top_left_particles.offset_top = -80
	top_left_particles.offset_bottom = 50
	top_left_particles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if rarity_particle_shader:
		var tl_mat = ShaderMaterial.new()
		tl_mat.shader = rarity_particle_shader
		tl_mat.set_shader_parameter("rarity_color", rarity_color)
		tl_mat.set_shader_parameter("intensity", intensity * 0.8)
		tl_mat.set_shader_parameter("speed", 1.0)
		tl_mat.set_shader_parameter("particle_density", density * 0.5)
		tl_mat.set_shader_parameter("pixel_size", 0.08)
		top_left_particles.material = tl_mat
	else:
		top_left_particles.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	container.add_child(top_left_particles)

	# Create top-right corner particle effect
	var top_right_particles = ColorRect.new()
	top_right_particles.custom_minimum_size = Vector2(80, 130)
	top_right_particles.anchor_left = 1.0
	top_right_particles.anchor_right = 1.0
	top_right_particles.anchor_top = 0.0
	top_right_particles.anchor_bottom = 0.0
	top_right_particles.offset_left = -50
	top_right_particles.offset_right = 30
	top_right_particles.offset_top = -80
	top_right_particles.offset_bottom = 50
	top_right_particles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if rarity_particle_shader:
		var tr_mat = ShaderMaterial.new()
		tr_mat.shader = rarity_particle_shader
		tr_mat.set_shader_parameter("rarity_color", rarity_color)
		tr_mat.set_shader_parameter("intensity", intensity * 0.8)
		tr_mat.set_shader_parameter("speed", 1.1)
		tr_mat.set_shader_parameter("particle_density", density * 0.5)
		tr_mat.set_shader_parameter("pixel_size", 0.08)
		top_right_particles.material = tr_mat
	else:
		top_right_particles.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	container.add_child(top_right_particles)

	return container

func _get_particle_intensity(rarity: ActiveAbilityData.Rarity) -> float:
	match rarity:
		ActiveAbilityData.Rarity.RARE:
			return 1.2
		ActiveAbilityData.Rarity.EPIC:
			return 1.6
		ActiveAbilityData.Rarity.LEGENDARY:
			return 2.0
		ActiveAbilityData.Rarity.MYTHIC:
			return 2.5
		_:
			return 0.0

func _get_particle_density(rarity: ActiveAbilityData.Rarity) -> float:
	match rarity:
		ActiveAbilityData.Rarity.RARE:
			return 10.0
		ActiveAbilityData.Rarity.EPIC:
			return 14.0
		ActiveAbilityData.Rarity.LEGENDARY:
			return 20.0
		ActiveAbilityData.Rarity.MYTHIC:
			return 28.0
		_:
			return 0.0

func _update_particle_container(container: Control, rarity: ActiveAbilityData.Rarity) -> void:
	if rarity == ActiveAbilityData.Rarity.COMMON:
		container.visible = false
		return

	container.visible = true
	var rarity_color = ActiveAbilityData.get_rarity_color(rarity)
	var intensity = _get_particle_intensity(rarity)
	var density = _get_particle_density(rarity)

	# Update all particle strips
	var child_index = 0
	for child in container.get_children():
		if child is ColorRect and child.material is ShaderMaterial:
			child.material.set_shader_parameter("rarity_color", rarity_color)
			if child_index == 0:
				child.material.set_shader_parameter("intensity", intensity)
				child.material.set_shader_parameter("particle_density", density)
			else:
				child.material.set_shader_parameter("intensity", intensity * 0.8)
				child.material.set_shader_parameter("particle_density", density * 0.5)
			child_index += 1
