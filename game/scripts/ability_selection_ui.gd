extends CanvasLayer

signal ability_selected(ability: AbilityData)
signal active_upgrade_selected(ability)  # For ActiveAbilityData upgrades

var current_choices: Array = []  # Mixed: AbilityData (passives) + ActiveAbilityData (upgrades)
var ability_buttons: Array[Button] = []
var all_abilities_pool: Array[AbilityData] = []  # For slot machine effect (passives only)

# Slot machine state
var is_rolling: bool = false
var roll_timer: float = 0.0
var roll_duration: float = 1.0  # Total roll time
var slots_settled: Array[bool] = []
var slot_roll_timers: Array[float] = []
var slot_settle_times: Array[float] = []  # When each slot settles (left to right) - dynamically set
var current_roll_speed: float = 0.05  # Time between ability changes during roll
var roll_tick_timers: Array[float] = []

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
	add_to_group("ability_selection_ui")
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
			# Update to final ability (is_final_reveal = true)
			update_card_content(ability_buttons[i], current_choices[i], true)
			# Play ding sound when settling
			if SoundManager:
				SoundManager.play_ding()
			# Play flash effect and frame freeze for non-common rarities
			if not _is_common_rarity(current_choices[i]):
				var passive_rarity = _get_passive_rarity(current_choices[i])
				_play_rarity_reveal_effect(ability_buttons[i], passive_rarity)
				# Frame freeze based on rarity (more frames for higher rarity)
				var freeze_frames = _get_rarity_freeze_frames(passive_rarity)
				if freeze_frames > 0:
					_do_frame_freeze(freeze_frames)
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

func show_choices(abilities: Array) -> void:
	## Show ability choices - can be mixed AbilityData (passives) and ActiveAbilityData (upgrades)
	current_choices = abilities

	# Get all passive abilities for the slot machine pool (we only roll passives during animation)
	all_abilities_pool = AbilityManager.get_available_abilities()
	if all_abilities_pool.is_empty():
		# Fallback: filter to only AbilityData types
		for a in abilities:
			if a is AbilityData:
				all_abilities_pool.append(a)

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

func create_ability_card(ability, index: int) -> Button:
	## Create a card for either AbilityData (passive) or ActiveAbilityData (upgrade)
	var button = Button.new()
	button.custom_minimum_size = Vector2(312, 360)
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = false

	# Get ability properties (works for both types)
	var ability_name = ability.name
	var ability_desc = ability.description
	var is_upgrade = _is_active_ability_upgrade(ability)

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 0)

	# Spacer above ability name (for rarity tag + upgrade indicator)
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 8 if not is_upgrade else 24)
	vbox.add_child(top_spacer)

	# Ability name - use RichTextLabel for upgrades to show prefix in green
	if is_upgrade and ability is ActiveAbilityData and not ability.name_prefix.is_empty():
		var name_rich = RichTextLabel.new()
		name_rich.name = "NameLabel"
		name_rich.bbcode_enabled = true
		name_rich.fit_content = true
		name_rich.scroll_active = false
		name_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_rich.add_theme_font_size_override("normal_font_size", 18)
		if pixel_font:
			name_rich.add_theme_font_override("normal_font", pixel_font)
		# Build compound name: [green]Prefix[/color] [rarity]BaseName[/color] [gold]Suffix[/gold]
		var base_rarity_color = _get_base_ability_rarity_color(ability)
		var suffix = ability.name_suffix if ability.is_signature() else ""
		name_rich.text = _format_compound_name_full(ability.name_prefix, ability.base_name, suffix, base_rarity_color, ability.is_signature())
		vbox.add_child(name_rich)
	else:
		# Regular label for non-upgrades
		var name_label = Label.new()
		name_label.name = "NameLabel"
		name_label.text = ability_name
		name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		name_label.add_theme_font_size_override("font_size", 18)
		name_label.add_theme_color_override("font_color", _get_rarity_color(ability))
		name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		if pixel_font:
			name_label.add_theme_font_override("font", pixel_font)
		vbox.add_child(name_label)

	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = ability_desc
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.add_theme_font_size_override("font_size", 14)
	desc_label.add_theme_color_override("font_color", Color(0.95, 0.95, 0.95))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	if pixel_font:
		desc_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(desc_label)

	# Stat changes container (for upgrades)
	var stats_container = VBoxContainer.new()
	stats_container.name = "StatsContainer"
	stats_container.add_theme_constant_override("separation", 2)
	if is_upgrade and ability is ActiveAbilityData:
		_populate_stat_changes(stats_container, ability)
	vbox.add_child(stats_container)

	# Tier diamonds container (for upgrades)
	var tier_container = HBoxContainer.new()
	tier_container.name = "TierContainer"
	tier_container.alignment = BoxContainer.ALIGNMENT_CENTER
	tier_container.add_theme_constant_override("separation", 8)
	if is_upgrade and ability is ActiveAbilityData:
		_populate_tier_diamonds(tier_container, ability)
	vbox.add_child(tier_container)

	# Upgradeable indicator - shows for passive abilities that have upgrade paths
	var upgradeable_label = Label.new()
	upgradeable_label.name = "UpgradeableLabel"
	upgradeable_label.text = "Upgradeable"
	upgradeable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgradeable_label.add_theme_font_size_override("font_size", 12)
	upgradeable_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))  # Green
	if pixel_font:
		upgradeable_label.add_theme_font_override("font", pixel_font)
	# Only show for passive abilities that have upgrades available
	if ability is AbilityData and not is_upgrade:
		upgradeable_label.visible = ability.has_available_upgrades()
	else:
		upgradeable_label.visible = false
	vbox.add_child(upgradeable_label)

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

	# Rarity tag pinned to top
	var rarity_tag = _create_rarity_tag_for_ability(ability)
	rarity_tag.name = "RarityTag"
	button.add_child(rarity_tag)

	# Add particle effect container
	var particle_container = _create_particle_container_for_ability(ability)
	particle_container.name = "ParticleContainer"
	particle_container.visible = false
	button.add_child(particle_container)
	particle_containers.append(particle_container)

	# Style the button (upgrade-aware)
	_style_button_for_ability(button, ability)

	# Connect click
	button.pressed.connect(_on_ability_selected.bind(index))

	return button

