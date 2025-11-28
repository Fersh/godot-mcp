extends CanvasLayer

signal ability_selected(ability: AbilityData)

var current_choices: Array[AbilityData] = []
var ability_buttons: Array[Button] = []
var all_abilities_pool: Array[AbilityData] = []  # For slot machine effect

# Slot machine state
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 1.0  # Total roll time
var slots_settled: Array[bool] = [false, false, false]
var slot_roll_timers: Array[float] = [0.0, 0.0, 0.0]
var slot_settle_times: Array[float] = [0.6, 0.8, 1.0]  # When each slot settles (left to right)
var current_roll_speed: float = 0.05  # Time between ability changes during roll
var roll_tick_timers: Array[float] = [0.0, 0.0, 0.0]

# Particle effect containers for each card
var particle_containers: Array[Control] = []

@onready var panel: PanelContainer = $Panel
@onready var title_label: Label = $Panel/VBoxContainer/TitleLabel
@onready var choices_container: HBoxContainer = $Panel/VBoxContainer/ChoicesContainer

var pixel_font: Font = null
var rarity_particle_shader: Shader = null

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS  # Process even when paused
	# Use the same font as points/coins display
	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load rarity particle shader
	if ResourceLoader.exists("res://shaders/rarity_particles.gdshader"):
		rarity_particle_shader = load("res://shaders/rarity_particles.gdshader")

	# Apply pixel font to title
	if pixel_font and title_label:
		title_label.add_theme_font_override("font", pixel_font)

func _process(delta: float) -> void:
	if not is_rolling:
		return

	roll_timer += delta

	# Update each slot
	for i in range(ability_buttons.size()):
		if slots_settled[i]:
			continue

		# Check if this slot should settle
		if roll_timer >= slot_settle_times[i]:
			slots_settled[i] = true
			# Update to final ability
			update_card_content(ability_buttons[i], current_choices[i])
			# Play ding sound when settling
			if SoundManager:
				SoundManager.play_ding()
			# Play flash effect for non-common rarities
			if current_choices[i].rarity != AbilityData.Rarity.COMMON:
				_play_rarity_reveal_effect(ability_buttons[i], current_choices[i].rarity)
		else:
			# Still rolling - cycle through random abilities
			roll_tick_timers[i] += delta
			# Slow down as we approach settle time
			var progress = roll_timer / slot_settle_times[i]
			var current_speed = current_roll_speed * (1.0 + progress * 3.0)  # Slows down over time

			if roll_tick_timers[i] >= current_speed:
				roll_tick_timers[i] = 0.0
				# Show random ability
				if all_abilities_pool.size() > 0:
					var random_ability = all_abilities_pool[randi() % all_abilities_pool.size()]
					update_card_content(ability_buttons[i], random_ability)

	# Check if all slots settled
	if slots_settled.all(func(s): return s):
		is_rolling = false
		# Enable button interaction
		for button in ability_buttons:
			button.disabled = false

func show_choices(abilities: Array[AbilityData]) -> void:
	current_choices = abilities

	# Get all abilities for the slot machine pool
	all_abilities_pool = AbilityManager.get_available_abilities()
	if all_abilities_pool.is_empty():
		all_abilities_pool = abilities  # Fallback

	# Clear previous buttons and particle containers
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()
	particle_containers.clear()

	# Reset slot machine state
	is_rolling = true
	roll_timer = 0.0
	slots_settled = [false, false, false]
	roll_tick_timers = [0.0, 0.0, 0.0]

	# Create buttons for each ability (start with random display)
	for i in abilities.size():
		var random_start = all_abilities_pool[randi() % all_abilities_pool.size()]
		var card = create_ability_card(random_start, i)
		card.disabled = true  # Disable until rolling completes
		choices_container.add_child(card)
		ability_buttons.append(card)

	# Show and pause
	visible = true
	get_tree().paused = true

	# Animate entrance
	_animate_entrance()

