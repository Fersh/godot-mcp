extends CanvasLayer
class_name UltimateSelectionUI

signal ultimate_selected(ability: UltimateAbilityData)

const ULTIMATE_BASE := Color(0.2, 1.0, 0.3)  # Bright green
const ULTIMATE_DARK := Color(0.05, 0.15, 0.05)  # Dark green

var current_choices: Array = []
var ability_buttons: Array[Button] = []
var all_ultimates_pool: Array = []

# Fire effect for cards
var fire_containers: Array[Control] = []
var fire_particles: Array[Array] = []
const FIRE_PARTICLE_COUNT := 12
const FIRE_UPDATE_RATE := 0.08
var fire_update_timer: float = 0.0

# Slot machine state
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 1.2  # Slightly longer for more drama
var slots_settled: Array[bool] = []
var slot_settle_times: Array[float] = []  # Dynamically set based on ability count
var current_roll_speed: float = 0.04
var roll_tick_timers: Array[float] = []

@onready var panel: PanelContainer
@onready var title_label: Label
@onready var choices_container: HBoxContainer

var pixel_font: Font = null

func _ready() -> void:
	visible = false
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("ultimate_selection_ui")

	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_create_ui()

func _create_ui() -> void:
	# Full-screen panel with dark golden tint
	panel = PanelContainer.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	# Style with dark purple semi-transparent background (90% transparent)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0.04, 0.02, 0.08, 0.1)
	panel.add_theme_stylebox_override("panel", panel_style)
	add_child(panel)

	# Content VBox - centered
	var vbox = VBoxContainer.new()
	vbox.name = "VBoxContainer"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 25)
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	panel.add_child(vbox)

	# "ULTIMATE" small tag
	var ultimate_tag = Label.new()
	ultimate_tag.text = "LEVEL 15"
	ultimate_tag.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	ultimate_tag.add_theme_font_size_override("font_size", 14)
	ultimate_tag.add_theme_color_override("font_color", Color(0.7, 0.6, 0.4))
	if pixel_font:
		ultimate_tag.add_theme_font_override("font", pixel_font)
	vbox.add_child(ultimate_tag)

	# Title
	title_label = Label.new()
	title_label.name = "TitleLabel"
	title_label.text = "ULTIMATE ABILITY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 38)
	title_label.add_theme_color_override("font_color", ULTIMATE_BASE)  # Bright green
	title_label.add_theme_color_override("font_outline_color", ULTIMATE_DARK)
	title_label.add_theme_constant_override("outline_size", 3)
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(title_label)

	# Subtitle
	var subtitle = Label.new()
	subtitle.text = "Choose your signature power"
	subtitle.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	subtitle.add_theme_font_size_override("font_size", 16)
	subtitle.add_theme_color_override("font_color", Color(0.85, 0.8, 0.6))
	if pixel_font:
		subtitle.add_theme_font_override("font", pixel_font)
	vbox.add_child(subtitle)

	# Spacer
	var spacer = Control.new()
	spacer.custom_minimum_size = Vector2(0, 30)
	vbox.add_child(spacer)

	# Choices container
	choices_container = HBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 30)
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(choices_container)

func _process(delta: float) -> void:
	# Update fire particles (always when visible)
	if visible and fire_particles.size() > 0:
		fire_update_timer += delta
		if fire_update_timer >= FIRE_UPDATE_RATE:
			fire_update_timer = 0.0
			_update_all_fire_particles(FIRE_UPDATE_RATE)

	if not is_rolling:
		return

	roll_timer += delta

	for i in range(ability_buttons.size()):
		if slots_settled[i]:
			continue

		if roll_timer >= slot_settle_times[i]:
			slots_settled[i] = true
			_update_card_content(ability_buttons[i], current_choices[i])
			if SoundManager and SoundManager.has_method("play_ding"):
				SoundManager.play_ding()
			# Extra haptic for ultimate settling
			if HapticManager:
				HapticManager.medium()
		else:
			roll_tick_timers[i] += delta
			var progress = roll_timer / slot_settle_times[i]
			var current_speed = current_roll_speed * (1.0 + progress * 3.0)

			if roll_tick_timers[i] >= current_speed:
				roll_tick_timers[i] = 0.0
				if all_ultimates_pool.size() > 0:
					var random_ultimate = all_ultimates_pool[randi() % all_ultimates_pool.size()]
					_update_card_content(ability_buttons[i], random_ultimate)

	if slots_settled.all(func(s): return s):
		is_rolling = false
		for button in ability_buttons:
			button.disabled = false