func _is_active_ability_upgrade(ability) -> bool:
	## Check if this is an ActiveAbilityData upgrade (not a passive)
	if ability is ActiveAbilityData:
		return ability.is_upgrade()
	return false

func _get_rarity_color(ability) -> Color:
	## Get rarity color for either AbilityData or ActiveAbilityData
	if ability is ActiveAbilityData:
		return ActiveAbilityData.get_rarity_color(ability.rarity)
	return AbilityData.get_rarity_color(ability.rarity)

func _get_rarity_name(ability) -> String:
	## Get rarity name for either AbilityData or ActiveAbilityData
	if ability is ActiveAbilityData:
		return ActiveAbilityData.get_rarity_name(ability.rarity)
	return AbilityData.get_rarity_name(ability.rarity)

func _create_rarity_tag_for_ability(ability) -> CenterContainer:
	## Create rarity tag that works for both AbilityData and ActiveAbilityData
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 0
	center.offset_top = -12
	center.offset_bottom = 12

	var tag = PanelContainer.new()

	var tag_style = StyleBoxFlat.new()
	var is_upgrade = _is_active_ability_upgrade(ability)

	if is_upgrade:
		# All upgrade cards get green tag
		tag_style.bg_color = Color(0.2, 0.9, 0.3)  # Green for all upgrades
	else:
		tag_style.bg_color = _get_rarity_color(ability)

	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 10
	tag_style.content_margin_right = 10
	tag_style.content_margin_top = 4
	tag_style.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_style)

	var label = Label.new()
	label.name = "RarityLabel"
	if is_upgrade:
		label.text = "Upgrade"  # Same text for T2 and T3
	else:
		label.text = _get_rarity_name(ability)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	tag.add_child(label)

	center.add_child(tag)
	return center

func _create_rarity_tag(rarity: AbilityData.Rarity) -> CenterContainer:
	## Legacy function for passive abilities only
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 0
	center.offset_top = -12
	center.offset_bottom = 12

	var tag = PanelContainer.new()

	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = AbilityData.get_rarity_color(rarity)
	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 10
	tag_style.content_margin_right = 10
	tag_style.content_margin_top = 4
	tag_style.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_style)

	var label = Label.new()
	label.name = "RarityLabel"
	label.text = AbilityData.get_rarity_name(rarity)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	tag.add_child(label)

	center.add_child(tag)
	return center

func _create_particle_container_for_ability(ability) -> Control:
	## Create particle container for either type
	## Upgrades get green flame particles (T3 gets more intense flames)
	var is_upgrade = _is_active_ability_upgrade(ability)

	if is_upgrade:
		# Green flames for upgrade abilities - T3 gets enhanced flames
		var is_signature = ability is ActiveAbilityData and ability.is_signature()
		return _create_upgrade_particle_container(is_signature)

	if ability is ActiveAbilityData:
		# Map ActiveAbilityData.Rarity to AbilityData.Rarity for particles
		var passive_rarity = _map_active_to_passive_rarity(ability.rarity)
		return _create_particle_container(passive_rarity)
	return _create_particle_container(ability.rarity)

func _map_active_to_passive_rarity(active_rarity) -> AbilityData.Rarity:
	## Map ActiveAbilityData rarity to AbilityData rarity for particle effects
	match active_rarity:
		ActiveAbilityData.Rarity.COMMON:
			return AbilityData.Rarity.COMMON
		ActiveAbilityData.Rarity.RARE:
			return AbilityData.Rarity.RARE
		ActiveAbilityData.Rarity.EPIC:
			return AbilityData.Rarity.EPIC
		ActiveAbilityData.Rarity.LEGENDARY:
			return AbilityData.Rarity.LEGENDARY
		ActiveAbilityData.Rarity.MYTHIC:
			return AbilityData.Rarity.MYTHIC
		_:
			return AbilityData.Rarity.COMMON