func create_ability_card(ability: AbilityData, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(260, 300)
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = false

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)

	# Spacer above ability name (for rarity tag)
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(top_spacer)

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

	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = ability.description
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 12)
	desc_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	# Bottom spacer
	var bottom_spacer = Control.new()
	bottom_spacer.custom_minimum_size = Vector2(0, 8)
	vbox.add_child(bottom_spacer)

	# Add margin container
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

	# Add particle effect container for non-common rarities
	var particle_container = _create_particle_container(ability.rarity)
	particle_container.name = "ParticleContainer"
	button.add_child(particle_container)
	particle_containers.append(particle_container)

	# Style the button
	style_button(button, ability.rarity)

	# Connect click
	button.pressed.connect(_on_ability_selected.bind(index))

	return button

func _create_rarity_tag(rarity: AbilityData.Rarity) -> CenterContainer:
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
	tag_style.bg_color = AbilityData.get_rarity_color(rarity)
	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 10
	tag_style.content_margin_right = 10
	tag_style.content_margin_top = 4
	tag_style.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_style)

	# Rarity label inside tag
	var label = Label.new()
	label.name = "RarityLabel"
	label.text = AbilityData.get_rarity_name(rarity)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 10)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	tag.add_child(label)

	center.add_child(tag)
	return center

func _create_particle_container(rarity: AbilityData.Rarity) -> Control:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = 5  # Render above card content for fire effect
	container.clip_contents = false

	# Only add particles for non-common rarities
	if rarity == AbilityData.Rarity.COMMON:
		container.visible = false
		return container

	# Get rarity color and settings based on rarity
	var rarity_color = AbilityData.get_rarity_color(rarity)
	var intensity = _get_particle_intensity(rarity)
	var density = _get_particle_density(rarity)

	# Create top particle strip (main fire effect rising above card)
	var top_particles = ColorRect.new()
	top_particles.anchor_left = 0.0
	top_particles.anchor_right = 1.0
	top_particles.anchor_top = 0.0
	top_particles.anchor_bottom = 0.0
	top_particles.offset_left = 5
	top_particles.offset_right = -5
	top_particles.offset_top = -80  # Extend above the card
	top_particles.offset_bottom = 60  # Overlap into card
	top_particles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if rarity_particle_shader:
		var top_mat = ShaderMaterial.new()
		top_mat.shader = rarity_particle_shader
		top_mat.set_shader_parameter("rarity_color", rarity_color)
		top_mat.set_shader_parameter("intensity", intensity)
		top_mat.set_shader_parameter("speed", 1.0)
		top_mat.set_shader_parameter("particle_density", density)
		top_particles.material = top_mat
	else:
		top_particles.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	container.add_child(top_particles)

	# Create left particle strip
	var left_particles = ColorRect.new()
	left_particles.anchor_left = 0.0
	left_particles.anchor_right = 0.0
	left_particles.anchor_top = 0.0
	left_particles.anchor_bottom = 1.0
	left_particles.offset_left = -40
	left_particles.offset_right = 30
	left_particles.offset_top = 20
	left_particles.offset_bottom = -20
	left_particles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if rarity_particle_shader:
		var left_mat = ShaderMaterial.new()
		left_mat.shader = rarity_particle_shader
		left_mat.set_shader_parameter("rarity_color", rarity_color)
		left_mat.set_shader_parameter("intensity", intensity * 0.7)
		left_mat.set_shader_parameter("speed", 1.2)
		left_mat.set_shader_parameter("particle_density", density * 0.6)
		left_particles.material = left_mat
	else:
		left_particles.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	container.add_child(left_particles)

	# Create right particle strip
	var right_particles = ColorRect.new()
	right_particles.anchor_left = 1.0
	right_particles.anchor_right = 1.0
	right_particles.anchor_top = 0.0
	right_particles.anchor_bottom = 1.0
	right_particles.offset_left = -30
	right_particles.offset_right = 40
	right_particles.offset_top = 20
	right_particles.offset_bottom = -20
	right_particles.mouse_filter = Control.MOUSE_FILTER_IGNORE

	if rarity_particle_shader:
		var right_mat = ShaderMaterial.new()
		right_mat.shader = rarity_particle_shader
		right_mat.set_shader_parameter("rarity_color", rarity_color)
		right_mat.set_shader_parameter("intensity", intensity * 0.7)
		right_mat.set_shader_parameter("speed", 1.3)
		right_mat.set_shader_parameter("particle_density", density * 0.6)
		right_particles.material = right_mat
	else:
		right_particles.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)

	container.add_child(right_particles)

	return container