func show_choices(ultimates: Array, character_class_id: String) -> void:
	current_choices = ultimates

	# Clear previous fire effects
	fire_containers.clear()
	fire_particles.clear()

	# Get pool for slot machine effect
	var ultimate_class = UltimateAbilityManager._convert_character_id_to_class(character_class_id) if UltimateAbilityManager else UltimateAbilityData.CharacterClass.ARCHER
	all_ultimates_pool = UltimateAbilityDatabase.get_ultimates_for_class(ultimate_class)
	if all_ultimates_pool.is_empty():
		all_ultimates_pool = ultimates

	# Clear previous buttons
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()

	# Reset slot machine state - dynamically sized based on ability count
	is_rolling = true
	roll_timer = 0.0
	slots_settled = []
	roll_tick_timers = []
	slot_settle_times = []
	for i in ultimates.size():
		slots_settled.append(false)
		roll_tick_timers.append(0.0)
		# Stagger settle times: first card settles at 0.7s, subsequent cards 0.25s apart
		slot_settle_times.append(0.7 + i * 0.25)

	# Create cards
	for i in ultimates.size():
		var random_start = all_ultimates_pool[randi() % all_ultimates_pool.size()]
		var card = _create_ultimate_card(random_start, i)
		card.disabled = true
		choices_container.add_child(card)
		ability_buttons.append(card)

	visible = true
	get_tree().paused = true

	# Play epic sound
	if SoundManager and SoundManager.has_method("play_level_up"):
		SoundManager.play_level_up()

	_animate_entrance()

func _create_ultimate_card(ultimate: UltimateAbilityData, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(280, 340)  # Slightly larger than regular ability cards
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = false

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 8)

	# Top spacer
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 12)
	vbox.add_child(top_spacer)

	# Ultimate name
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = ultimate.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 20)
	name_label.add_theme_color_override("font_color", ULTIMATE_BASE)
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Separator line
	var separator = HSeparator.new()
	var sep_style = StyleBoxLine.new()
	sep_style.color = Color(ULTIMATE_BASE.r, ULTIMATE_BASE.g, ULTIMATE_BASE.b, 0.4)
	sep_style.thickness = 1
	separator.add_theme_stylebox_override("separator", sep_style)
	vbox.add_child(separator)

	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = ultimate.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 13)
	desc_label.add_theme_color_override("font_color", Color(0.9, 0.88, 0.8))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	# Cooldown info
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.text = "Cooldown: " + str(int(ultimate.cooldown)) + "s"
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 12)
	cooldown_label.add_theme_color_override("font_color", Color(0.6, 0.55, 0.4))
	if pixel_font:
		cooldown_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(cooldown_label)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(bottom_spacer)

	# Margin container
	var margin = MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 24)
	margin.add_theme_constant_override("margin_bottom", 14)
	margin.add_child(vbox)

	button.add_child(margin)

	# "ULTIMATE" rarity tag
	var rarity_tag = _create_ultimate_tag()
	rarity_tag.name = "RarityTag"
	button.add_child(rarity_tag)

	_style_ultimate_button(button)

	# Add fire effect
	_add_fire_effect(button)

	button.pressed.connect(_on_ultimate_selected.bind(index))

	return button