func _is_common_rarity(ability) -> bool:
	## Check if ability is common rarity (works for both types)
	if ability is ActiveAbilityData:
		return ability.rarity == ActiveAbilityData.Rarity.COMMON
	return ability.rarity == AbilityData.Rarity.COMMON

func _get_passive_rarity(ability) -> AbilityData.Rarity:
	## Get passive rarity enum (maps ActiveAbilityData rarity if needed)
	if ability is ActiveAbilityData:
		return _map_active_to_passive_rarity(ability.rarity)
	return ability.rarity

func _style_button_for_ability(button: Button, ability) -> void:
	## Style button for either AbilityData or ActiveAbilityData (with upgrade styling)
	var style = StyleBoxFlat.new()
	var is_upgrade = _is_active_ability_upgrade(ability)

	if is_upgrade:
		# Upgrade cards get green styling (both T2 and T3)
		style.bg_color = Color(0.08, 0.18, 0.1, 0.98)
		style.border_color = Color(0.2, 0.9, 0.3)
		style.set_border_width_all(4)  # Thicker border for upgrades
	else:
		# Standard passive ability styling
		var rarity = ability.rarity
		if ability is AbilityData:
			match rarity:
				AbilityData.Rarity.COMMON:
					style.bg_color = Color(0.15, 0.15, 0.18, 0.98)
					style.border_color = Color(0.4, 0.4, 0.4)
				AbilityData.Rarity.RARE:
					style.bg_color = Color(0.1, 0.15, 0.25, 0.98)
					style.border_color = Color(0.3, 0.5, 1.0)
				AbilityData.Rarity.EPIC:
					style.bg_color = Color(0.15, 0.1, 0.2, 0.98)
					style.border_color = AbilityData.get_rarity_color(rarity)
				AbilityData.Rarity.LEGENDARY:
					style.bg_color = Color(0.2, 0.18, 0.1, 0.98)
					style.border_color = AbilityData.get_rarity_color(rarity)
				AbilityData.Rarity.MYTHIC:
					style.bg_color = Color(0.18, 0.08, 0.1, 0.98)
					style.border_color = AbilityData.get_rarity_color(rarity)
				_:
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

func _create_particle_container(rarity: AbilityData.Rarity) -> Control:
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = -1  # Render behind card content
	container.clip_contents = false

	# Only add particles for non-common rarities
	if rarity == AbilityData.Rarity.COMMON:
		container.visible = false
		return container

	# Get rarity color and settings based on rarity
	var rarity_color = AbilityData.get_rarity_color(rarity)
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
	top_particles.offset_top = -100  # Extend well above the card
	top_particles.offset_bottom = 30  # Slight overlap into card top
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

func _get_particle_intensity(rarity: AbilityData.Rarity) -> float:
	match rarity:
		AbilityData.Rarity.RARE:
			return 1.2
		AbilityData.Rarity.EPIC:
			return 1.6
		AbilityData.Rarity.LEGENDARY:
			return 2.0
		AbilityData.Rarity.MYTHIC:
			return 2.5
		_:
			return 0.0

func _get_particle_density(rarity: AbilityData.Rarity) -> float:
	match rarity:
		AbilityData.Rarity.RARE:
			return 10.0
		AbilityData.Rarity.EPIC:
			return 14.0
		AbilityData.Rarity.LEGENDARY:
			return 20.0
		AbilityData.Rarity.MYTHIC:
			return 28.0
		_:
			return 0.0

func _create_upgrade_particle_container(is_signature: bool = false) -> Control:
	## Create green flame particles for upgrade abilities
	## T3/Signature abilities get more intense flames
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	container.z_index = -1  # Render behind card content
	container.clip_contents = false

	var green_color = Color(0.2, 0.93, 0.35)  # Bright green
	# T3 gets more intense and denser flames
	var intensity = 2.2 if is_signature else 1.5
	var density = 22.0 if is_signature else 14.0

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
		top_mat.set_shader_parameter("rarity_color", green_color)
		top_mat.set_shader_parameter("intensity", intensity)
		top_mat.set_shader_parameter("speed", 1.2)
		top_mat.set_shader_parameter("particle_density", density)
		top_mat.set_shader_parameter("pixel_size", 0.07)
		top_particles.material = top_mat
	else:
		top_particles.color = Color(green_color.r, green_color.g, green_color.b, 0.3)

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
		tl_mat.set_shader_parameter("rarity_color", green_color)
		tl_mat.set_shader_parameter("intensity", intensity * 0.8)
		tl_mat.set_shader_parameter("speed", 1.0)
		tl_mat.set_shader_parameter("particle_density", density * 0.5)
		tl_mat.set_shader_parameter("pixel_size", 0.08)
		top_left_particles.material = tl_mat
	else:
		top_left_particles.color = Color(green_color.r, green_color.g, green_color.b, 0.3)

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
		tr_mat.set_shader_parameter("rarity_color", green_color)
		tr_mat.set_shader_parameter("intensity", intensity * 0.8)
		tr_mat.set_shader_parameter("speed", 1.1)
		tr_mat.set_shader_parameter("particle_density", density * 0.5)
		tr_mat.set_shader_parameter("pixel_size", 0.08)
		top_right_particles.material = tr_mat
	else:
		top_right_particles.color = Color(green_color.r, green_color.g, green_color.b, 0.3)

	container.add_child(top_right_particles)

	return container