func _get_particle_intensity(rarity: AbilityData.Rarity) -> float:
	match rarity:
		AbilityData.Rarity.RARE:
			return 1.2
		AbilityData.Rarity.LEGENDARY:
			return 1.8
		AbilityData.Rarity.MYTHIC:
			return 2.5
		_:
			return 0.0

func _get_particle_density(rarity: AbilityData.Rarity) -> float:
	match rarity:
		AbilityData.Rarity.RARE:
			return 10.0
		AbilityData.Rarity.LEGENDARY:
			return 16.0
		AbilityData.Rarity.MYTHIC:
			return 24.0
		_:
			return 0.0

func _update_particle_container(container: Control, rarity: AbilityData.Rarity) -> void:
	if rarity == AbilityData.Rarity.COMMON:
		container.visible = false
		return

	container.visible = true
	var rarity_color = AbilityData.get_rarity_color(rarity)
	var intensity = _get_particle_intensity(rarity)
	var density = _get_particle_density(rarity)

	# Update all particle strips (top, left, right)
	var child_index = 0
	for child in container.get_children():
		if child is ColorRect and child.material is ShaderMaterial:
			child.material.set_shader_parameter("rarity_color", rarity_color)
			# Top strip gets full intensity, sides get reduced
			if child_index == 0:
				child.material.set_shader_parameter("intensity", intensity)
				child.material.set_shader_parameter("particle_density", density)
			else:
				child.material.set_shader_parameter("intensity", intensity * 0.7)
				child.material.set_shader_parameter("particle_density", density * 0.6)
			child_index += 1

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
			style.border_color = AbilityData.get_rarity_color(rarity)
		AbilityData.Rarity.MYTHIC:
			style.bg_color = Color(0.18, 0.08, 0.1, 0.95)  # Dark red-tinted background
			style.border_color = AbilityData.get_rarity_color(rarity)  # Red mythic border
		_:
			# Fallback for unknown rarity
			style.bg_color = Color(0.15, 0.15, 0.18, 0.95)
			style.border_color = Color(0.4, 0.4, 0.4)

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

func update_card_content(button: Button, ability: AbilityData) -> void:
	# Find the margin container and vbox inside the button
	var margin = button.get_child(0) as MarginContainer
	if not margin:
		return
	var vbox = margin.get_child(0) as VBoxContainer
	if not vbox:
		return

	# Children: 0=top_spacer, 1=name, 2=desc, 3=bottom_spacer
	# Update name label (child 1)
	var name_label = vbox.get_child(1) as Label
	if name_label:
		name_label.text = ability.name

	# Update description label (child 2)
	var desc_label = vbox.get_child(2) as Label
	if desc_label:
		desc_label.text = ability.description

	# Update rarity tag (child 1 of button is CenterContainer, which contains PanelContainer)
	var center_container = button.get_child(1) as CenterContainer
	if center_container:
		var rarity_tag = center_container.get_child(0) as PanelContainer
		if rarity_tag:
			var tag_style = rarity_tag.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			tag_style.bg_color = AbilityData.get_rarity_color(ability.rarity)
			rarity_tag.add_theme_stylebox_override("panel", tag_style)
			var rarity_label = rarity_tag.get_child(0) as Label
			if rarity_label:
				rarity_label.text = AbilityData.get_rarity_name(ability.rarity)

	# Update particle container (child 2 of button)
	var particle_container = button.get_node_or_null("ParticleContainer") as Control
	if particle_container:
		_update_particle_container(particle_container, ability.rarity)

	# Update button style
	style_button(button, ability.rarity)

func _on_ability_selected(index: int) -> void:
	# Don't allow selection while rolling
	if is_rolling:
		return

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
	if not visible or is_rolling:
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