func _create_ultimate_tag() -> CenterContainer:
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 0
	center.offset_top = -14
	center.offset_bottom = 14

	var tag = PanelContainer.new()

	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = ULTIMATE_BASE
	tag_style.set_corner_radius_all(6)
	tag_style.content_margin_left = 14
	tag_style.content_margin_right = 14
	tag_style.content_margin_top = 5
	tag_style.content_margin_bottom = 5
	# Add subtle shadow/glow effect
	tag_style.shadow_color = Color(1.0, 0.9, 0.5, 0.5)
	tag_style.shadow_size = 4
	tag.add_theme_stylebox_override("panel", tag_style)

	var label = Label.new()
	label.name = "RarityLabel"
	label.text = "ULTIMATE"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 13)
	label.add_theme_color_override("font_color", Color(0.1, 0.08, 0.02))
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	tag.add_child(label)

	center.add_child(tag)
	return center

func _style_ultimate_button(button: Button) -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.1, 0.05, 0.98)
	style.border_color = ULTIMATE_BASE
	style.set_border_width_all(4)
	style.set_corner_radius_all(14)
	# Add golden glow
	style.shadow_color = Color(1.0, 0.84, 0.0, 0.3)
	style.shadow_size = 8

	button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = Color(0.18, 0.15, 0.08, 0.98)
	hover_style.shadow_size = 12
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = Color(0.08, 0.06, 0.02, 0.98)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _update_card_content(button: Button, ultimate: UltimateAbilityData) -> void:
	var margin = button.get_child(0) as MarginContainer
	if not margin:
		return
	var vbox = margin.get_child(0) as VBoxContainer
	if not vbox:
		return

	# Update name (child 1 after top_spacer)
	var name_label = vbox.get_child(1) as Label
	if name_label:
		name_label.text = ultimate.name

	# Update description (child 3 after separator)
	var desc_label = vbox.get_child(3) as Label
	if desc_label:
		desc_label.text = ultimate.description

	# Update cooldown (child 4)
	var cooldown_label = vbox.get_child(4) as Label
	if cooldown_label:
		cooldown_label.text = "Cooldown: " + str(int(ultimate.cooldown)) + "s"

func _on_ultimate_selected(index: int) -> void:
	if is_rolling:
		return

	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if index >= 0 and index < current_choices.size():
		var ultimate = current_choices[index]

		# Acquire the ultimate
		if UltimateAbilityManager:
			UltimateAbilityManager.acquire_ultimate(ultimate)

		# Play epic sound
		if SoundManager and SoundManager.has_method("play_buff"):
			SoundManager.play_buff()

		# Heavy haptic
		if HapticManager:
			HapticManager.heavy()

		emit_signal("ultimate_selected", ultimate)

		hide_selection()

func hide_selection() -> void:
	visible = false
	_safe_unpause()
	# Clear fire particles
	fire_containers.clear()
	fire_particles.clear()

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

	# Check if active ability selection UI is visible
	var active_ui = get_tree().get_first_node_in_group("active_ability_selection_ui")
	if active_ui and active_ui.visible:
		return

	# Check if item pickup UI is visible
	var item_ui = get_tree().get_first_node_in_group("item_pickup_ui")
	if item_ui and item_ui.visible:
		return

	get_tree().paused = false

func _input(event: InputEvent) -> void:
	if not visible or is_rolling:
		return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1, KEY_J, KEY_Q:
				if current_choices.size() > 0:
					_on_ultimate_selected(0)
			KEY_2, KEY_K, KEY_W:
				if current_choices.size() > 1:
					_on_ultimate_selected(1)
			KEY_3, KEY_L, KEY_E:
				if current_choices.size() > 2:
					_on_ultimate_selected(2)