func _update_particle_container(container: Control, rarity: AbilityData.Rarity) -> void:
	if rarity == AbilityData.Rarity.COMMON:
		container.visible = false
		return

	container.visible = true
	var rarity_color = AbilityData.get_rarity_color(rarity)
	var intensity = _get_particle_intensity(rarity)
	var density = _get_particle_density(rarity)

	# Update all particle strips (top center, top-left corner, top-right corner)
	var child_index = 0
	for child in container.get_children():
		if child is ColorRect and child.material is ShaderMaterial:
			child.material.set_shader_parameter("rarity_color", rarity_color)
			# Top center strip gets full intensity, corners get reduced
			if child_index == 0:
				child.material.set_shader_parameter("intensity", intensity)
				child.material.set_shader_parameter("particle_density", density)
			else:
				child.material.set_shader_parameter("intensity", intensity * 0.8)
				child.material.set_shader_parameter("particle_density", density * 0.5)
			child_index += 1

func _update_particle_container_to_upgrade(container: Control) -> void:
	## Update an existing particle container to use green upgrade colors
	container.visible = true
	var green_color = Color(0.2, 0.93, 0.35)  # Bright green
	var intensity = 1.5
	var density = 14.0

	# Update all particle strips to green
	var child_index = 0
	for child in container.get_children():
		if child is ColorRect and child.material is ShaderMaterial:
			child.material.set_shader_parameter("rarity_color", green_color)
			# Top center strip gets full intensity, corners get reduced
			if child_index == 0:
				child.material.set_shader_parameter("intensity", intensity)
				child.material.set_shader_parameter("particle_density", density)
			else:
				child.material.set_shader_parameter("intensity", intensity * 0.8)
				child.material.set_shader_parameter("particle_density", density * 0.5)
			child_index += 1

func style_button(button: Button, rarity: AbilityData.Rarity) -> void:
	var style = StyleBoxFlat.new()

	# Background based on rarity - reduced transparency (0.98 instead of 0.95)
	match rarity:
		AbilityData.Rarity.COMMON:
			style.bg_color = Color(0.15, 0.15, 0.18, 0.98)
			style.border_color = Color(0.4, 0.4, 0.4)
		AbilityData.Rarity.RARE:
			style.bg_color = Color(0.1, 0.15, 0.25, 0.98)
			style.border_color = Color(0.3, 0.5, 1.0)
		AbilityData.Rarity.EPIC:
			style.bg_color = Color(0.15, 0.1, 0.2, 0.98)  # Purple-tinted background
			style.border_color = AbilityData.get_rarity_color(rarity)
		AbilityData.Rarity.LEGENDARY:
			style.bg_color = Color(0.2, 0.18, 0.1, 0.98)  # Yellow-tinted background
			style.border_color = AbilityData.get_rarity_color(rarity)
		AbilityData.Rarity.MYTHIC:
			style.bg_color = Color(0.18, 0.08, 0.1, 0.98)  # Dark red-tinted background
			style.border_color = AbilityData.get_rarity_color(rarity)
		_:
			# Fallback for unknown rarity
			style.bg_color = Color(0.15, 0.15, 0.18, 0.98)
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