func _animate_entrance() -> void:
	# Animate the panel scaling up and fading in
	if panel:
		panel.scale = Vector2(0.8, 0.8)
		panel.modulate.a = 0.0
		panel.pivot_offset = panel.size / 2

		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.set_parallel(true)
		tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		tween.tween_property(panel, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

	# Animate title with a bounce
	if title_label:
		title_label.scale = Vector2(1.5, 1.5)
		title_label.pivot_offset = Vector2(title_label.size.x / 2, title_label.size.y / 2)

		var title_tween = create_tween()
		title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Animate each card sliding in from below with stagger
	for i in ability_buttons.size():
		var button = ability_buttons[i]
		button.modulate.a = 0.0
		var original_pos = button.position
		button.position.y += 50

		var card_tween = create_tween()
		card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		card_tween.tween_interval(0.1 * i)  # Stagger delay
		card_tween.set_parallel(true)
		card_tween.tween_property(button, "position:y", original_pos.y, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
		card_tween.tween_property(button, "modulate:a", 1.0, 0.2).set_ease(Tween.EASE_OUT)

func _play_rarity_reveal_effect(button: Button, rarity: AbilityData.Rarity) -> void:
	var rarity_color = AbilityData.get_rarity_color(rarity)

	# Create flash overlay
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.8)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 10
	button.add_child(flash)

	# Create expanding glow ring
	var glow = ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.5
	glow.anchor_bottom = 0.5
	glow.offset_left = -150
	glow.offset_right = 150
	glow.offset_top = -175
	glow.offset_bottom = 175
	glow.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 9
	button.add_child(glow)

	# Animate flash - quick bright flash then fade
	var flash_tween = create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.4).set_ease(Tween.EASE_OUT)
	flash_tween.tween_callback(flash.queue_free)

	# Animate glow ring expanding outward
	var glow_tween = create_tween()
	glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glow_tween.set_parallel(true)
	glow_tween.tween_property(glow, "color:a", 0.6, 0.1).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_left", -200, 0.3).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_right", 200, 0.3).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_top", -225, 0.3).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_bottom", 225, 0.3).set_ease(Tween.EASE_OUT)
	glow_tween.chain().tween_property(glow, "color:a", 0.0, 0.3).set_ease(Tween.EASE_IN)
	glow_tween.tween_callback(glow.queue_free)

	# Scale punch effect on the card
	button.pivot_offset = button.size / 2
	var scale_tween = create_tween()
	scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scale_tween.tween_property(button, "scale", Vector2(1.08, 1.08), 0.1).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Create sparkle particles around the card for legendary/mythic
	if rarity == AbilityData.Rarity.LEGENDARY or rarity == AbilityData.Rarity.MYTHIC:
		_spawn_sparkles(button, rarity_color)

	# Screen shake for mythic
	if rarity == AbilityData.Rarity.MYTHIC and JuiceManager:
		JuiceManager.shake_medium()

func _spawn_sparkles(button: Button, color: Color) -> void:
	# Spawn several sparkle particles around the card
	for i in range(8):
		var sparkle = ColorRect.new()
		sparkle.custom_minimum_size = Vector2(6, 6)
		sparkle.size = Vector2(6, 6)
		sparkle.color = Color(color.r, color.g, color.b, 1.0)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle.z_index = 11

		# Random position around the card edges
		var angle = (i / 8.0) * TAU + randf() * 0.5
		var radius = 130.0 + randf() * 20.0
		var start_pos = Vector2(
			button.size.x / 2 + cos(angle) * radius,
			button.size.y / 2 + sin(angle) * radius
		)
		sparkle.position = start_pos

		button.add_child(sparkle)

		# Animate sparkle floating up and fading
		var sparkle_tween = create_tween()
		sparkle_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		sparkle_tween.set_parallel(true)
		sparkle_tween.tween_property(sparkle, "position:y", start_pos.y - 40 - randf() * 30, 0.6).set_ease(Tween.EASE_OUT)
		sparkle_tween.tween_property(sparkle, "color:a", 0.0, 0.6).set_ease(Tween.EASE_IN)
		sparkle_tween.tween_property(sparkle, "scale", Vector2(0.3, 0.3), 0.6).set_ease(Tween.EASE_IN)
		sparkle_tween.chain().tween_callback(sparkle.queue_free)