func _animate_entrance() -> void:
	if panel:
		panel.scale = Vector2(0.85, 0.85)
		panel.modulate.a = 0.0
		panel.pivot_offset = panel.size / 2

		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

	if title_label:
		title_label.scale = Vector2(1.8, 1.8)
		title_label.pivot_offset = Vector2(title_label.size.x / 2, title_label.size.y / 2)

		var title_tween = create_tween()
		title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.5).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	for i in ability_buttons.size():
		var button = ability_buttons[i]
		button.modulate.a = 0.0
		var original_pos = button.position
		button.position.y += 60

		var card_tween = create_tween()
		card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tween.tween_interval(0.12 * i)
		card_tween.set_parallel(true)
		card_tween.tween_property(button, "position:y", original_pos.y, 0.35).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		card_tween.tween_property(button, "modulate:a", 1.0, 0.25).set_ease(Tween.EASE_OUT)

# ============================================
# PURPLE FIRE EFFECT FOR ULTIMATE CARDS
# ============================================

func _add_fire_effect(button: Button) -> void:
	"""Add purple fire particles above an ultimate card."""
	var fire_container = Control.new()
	fire_container.name = "FireContainer"
	fire_container.size = Vector2(button.custom_minimum_size.x + 40, 60)
	fire_container.position = Vector2(-20, -55)  # Position above the card
	fire_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_container.clip_contents = false
	button.add_child(fire_container)
	fire_containers.append(fire_container)

	var card_particles: Array = []
	for i in range(FIRE_PARTICLE_COUNT):
		var particle = ColorRect.new()
		particle.name = "FireParticle" + str(i)
		particle.size = Vector2(6, 6)
		particle.color = _get_ultimate_color()
		particle.color.a = 0.0
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fire_container.add_child(particle)

		var p_data = {
			"node": particle,
			"x": 0.0,
			"y": 0.0,
			"speed": 0.0,
			"wobble": 0.0,
			"lifetime": 0.0,
			"max_lifetime": 0.0,
			"card_width": button.custom_minimum_size.x
		}
		_reset_fire_particle(p_data)
		card_particles.append(p_data)

	fire_particles.append(card_particles)

func _reset_fire_particle(p: Dictionary) -> void:
	"""Reset a fire particle to start position."""
	var card_width = p.get("card_width", 280.0)
	var spawn_spread = card_width * 0.7
	var center_x = (card_width + 40) / 2.0

	p["x"] = center_x + randf_range(-spawn_spread / 2, spawn_spread / 2)
	p["y"] = 55 + randf_range(-5, 5)  # Start at bottom
	p["speed"] = randf_range(50, 80)
	p["wobble"] = randf_range(-1.0, 1.0)
	p["lifetime"] = 0.0
	p["max_lifetime"] = randf_range(0.3, 0.6)

	p["node"].color = _get_ultimate_color()
	p["node"].color.a = 0.9

func _update_all_fire_particles(delta: float) -> void:
	"""Update all fire particles on all cards."""
	var ultimate_color = _get_ultimate_color()

	for card_idx in range(fire_particles.size()):
		var card_particles = fire_particles[card_idx]

		for p in card_particles:
			p["lifetime"] += delta
			var life_ratio = p["lifetime"] / p["max_lifetime"]

			if life_ratio >= 1.0:
				_reset_fire_particle(p)
				p["node"].color = ultimate_color
				continue

			# Move upward
			p["y"] -= p["speed"] * delta

			# Wobble side to side
			p["wobble"] += randf_range(-5, 5) * delta
			p["x"] += p["wobble"] * delta * 20

			# Update position
			p["node"].position = Vector2(p["x"], p["y"])

			# Green color that darkens as it rises
			var darkened = ultimate_color.lerp(Color(0.0, 0.1, 0.0), life_ratio * 0.7)
			p["node"].color = darkened

			# Fade out near end of life
			if life_ratio > 0.6:
				p["node"].color.a = (1.0 - life_ratio) / 0.4 * 0.9
			else:
				p["node"].color.a = 0.9

			# Shrink as it rises
			var size = 6.0 * (1.0 - life_ratio * 0.5)
			p["node"].size = Vector2(size, size)

func _get_ultimate_color() -> Color:
	"""Return the ultimate ability color (bright green)."""
	return ULTIMATE_BASE