func update_card_content(button: Button, ability, is_final_reveal: bool = false) -> void:
	## Update card content - handles both AbilityData and ActiveAbilityData
	# Find the margin container and vbox inside the button
	var margin = button.get_child(0) as MarginContainer
	if not margin:
		return
	var vbox = margin.get_child(0) as VBoxContainer
	if not vbox:
		return

	var is_upgrade = _is_active_ability_upgrade(ability)

	# Children: 0=top_spacer, 1=name, 2=desc, 3=stats_container, 4=bottom_spacer
	# Update name (child 1) - could be Label or RichTextLabel
	var name_node = vbox.get_child(1)
	if name_node:
		if is_upgrade and ability is ActiveAbilityData and not ability.name_prefix.is_empty():
			# Need RichTextLabel for compound name
			var base_rarity_color = _get_base_ability_rarity_color(ability)
			var suffix = ability.name_suffix if ability.is_signature() else ""
			var formatted_name = _format_compound_name_full(ability.name_prefix, ability.base_name, suffix, base_rarity_color, ability.is_signature())

			if name_node is RichTextLabel:
				name_node.text = formatted_name
			elif name_node is Label:
				# Replace Label with RichTextLabel
				var name_rich = RichTextLabel.new()
				name_rich.name = "NameLabel"
				name_rich.bbcode_enabled = true
				name_rich.fit_content = true
				name_rich.scroll_active = false
				name_rich.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				name_rich.add_theme_font_size_override("normal_font_size", 18)
				if pixel_font:
					name_rich.add_theme_font_override("normal_font", pixel_font)
				name_rich.text = formatted_name
				vbox.remove_child(name_node)
				name_node.queue_free()
				vbox.add_child(name_rich)
				vbox.move_child(name_rich, 1)
		else:
			# Regular label
			if name_node is Label:
				name_node.text = ability.name
				name_node.add_theme_color_override("font_color", _get_rarity_color(ability))
			elif name_node is RichTextLabel:
				# Replace RichTextLabel with Label
				var name_label = Label.new()
				name_label.name = "NameLabel"
				name_label.text = ability.name
				name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				name_label.add_theme_font_size_override("font_size", 18)
				name_label.add_theme_color_override("font_color", _get_rarity_color(ability))
				name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
				if pixel_font:
					name_label.add_theme_font_override("font", pixel_font)
				vbox.remove_child(name_node)
				name_node.queue_free()
				vbox.add_child(name_label)
				vbox.move_child(name_label, 1)

	# Update description label (child 2)
	var desc_label = vbox.get_child(2) as Label
	if desc_label:
		desc_label.text = ability.description

	# Update stats container (child 3)
	var stats_container = vbox.get_node_or_null("StatsContainer") as VBoxContainer
	if stats_container:
		# Clear and repopulate
		for child in stats_container.get_children():
			child.queue_free()
		if is_upgrade and ability is ActiveAbilityData:
			_populate_stat_changes(stats_container, ability)

	# Update tier diamonds container
	var tier_container = vbox.get_node_or_null("TierContainer") as HBoxContainer
	if tier_container:
		# Clear and repopulate
		for child in tier_container.get_children():
			child.queue_free()
		if is_upgrade and ability is ActiveAbilityData:
			_populate_tier_diamonds(tier_container, ability)

	# Update upgradeable indicator - only show on final reveal for passive abilities with upgrades
	var upgradeable_label = vbox.get_node_or_null("UpgradeableLabel") as Label
	if upgradeable_label:
		if is_final_reveal and ability is AbilityData and not is_upgrade:
			upgradeable_label.visible = ability.has_available_upgrades()
		else:
			upgradeable_label.visible = false

	# Update rarity tag (child 1 of button is CenterContainer, which contains PanelContainer)
	var center_container = button.get_child(1) as CenterContainer
	if center_container:
		var rarity_tag = center_container.get_child(0) as PanelContainer
		if rarity_tag:
			var tag_style = rarity_tag.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
			if is_upgrade:
				# All upgrades get green tag
				tag_style.bg_color = Color(0.2, 0.9, 0.3)  # Green for all upgrades
			else:
				tag_style.bg_color = _get_rarity_color(ability)
			rarity_tag.add_theme_stylebox_override("panel", tag_style)
			var rarity_label = rarity_tag.get_child(0) as Label
			if rarity_label:
				if is_upgrade:
					rarity_label.text = "Upgrade"  # Same for T2 and T3
				else:
					rarity_label.text = _get_rarity_name(ability)

	# Update particle container (child 2 of button) - only show on final reveal
	var particle_container = button.get_node_or_null("ParticleContainer") as Control
	if particle_container:
		if is_final_reveal:
			if is_upgrade:
				# Green flames for upgrades - update existing container to green
				_update_particle_container_to_upgrade(particle_container)
			else:
				var passive_rarity = ability.rarity if ability is AbilityData else _map_active_to_passive_rarity(ability.rarity)
				_update_particle_container(particle_container, passive_rarity)
		else:
			# Keep particles hidden during rolling
			particle_container.visible = false

	# Update button style
	_style_button_for_ability(button, ability)

func _on_ability_selected(index: int) -> void:
	# Don't allow selection while rolling
	if is_rolling:
		return

	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if index >= 0 and index < current_choices.size():
		var ability = current_choices[index]

		# Check if this is an active ability upgrade or a passive ability
		if ability is ActiveAbilityData:
			# Active ability upgrade - use ActiveAbilityManager
			var active_manager = get_tree().get_first_node_in_group("active_ability_manager")
			if active_manager:
				active_manager.acquire_ability(ability)
			emit_signal("active_upgrade_selected", ability)
		else:
			# Passive ability - use AbilityManager
			AbilityManager.acquire_ability(ability)
			emit_signal("ability_selected", ability)

		# Play buff sound
		if SoundManager:
			SoundManager.play_buff()

		# Hide and unpause
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

	# Check if item pickup UI is visible
	var item_ui = get_tree().get_first_node_in_group("item_pickup_ui")
	if item_ui and item_ui.visible:
		return

	# Check if active ability selection UI is visible
	var active_ability_ui = get_tree().get_first_node_in_group("active_ability_selection_ui")
	if active_ability_ui and active_ability_ui.visible:
		return

	# Check if ultimate selection UI is visible
	var ultimate_ui = get_tree().get_first_node_in_group("ultimate_selection_ui")
	if ultimate_ui and ultimate_ui.visible:
		return

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

func _get_rarity_freeze_frames(rarity: AbilityData.Rarity) -> int:
	match rarity:
		AbilityData.Rarity.RARE:
			return 2
		AbilityData.Rarity.EPIC:
			return 3
		AbilityData.Rarity.LEGENDARY:
			return 4
		AbilityData.Rarity.MYTHIC:
			return 5
		_:
			return 0

func _do_frame_freeze(frames: int) -> void:
	# Brief pause effect - since we're already paused, we use Engine.time_scale
	var freeze_duration = frames / 60.0  # Convert frames to seconds at 60fps
	Engine.time_scale = 0.0

	# Use a timer that ignores time scale
	var timer = get_tree().create_timer(freeze_duration, true, false, true)  # process_always = true
	timer.timeout.connect(func(): Engine.time_scale = 1.0)

func _play_rarity_reveal_effect(button: Button, rarity: AbilityData.Rarity) -> void:
	var rarity_color = AbilityData.get_rarity_color(rarity)

	# Get intensity multiplier based on rarity
	var intensity = 1.0
	match rarity:
		AbilityData.Rarity.RARE:
			intensity = 1.0
		AbilityData.Rarity.EPIC:
			intensity = 1.3
		AbilityData.Rarity.LEGENDARY:
			intensity = 1.7
		AbilityData.Rarity.MYTHIC:
			intensity = 2.2

	# Create flash overlay - brighter for higher rarity
	var flash = ColorRect.new()
	flash.set_anchors_preset(Control.PRESET_FULL_RECT)
	flash.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, min(0.9 * intensity, 1.0))
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	flash.z_index = 10
	button.add_child(flash)

	# Create expanding glow ring - larger for higher rarity
	var glow = ColorRect.new()
	glow.set_anchors_preset(Control.PRESET_CENTER)
	glow.anchor_left = 0.5
	glow.anchor_right = 0.5
	glow.anchor_top = 0.5
	glow.anchor_bottom = 0.5
	var base_size = 150 * intensity
	glow.offset_left = -base_size
	glow.offset_right = base_size
	glow.offset_top = -base_size * 1.15
	glow.offset_bottom = base_size * 1.15
	glow.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.0)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glow.z_index = 9
	button.add_child(glow)

	# Animate flash - quick bright flash then fade (longer for higher rarity)
	var flash_tween = create_tween()
	flash_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	flash_tween.tween_property(flash, "color:a", 0.0, 0.3 + 0.15 * intensity).set_ease(Tween.EASE_OUT)
	flash_tween.tween_callback(flash.queue_free)

	# Animate glow ring expanding outward - faster and larger for higher rarity
	var expand_size = 200 * intensity
	var glow_tween = create_tween()
	glow_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	glow_tween.set_parallel(true)
	glow_tween.tween_property(glow, "color:a", 0.5 + 0.2 * intensity, 0.08).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_left", -expand_size, 0.25).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_right", expand_size, 0.25).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_top", -expand_size * 1.15, 0.25).set_ease(Tween.EASE_OUT)
	glow_tween.tween_property(glow, "offset_bottom", expand_size * 1.15, 0.25).set_ease(Tween.EASE_OUT)
	glow_tween.chain().tween_property(glow, "color:a", 0.0, 0.25).set_ease(Tween.EASE_IN)
	glow_tween.tween_callback(glow.queue_free)

	# Scale punch effect on the card - bigger punch for higher rarity
	button.pivot_offset = button.size / 2
	var scale_amount = 1.05 + 0.03 * intensity
	var scale_tween = create_tween()
	scale_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	scale_tween.tween_property(button, "scale", Vector2(scale_amount, scale_amount), 0.08).set_ease(Tween.EASE_OUT)
	scale_tween.tween_property(button, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Create sparkle particles for all rarities
	var sparkle_count = 5
	match rarity:
		AbilityData.Rarity.COMMON:
			sparkle_count = 5
		AbilityData.Rarity.RARE:
			sparkle_count = 10
		AbilityData.Rarity.EPIC:
			sparkle_count = 15
		AbilityData.Rarity.LEGENDARY:
			sparkle_count = 20
		AbilityData.Rarity.MYTHIC:
			sparkle_count = 25
	_spawn_sparkles_count(button, rarity_color, sparkle_count)

	# Screen shake for epic and above
	if rarity == AbilityData.Rarity.EPIC and JuiceManager:
		JuiceManager.shake_small()
	elif rarity == AbilityData.Rarity.LEGENDARY and JuiceManager:
		JuiceManager.shake_small()
	elif rarity == AbilityData.Rarity.MYTHIC and JuiceManager:
		JuiceManager.shake_medium()

func _spawn_sparkles(button: Button, color: Color) -> void:
	_spawn_sparkles_count(button, color, 8)

func _spawn_sparkles_count(button: Button, color: Color, count: int) -> void:
	# Spawn sparkle particles around the card
	for i in range(count):
		var sparkle = ColorRect.new()
		sparkle.custom_minimum_size = Vector2(6, 6)
		sparkle.size = Vector2(6, 6)
		sparkle.color = Color(color.r, color.g, color.b, 1.0)
		sparkle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		sparkle.z_index = 11

		# Random position around the card edges
		var angle = (float(i) / float(count)) * TAU + randf() * 0.5
		var radius = 130.0 + randf() * 30.0
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
		sparkle_tween.tween_property(sparkle, "position:y", start_pos.y - 50 - randf() * 40, 0.7).set_ease(Tween.EASE_OUT)
		sparkle_tween.tween_property(sparkle, "color:a", 0.0, 0.7).set_ease(Tween.EASE_IN)
		sparkle_tween.tween_property(sparkle, "scale", Vector2(0.2, 0.2), 0.7).set_ease(Tween.EASE_IN)
		sparkle_tween.chain().tween_callback(sparkle.queue_free)

# ============================================
# UPGRADE CARD HELPERS
# ============================================

func _format_compound_name_full(prefix: String, base_name: String, suffix: String, base_rarity_color: Color, is_signature: bool) -> String:
	## Format compound name:
	## T2: prefix (green) + base name (rarity color)
	## T3: prefix (white) + base name (white) + suffix (green)
	var green_hex = "33ee55"  # Bright green
	var white_hex = "ffffff"  # White for T3 prefix and base
	var rarity_hex = base_rarity_color.to_html(false)

	var result = "[center]"
	if is_signature:
		# T3: prefix and base in white, suffix in green
		if not prefix.is_empty():
			result += "[color=#%s]%s[/color] " % [white_hex, prefix]
		result += "[color=#%s]%s[/color]" % [white_hex, base_name]
		if not suffix.is_empty():
			result += " [color=#%s]%s[/color]" % [green_hex, suffix]
	else:
		# T2: prefix in green, base in rarity color
		if not prefix.is_empty():
			result += "[color=#%s]%s[/color] " % [green_hex, prefix]
		result += "[color=#%s]%s[/color]" % [rarity_hex, base_name]
	result += "[/center]"
	return result

func _format_compound_name(prefix: String, base_name: String, base_rarity_color: Color) -> String:
	## Format compound name with prefix in green and base name in rarity color (T2 abilities)
	return _format_compound_name_full(prefix, base_name, "", base_rarity_color, false)

func _get_base_ability_rarity_color(ability: ActiveAbilityData) -> Color:
	## Get the rarity color of the root T1 base ability (for the base_name portion)
	## e.g., for "Fiery Slam of Doom", get the rarity color of "Slam" (the T1 base)
	if ability.base_ability_id.is_empty():
		return _get_rarity_color(ability)

	var base_ability = ActiveAbilityDatabase.get_ability(ability.base_ability_id)
	if base_ability:
		return ActiveAbilityData.get_rarity_color(base_ability.rarity)
	return _get_rarity_color(ability)

func _populate_stat_changes(container: VBoxContainer, ability: ActiveAbilityData) -> void:
	## Populate the stats container with stat change indicators
	if ability.prerequisite_id.is_empty():
		return

	var prereq = ActiveAbilityDatabase.get_ability(ability.prerequisite_id)
	if not prereq:
		return

	# Clear existing children
	for child in container.get_children():
		child.queue_free()

	# Collect stat changes
	var changes: Array[String] = []

	# Damage comparison
	if ability.base_damage > 0 and prereq.base_damage > 0:
		var dmg_diff = ability.base_damage - prereq.base_damage
		var dmg_percent = (dmg_diff / prereq.base_damage) * 100 if prereq.base_damage > 0 else 0
		if abs(dmg_percent) >= 5:
			var sign = "+" if dmg_percent > 0 else ""
			var color = "33ee55" if dmg_percent > 0 else "ff5555"
			changes.append("[color=#%s]%s%.0f%% Damage[/color]" % [color, sign, dmg_percent])
	elif ability.base_damage > 0 and prereq.base_damage == 0:
		changes.append("[color=#33ee55]+%.0f Damage[/color]" % ability.base_damage)

	# Cooldown comparison (lower is better)
	if ability.cooldown != prereq.cooldown:
		var cd_diff = ability.cooldown - prereq.cooldown
		var sign = "+" if cd_diff > 0 else ""
		var color = "ff5555" if cd_diff > 0 else "33ee55"  # Lower cooldown is better
		changes.append("[color=#%s]%s%.1fs Cooldown[/color]" % [color, sign, cd_diff])

	# Range comparison
	if ability.range_distance > 0 and prereq.range_distance > 0:
		var range_diff = ability.range_distance - prereq.range_distance
		var range_percent = (range_diff / prereq.range_distance) * 100 if prereq.range_distance > 0 else 0
		if abs(range_percent) >= 10:
			var sign = "+" if range_percent > 0 else ""
			var color = "33ee55" if range_percent > 0 else "ff5555"
			changes.append("[color=#%s]%s%.0f%% Range[/color]" % [color, sign, range_percent])

	# AoE comparison
	if ability.radius > 0 and prereq.radius > 0:
		var aoe_diff = ability.radius - prereq.radius
		var aoe_percent = (aoe_diff / prereq.radius) * 100 if prereq.radius > 0 else 0
		if abs(aoe_percent) >= 10:
			var sign = "+" if aoe_percent > 0 else ""
			var color = "33ee55" if aoe_percent > 0 else "ff5555"
			changes.append("[color=#%s]%s%.0f%% AoE[/color]" % [color, sign, aoe_percent])
	elif ability.radius > 0 and prereq.radius == 0:
		changes.append("[color=#33ee55]+AoE[/color]")

	# Duration comparison
	if ability.duration > 0 and prereq.duration > 0:
		var dur_diff = ability.duration - prereq.duration
		if abs(dur_diff) >= 0.5:
			var sign = "+" if dur_diff > 0 else ""
			var color = "33ee55" if dur_diff > 0 else "ff5555"
			changes.append("[color=#%s]%s%.1fs Duration[/color]" % [color, sign, dur_diff])
	elif ability.duration > 0 and prereq.duration == 0:
		changes.append("[color=#33ee55]+%.1fs Duration[/color]" % ability.duration)

	# Stun comparison
	if ability.stun_duration > 0 and prereq.stun_duration == 0:
		changes.append("[color=#33ee55]+%.1fs Stun[/color]" % ability.stun_duration)
	elif ability.stun_duration > prereq.stun_duration:
		var stun_diff = ability.stun_duration - prereq.stun_duration
		changes.append("[color=#33ee55]+%.1fs Stun[/color]" % stun_diff)

	# Slow comparison
	if ability.slow_percent > 0 and prereq.slow_percent == 0:
		changes.append("[color=#33ee55]+%.0f%% Slow[/color]" % (ability.slow_percent * 100))

	# Knockback comparison
	if ability.knockback_force > 0 and prereq.knockback_force == 0:
		changes.append("[color=#33ee55]+Knockback[/color]")

	# Create labels for each change (show max 3 to fit in card)
	var max_changes = 3
	for i in range(min(changes.size(), max_changes)):
		var change_label = RichTextLabel.new()
		change_label.bbcode_enabled = true
		change_label.fit_content = true
		change_label.scroll_active = false
		change_label.add_theme_font_size_override("normal_font_size", 12)
		if pixel_font:
			change_label.add_theme_font_override("normal_font", pixel_font)
		change_label.text = "[center]%s[/center]" % changes[i]
		container.add_child(change_label)

func _populate_tier_diamonds(container: HBoxContainer, ability: ActiveAbilityData) -> void:
	## Create 3 tier diamonds showing progression:
	## T2 upgrade: first filled, second flashing
	## T3 upgrade: first and second filled, third flashing
	var is_t3 = ability.is_signature()
	var current_tier = 3 if is_t3 else 2

	for i in range(3):
		var tier_num = i + 1
		var diamond = _create_tier_diamond(tier_num, current_tier)
		container.add_child(diamond)

func _create_tier_diamond(tier_num: int, current_tier: int) -> Control:
	## Create a single diamond indicator
	## tier_num: 1, 2, or 3
	## current_tier: the tier being upgraded TO (2 for T2 upgrade, 3 for T3 upgrade)
	var container = Control.new()
	container.custom_minimum_size = Vector2(16, 16)

	var diamond = ColorRect.new()
	diamond.custom_minimum_size = Vector2(12, 12)
	diamond.size = Vector2(12, 12)
	diamond.position = Vector2(2, 2)
	diamond.rotation = PI / 4  # 45 degrees to make it a diamond
	diamond.pivot_offset = Vector2(6, 6)

	var green = Color(0.2, 0.93, 0.35)  # Bright green
	var yellow = Color(1.0, 0.85, 0.2)  # Yellow for flashing
	var dark = Color(0.2, 0.2, 0.2)     # Dark/empty

	if tier_num < current_tier:
		# Filled diamond (previous tiers)
		diamond.color = green
	elif tier_num == current_tier:
		# Flashing diamond (current upgrade tier) - yellow
		diamond.color = yellow
		diamond.name = "FlashingDiamond"
		# Add flashing animation
		var tween = container.create_tween()
		tween.set_loops()
		tween.tween_property(diamond, "color:a", 0.3, 0.4)
		tween.tween_property(diamond, "color:a", 1.0, 0.4)
	else:
		# Empty diamond (future tiers)
		diamond.color = dark

	container.add_child(diamond)
	return container
