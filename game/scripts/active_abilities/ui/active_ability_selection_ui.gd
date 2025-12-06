extends CanvasLayer
class_name ActiveAbilitySelectionUI

signal ability_selected(ability: ActiveAbilityData)

# Inner class for drawing circular icons
class IconCircleDrawer extends Control:
	var icon_size: int = 80
	var border_width: int = 3
	var border_color: Color = Color(0.5, 0.5, 0.5)
	var bg_color: Color = Color(0.1, 0.1, 0.15)
	var icon_texture: Texture2D = null
	var fallback_letter: String = ""
	var pixel_font: Font = null
	var show_skillshot_indicator: bool = false

	func _draw() -> void:
		var center = Vector2(icon_size, icon_size) / 2
		var radius = icon_size / 2.0 - border_width

		# Draw outer border circle
		draw_circle(center, radius + border_width, border_color)

		# Draw inner background circle
		draw_circle(center, radius, bg_color)

		# Draw icon clipped to circle
		if icon_texture:
			_draw_texture_clipped_to_circle(icon_texture, center, radius, Color.WHITE)
		elif fallback_letter != "":
			# Draw fallback letter
			var font_size = int(icon_size * 0.4)
			var font = pixel_font if pixel_font else ThemeDB.fallback_font
			var text_size = font.get_string_size(fallback_letter, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			var text_pos = center - text_size / 2 + Vector2(0, text_size.y * 0.35)
			draw_string(font, text_pos, fallback_letter, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

		# Draw skillshot indicator if ability supports it
		if show_skillshot_indicator:
			_draw_skillshot_indicator(center, radius)

	func _draw_skillshot_indicator(center: Vector2, radius: float) -> void:
		# Subtle scope/reticle - 8 lines radiating from edge toward center
		var indicator_color = Color(1.0, 1.0, 1.0, 0.6)
		var outline_color = Color(0.0, 0.0, 0.0, 0.4)
		var line_length = radius * 0.25  # Base length for cardinal lines

		# 8 directions - 4 cardinal + 4 diagonal
		var angles = [
			0,           # Right (3pm)
			PI * 0.25,   # Bottom-right diagonal
			PI * 0.5,    # Bottom (6pm)
			PI * 0.75,   # Bottom-left diagonal
			PI,          # Left (9pm)
			PI * 1.25,   # Top-left diagonal
			PI * 1.5,    # Top (12pm)
			PI * 1.75    # Top-right diagonal
		]

		for i in range(angles.size()):
			var angle = angles[i]
			var dir = Vector2(cos(angle), sin(angle))
			var is_cardinal = (i % 2 == 0)  # 0, 2, 4, 6 are cardinal (12pm, 3pm, 6pm, 9pm)

			# Cardinal lines: thicker and longer; Diagonal lines: thinner and shorter
			var this_length = line_length if is_cardinal else line_length * 0.4
			var line_width = 3.0 if is_cardinal else 1.5
			var outline_width = 5.0 if is_cardinal else 3.0

			var start = center + dir * radius  # Touch the edge
			var end = center + dir * (radius - this_length)

			# Draw outline then line
			draw_line(start, end, outline_color, outline_width)
			draw_line(start, end, indicator_color, line_width)

	func _draw_texture_clipped_to_circle(tex: Texture2D, center: Vector2, radius: float, modulate: Color) -> void:
		var segments = 64
		var points = PackedVector2Array()
		var uvs = PackedVector2Array()
		var colors = PackedColorArray()

		var tex_size = tex.get_size()
		var scale_factor = (radius * 2) / min(tex_size.x, tex_size.y)
		var scaled_size = tex_size * scale_factor

		# UV inset to avoid sampling edge pixels (fixes white border artifacts)
		var uv_inset = 0.92

		for i in range(segments):
			var angle = (float(i) / segments) * TAU - PI / 2
			var point = center + Vector2(cos(angle), sin(angle)) * radius
			points.append(point)

			var offset = point - center
			# Scale UV coordinates inward to avoid edge sampling artifacts
			var uv = Vector2(0.5, 0.5) + (offset / scaled_size) * uv_inset
			uvs.append(uv)
			colors.append(modulate)

		if points.size() >= 3:
			draw_polygon(points, colors, uvs, tex)

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
var desc_font: Font = null
var desc_bold_font: Font = null
var rarity_particle_shader: Shader = null
var particle_containers: Array[Control] = []

func _ready() -> void:
	visible = false
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("active_ability_selection_ui")

	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load Quicksand fonts for descriptions
	if ResourceLoader.exists("res://assets/fonts/Quicksand/Quicksand-Medium.ttf"):
		desc_font = load("res://assets/fonts/Quicksand/Quicksand-Medium.ttf")
	if ResourceLoader.exists("res://assets/fonts/Quicksand/Quicksand-Bold.ttf"):
		desc_bold_font = load("res://assets/fonts/Quicksand/Quicksand-Bold.ttf")

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

	# Style the panel with dark semi-transparent background (matches passive selection)
	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.96)
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
	title_label.text = "CHOOSE ACTIVE ABILITY"
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.add_theme_font_size_override("font_size", 34)
	title_label.add_theme_color_override("font_color", Color(1.0, 0.9, 0.3))
	if pixel_font:
		title_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(title_label)

	# Subtitle container - hidden for active ability selection
	var subtitle_container = HBoxContainer.new()
	subtitle_container.name = "SubtitleContainer"
	subtitle_container.alignment = BoxContainer.ALIGNMENT_CENTER
	subtitle_container.visible = false  # Hidden

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

	# Choices container - centered horizontally (spacing matches passive selection)
	choices_container = HBoxContainer.new()
	choices_container.name = "ChoicesContainer"
	choices_container.add_theme_constant_override("separation", 60)
	choices_container.alignment = BoxContainer.ALIGNMENT_CENTER
	choices_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	vbox.add_child(choices_container)

	# Spacer before reroll button
	var reroll_spacer = Control.new()
	reroll_spacer.custom_minimum_size = Vector2(0, 60)
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

func _set_mouse_filter_recursive(control: Control, filter: Control.MouseFilter) -> void:
	## Recursively set mouse_filter on control and all its children
	## This ensures the entire card is clickable
	control.mouse_filter = filter
	for child in control.get_children():
		if child is Control:
			_set_mouse_filter_recursive(child, filter)

func _process(_delta: float) -> void:
	# SLOT MACHINE DISABLED - using fly-in animation instead
	# To re-enable: uncomment below and set is_rolling = true in show_choices
	pass
	#if not is_rolling:
		#return
	#
	#roll_timer += delta
	#
	## Update each slot
	#for i in range(ability_buttons.size()):
		#if slots_settled[i]:
			#continue
		#
		#if roll_timer >= slot_settle_times[i]:
			#slots_settled[i] = true
			#_update_card_content(ability_buttons[i], current_choices[i], true)  # true = final reveal
			#if SoundManager and SoundManager.has_method("play_ding"):
				#SoundManager.play_ding()
		#else:
			#roll_tick_timers[i] += delta
			#var progress = roll_timer / slot_settle_times[i]
			#var current_speed = current_roll_speed * (1.0 + progress * 3.0)
			#
			#if roll_tick_timers[i] >= current_speed:
				#roll_tick_timers[i] = 0.0
				#if all_abilities_pool.size() > 0:
					#var random_ability = all_abilities_pool[randi() % all_abilities_pool.size()]
					#_update_card_content(ability_buttons[i], random_ability)
	#
	## Check if all slots settled
	#if slots_settled.all(func(s): return s):
		#is_rolling = false
		#for button in ability_buttons:
			#button.disabled = false
		## Enable reroll button if not used yet
		#if reroll_button and not reroll_used:
			#reroll_button.disabled = false

func show_choices(abilities: Array[ActiveAbilityData], level: int) -> void:
	current_choices = abilities
	current_level = level

	# Reset reroll state for this selection
	reroll_used = false
	if reroll_button:
		reroll_button.disabled = false  # Enable immediately (no slot machine)
		reroll_button.text = "Reroll"

	# Get pool for slot machine effect (kept for reroll functionality)
	var is_melee = CharacterManager.get_selected_character().attack_type == CharacterData.AttackType.MELEE if CharacterManager else false
	all_abilities_pool = ActiveAbilityDatabase.get_abilities_for_class(is_melee)
	if all_abilities_pool.is_empty():
		all_abilities_pool = abilities

	# Use consistent title for all levels
	title_label.text = "CHOOSE ACTIVE ABILITY"

	# Clear previous buttons and particle containers
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()
	particle_containers.clear()

	# SLOT MACHINE DISABLED - commented out for fly-in animation
	# To re-enable: uncomment below and uncomment _process slot machine code
	#is_rolling = true
	#roll_timer = 0.0
	#slots_settled = []
	#roll_tick_timers = []
	#slot_settle_times = []
	#for i in abilities.size():
		#slots_settled.append(false)
		#roll_tick_timers.append(0.0)
		#slot_settle_times.append(0.6 + i * 0.2)

	# Create cards with FINAL abilities (no slot machine)
	for i in abilities.size():
		var card = _create_ability_card(abilities[i], i)
		card.disabled = false  # Enable immediately
		choices_container.add_child(card)
		ability_buttons.append(card)
		# Show particle container immediately since no rolling
		var particle_container = card.get_node_or_null("ParticleContainer")
		if particle_container:
			particle_container.visible = true

	visible = true
	get_tree().paused = true

	_animate_entrance()

func _create_ability_card(ability: ActiveAbilityData, index: int) -> Button:
	var button = Button.new()
	button.custom_minimum_size = Vector2(240, 360)  # Rectangle area only
	button.focus_mode = Control.FOCUS_ALL
	button.clip_contents = false

	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)

	# Spacer at top (for icon that's half outside)
	var top_spacer = Control.new()
	top_spacer.custom_minimum_size = Vector2(0, 48)  # Space for icon overlap
	vbox.add_child(top_spacer)

	# Spacer after icon position (above name)
	var icon_spacer = Control.new()
	icon_spacer.custom_minimum_size = Vector2(0, 0)
	vbox.add_child(icon_spacer)

	# Ability name (below icon) - white for all active abilities
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = ability.name
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	name_label.add_theme_font_size_override("font_size", 18)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	name_label.custom_minimum_size = Vector2(0, 44)  # Min height for 2 lines
	if pixel_font:
		name_label.add_theme_font_override("font", pixel_font)
	vbox.add_child(name_label)

	# Spacer below name
	var name_spacer = Control.new()
	name_spacer.custom_minimum_size = Vector2(0, 40)  # 40px margin below title
	vbox.add_child(name_spacer)

	# Description (with padding via MarginContainer)
	var desc_margin = MarginContainer.new()
	desc_margin.add_theme_constant_override("margin_left", 10)
	desc_margin.add_theme_constant_override("margin_right", 10)
	desc_margin.size_flags_vertical = Control.SIZE_EXPAND_FILL

	var desc_label = RichTextLabel.new()
	desc_label.name = "DescLabel"
	desc_label.bbcode_enabled = true
	desc_label.text = DescriptionFormatter.format(ability.description)
	desc_label.fit_content = true
	desc_label.scroll_active = false
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc_label.add_theme_font_size_override("normal_font_size", 16)
	desc_label.add_theme_font_size_override("bold_font_size", 16)
	desc_label.add_theme_color_override("default_color", Color(0.95, 0.95, 0.95))
	if desc_font:
		desc_label.add_theme_font_override("normal_font", desc_font)
	if desc_bold_font:
		desc_label.add_theme_font_override("bold_font", desc_bold_font)
	desc_margin.add_child(desc_label)
	vbox.add_child(desc_margin)

	# Upgradeable indicator - shows for base abilities that have upgrade paths (above cooldown)
	var upgradeable_label = Label.new()
	upgradeable_label.name = "UpgradeableLabel"
	upgradeable_label.text = "Upgradeable"
	upgradeable_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	upgradeable_label.add_theme_font_size_override("font_size", 14)
	upgradeable_label.add_theme_color_override("font_color", Color(0.2, 0.9, 0.3))  # Green
	if desc_font:
		upgradeable_label.add_theme_font_override("font", desc_font)
	# Only show for base abilities that are part of a tree
	upgradeable_label.visible = not ability.is_upgrade() and AbilityTreeRegistry.is_ability_in_tree(ability.id)
	vbox.add_child(upgradeable_label)

	# Cooldown info
	var cooldown_label = Label.new()
	cooldown_label.name = "CooldownLabel"
	cooldown_label.text = str(int(ability.cooldown)) + "s cooldown"
	cooldown_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	cooldown_label.add_theme_font_size_override("font_size", 14)
	cooldown_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if desc_font:
		cooldown_label.add_theme_font_override("font", desc_font)
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

	# Make all children pass input to button
	_set_mouse_filter_recursive(margin, Control.MOUSE_FILTER_PASS)

	# Icon circle pinned to top (half above, half inside card) - replaces rarity tag
	var icon_container = CenterContainer.new()
	icon_container.name = "IconContainer"
	icon_container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	icon_container.anchor_left = 0
	icon_container.anchor_right = 1
	icon_container.anchor_top = 0
	icon_container.anchor_bottom = 0
	icon_container.offset_top = -40  # Half outside the card (icon is 80px, so -40 puts half outside)
	icon_container.offset_bottom = 40
	var icon_circle = _create_icon_circle(ability)
	icon_circle.name = "IconCircle"
	icon_container.add_child(icon_circle)
	button.add_child(icon_container)
	_set_mouse_filter_recursive(icon_container, Control.MOUSE_FILTER_PASS)

	# Tier banner for upgrades (UPGRADE or SIGNATURE)
	if ability.is_upgrade():
		var tier_banner = _create_tier_banner(ability)
		tier_banner.name = "TierBanner"
		button.add_child(tier_banner)
		_set_mouse_filter_recursive(tier_banner, Control.MOUSE_FILTER_PASS)

	# Prerequisite indicator showing what ability this upgrades from
	if ability.is_upgrade():
		var prereq_indicator = _create_prerequisite_indicator(ability)
		prereq_indicator.name = "PrereqIndicator"
		button.add_child(prereq_indicator)
		_set_mouse_filter_recursive(prereq_indicator, Control.MOUSE_FILTER_PASS)

	# Add particle effect container (starts hidden, shown after card settles)
	var particle_container = _create_particle_container(ability.rarity)
	particle_container.name = "ParticleContainer"
	particle_container.visible = false  # Hide until card is revealed
	button.add_child(particle_container)
	particle_containers.append(particle_container)

	_style_button(button, ability.rarity, ability)

	# Add banner point (triangle) at bottom - pass index for click handling
	var banner_point = _create_banner_point(index)
	banner_point.name = "BannerPoint"
	button.add_child(banner_point)

	# Connect hover signals for the triangle
	button.mouse_entered.connect(_on_card_hover_entered.bind(button))
	button.mouse_exited.connect(_on_card_hover_exited.bind(button))

	button.pressed.connect(_on_ability_selected.bind(index))

	return button

func _create_rarity_tag(_rarity: ActiveAbilityData.Rarity) -> CenterContainer:
	# Use CenterContainer to properly center the tag
	# All active ability cards show "Active" with green color
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_TOP_WIDE)
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 0
	center.anchor_bottom = 0
	center.offset_top = -12  # Half above the card
	center.offset_bottom = 12

	var tag = PanelContainer.new()

	# Style the tag - green for all active abilities
	var tag_style = StyleBoxFlat.new()
	tag_style.bg_color = Color(0.2, 0.9, 0.3)  # Green
	tag_style.set_corner_radius_all(4)
	tag_style.content_margin_left = 10
	tag_style.content_margin_right = 10
	tag_style.content_margin_top = 4
	tag_style.content_margin_bottom = 4
	tag.add_theme_stylebox_override("panel", tag_style)

	# Label shows "Active" for all
	var label = Label.new()
	label.name = "RarityLabel"
	label.text = "Active"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 12)
	label.add_theme_color_override("font_color", Color(0.1, 0.1, 0.1))  # Dark text
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	tag.add_child(label)

	center.add_child(tag)
	return center

func _create_tier_banner(ability: ActiveAbilityData) -> CenterContainer:
	"""Create a banner showing UPGRADE or SIGNATURE for tiered abilities."""
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	center.anchor_left = 0
	center.anchor_right = 1
	center.anchor_top = 1
	center.anchor_bottom = 1
	center.offset_top = -8
	center.offset_bottom = 16  # Slightly below the card

	var banner = PanelContainer.new()

	# Determine banner style based on tier
	var banner_color: Color
	var banner_text: String
	if ability.is_signature():
		banner_color = Color(1.0, 0.85, 0.3)  # Gold
		banner_text = "SIGNATURE"
	else:
		banner_color = Color(0.2, 0.9, 0.3)  # Green
		banner_text = "UPGRADE"

	var banner_style = StyleBoxFlat.new()
	banner_style.bg_color = banner_color
	banner_style.set_corner_radius_all(4)
	banner_style.content_margin_left = 12
	banner_style.content_margin_right = 12
	banner_style.content_margin_top = 3
	banner_style.content_margin_bottom = 3
	banner.add_theme_stylebox_override("panel", banner_style)

	var label = Label.new()
	label.name = "TierLabel"
	label.text = banner_text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 11)
	label.add_theme_color_override("font_color", Color.BLACK)
	if pixel_font:
		label.add_theme_font_override("font", pixel_font)
	banner.add_child(label)

	center.add_child(banner)
	return center

func _create_prerequisite_indicator(ability: ActiveAbilityData) -> Control:
	"""Create an indicator showing what ability this upgrades from."""
	var container = HBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_TOP_WIDE)
	container.anchor_left = 0
	container.anchor_right = 1
	container.anchor_top = 0
	container.anchor_bottom = 0
	container.offset_top = 24  # Below the rarity tag
	container.offset_bottom = 44
	container.alignment = BoxContainer.ALIGNMENT_CENTER

	# Get prerequisite ability name
	var prereq_id = ability.get_prerequisite_id()
	var prereq_ability = ActiveAbilityDatabase.get_ability_by_id(prereq_id)
	var prereq_name = prereq_ability.name if prereq_ability else prereq_id

	# Arrow icon (→)
	var arrow_label = Label.new()
	arrow_label.text = "↑"
	arrow_label.add_theme_font_size_override("font_size", 14)
	arrow_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))
	if pixel_font:
		arrow_label.add_theme_font_override("font", pixel_font)
	container.add_child(arrow_label)

	# Small text showing prerequisite
	var prereq_label = Label.new()
	prereq_label.name = "PrereqLabel"
	prereq_label.text = " " + prereq_name
	prereq_label.add_theme_font_size_override("font_size", 10)
	prereq_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.6))
	if pixel_font:
		prereq_label.add_theme_font_override("font", pixel_font)
	container.add_child(prereq_label)

	return container

func _style_button(button: Button, _rarity: ActiveAbilityData.Rarity, _ability: ActiveAbilityData = null) -> void:
	var style = StyleBoxFlat.new()

	# All active ability cards use green styling
	style.bg_color = Color(0.08, 0.18, 0.1, 0.98)  # Dark green background
	style.border_color = Color(0.2, 0.9, 0.3)  # Green border

	style.set_border_width_all(4)
	# Banner shape: rounded top corners, flat bottom (triangle covers the bottom)
	style.corner_radius_top_left = 12
	style.corner_radius_top_right = 12
	style.corner_radius_bottom_left = 0
	style.corner_radius_bottom_right = 0
	# Remove bottom border since triangle continues the shape
	style.border_width_bottom = 0

	button.add_theme_stylebox_override("normal", style)

	var hover_style = style.duplicate()
	hover_style.bg_color = hover_style.bg_color.lightened(0.1)
	button.add_theme_stylebox_override("hover", hover_style)

	var pressed_style = style.duplicate()
	pressed_style.bg_color = pressed_style.bg_color.darkened(0.1)
	button.add_theme_stylebox_override("pressed", pressed_style)

func _create_banner_point(index: int) -> Control:
	"""Create the triangle point at the bottom of the banner card."""
	## Triangle extends 40px below the button rect
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	container.anchor_top = 1.0
	container.anchor_bottom = 1.0
	container.offset_top = 0
	container.offset_bottom = 40  # Extend below button
	# Make triangle clickable - trigger button press on click
	container.mouse_filter = Control.MOUSE_FILTER_STOP
	container.gui_input.connect(func(event):
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_ability_selected(index)
		elif event is InputEventScreenTouch and event.pressed:
			_on_ability_selected(index)
	)

	# Green colors for active ability cards
	var bg_color = Color(0.08, 0.18, 0.1, 0.98)
	var border_color = Color(0.2, 0.9, 0.3)

	# Triangle polygon (pointing down)
	var triangle = Polygon2D.new()
	triangle.name = "TriangleFill"
	# Points: top-left, top-right, bottom-center
	triangle.polygon = PackedVector2Array([
		Vector2(0, 0),      # Top-left
		Vector2(240, 0),    # Top-right (card width)
		Vector2(120, 40)    # Bottom-center (point)
	])
	triangle.color = bg_color
	container.add_child(triangle)

	# Border lines for the triangle
	var left_border = Line2D.new()
	left_border.name = "LeftBorder"
	left_border.points = PackedVector2Array([
		Vector2(0, 0),
		Vector2(120, 40)
	])
	left_border.width = 4
	left_border.default_color = border_color
	container.add_child(left_border)

	var right_border = Line2D.new()
	right_border.name = "RightBorder"
	right_border.points = PackedVector2Array([
		Vector2(240, 0),
		Vector2(120, 40)
	])
	right_border.width = 4
	right_border.default_color = border_color
	container.add_child(right_border)

	return container

func _on_card_hover_entered(button: Button) -> void:
	"""Handle hover for the card including the banner point."""
	var banner_point = button.get_node_or_null("BannerPoint")
	if banner_point:
		var triangle = banner_point.get_node_or_null("TriangleFill") as Polygon2D
		if triangle:
			# Lighten the triangle to match hover state
			triangle.color = Color(0.08, 0.18, 0.1, 0.98).lightened(0.1)

func _on_card_hover_exited(button: Button) -> void:
	"""Handle hover exit for the card including the banner point."""
	var banner_point = button.get_node_or_null("BannerPoint")
	if banner_point:
		var triangle = banner_point.get_node_or_null("TriangleFill") as Polygon2D
		if triangle:
			# Restore original color
			triangle.color = Color(0.08, 0.18, 0.1, 0.98)

func _create_separator_style(rarity: ActiveAbilityData.Rarity) -> StyleBoxLine:
	var style = StyleBoxLine.new()
	var color = ActiveAbilityData.get_rarity_color(rarity)
	color.a = 0.4  # More transparent
	style.color = color
	style.thickness = 1
	return style

func _create_icon_circle(ability: ActiveAbilityData) -> Control:
	"""Create a circular icon display for the ability, similar to the ability button."""
	var ICON_SIZE := 80
	var BORDER_WIDTH := 3

	var container = Control.new()
	container.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	container.size = Vector2(ICON_SIZE, ICON_SIZE)

	# We'll use a custom drawing node for the circle
	var icon_drawer = IconCircleDrawer.new()
	icon_drawer.icon_size = ICON_SIZE
	icon_drawer.border_width = BORDER_WIDTH
	icon_drawer.border_color = Color(0.2, 0.9, 0.3)  # Green border for all active abilities
	icon_drawer.bg_color = Color(0.1, 0.1, 0.15, 1.0)
	icon_drawer.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	icon_drawer.size = Vector2(ICON_SIZE, ICON_SIZE)

	# Load the icon texture
	var icon_path = "res://assets/icons/abilities/" + ability.id + ".png"
	if ResourceLoader.exists(icon_path):
		icon_drawer.icon_texture = load(icon_path)
	else:
		# Fallback letter
		icon_drawer.fallback_letter = ability.name.substr(0, 1).to_upper()
		icon_drawer.pixel_font = pixel_font

	# Show skillshot indicator if ability supports aiming
	icon_drawer.show_skillshot_indicator = ability.supports_skillshot()

	container.add_child(icon_drawer)
	return container

func _update_card_content(button: Button, ability: ActiveAbilityData, is_final_reveal: bool = false) -> void:
	var margin = button.get_child(0) as MarginContainer
	if not margin:
		return
	var vbox = margin.get_child(0) as VBoxContainer
	if not vbox:
		return

	# Update icon circle (now positioned on button, not in vbox)
	var icon_container = button.get_node_or_null("IconContainer") as CenterContainer
	if icon_container:
		var icon_circle = icon_container.get_node_or_null("IconCircle")
		if icon_circle and icon_circle.get_child_count() > 0:
			var icon_drawer = icon_circle.get_child(0) as IconCircleDrawer
			if icon_drawer:
				icon_drawer.border_color = Color(0.2, 0.9, 0.3)  # Green border for all active abilities
				var icon_path = "res://assets/icons/abilities/" + ability.id + ".png"
				if ResourceLoader.exists(icon_path):
					icon_drawer.icon_texture = load(icon_path)
					icon_drawer.fallback_letter = ""
				else:
					icon_drawer.icon_texture = null
					icon_drawer.fallback_letter = ability.name.substr(0, 1).to_upper()
				icon_drawer.show_skillshot_indicator = ability.supports_skillshot()
				icon_drawer.queue_redraw()

	# Children: 0=top_spacer, 1=icon_spacer, 2=name, 3=name_spacer, 4=desc_margin, 5=upgradeable, 6=cooldown, 7=bottom_spacer
	# Update name (child 2) - white for all active abilities
	var name_label = vbox.get_child(2) as Label
	if name_label:
		name_label.text = ability.name
		name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0))  # White

	# Update description (child 4 is MarginContainer, desc_label is inside)
	var desc_margin = vbox.get_child(4) as MarginContainer
	if desc_margin and desc_margin.get_child_count() > 0:
		var desc_label = desc_margin.get_child(0) as RichTextLabel
		if desc_label:
			desc_label.text = DescriptionFormatter.format(ability.description)

	# Update upgradeable indicator (child 5) - only show on final reveal for base abilities in trees
	var upgradeable_label = vbox.get_child(5) as Label
	if upgradeable_label:
		if is_final_reveal:
			upgradeable_label.visible = not ability.is_upgrade() and AbilityTreeRegistry.is_ability_in_tree(ability.id)
		else:
			upgradeable_label.visible = false

	# Update cooldown (child 6)
	var cooldown_label = vbox.get_child(6) as Label
	if cooldown_label:
		cooldown_label.text = str(int(ability.cooldown)) + "s cooldown"

	# Update particle container - only show on final reveal
	var particle_container = button.get_node_or_null("ParticleContainer") as Control
	if particle_container:
		if is_final_reveal:
			_update_particle_container(particle_container, ability.rarity)
		else:
			particle_container.visible = false

	# Update tier banner visibility and content
	var tier_banner = button.get_node_or_null("TierBanner") as CenterContainer
	if is_final_reveal and ability.is_upgrade():
		if not tier_banner:
			# Create tier banner if it doesn't exist
			tier_banner = _create_tier_banner(ability)
			tier_banner.name = "TierBanner"
			button.add_child(tier_banner)
		else:
			# Update existing banner
			tier_banner.visible = true
			_update_tier_banner(tier_banner, ability)
	elif tier_banner:
		tier_banner.visible = false

	# Update prerequisite indicator visibility and content
	var prereq_indicator = button.get_node_or_null("PrereqIndicator") as Control
	if is_final_reveal and ability.is_upgrade():
		if not prereq_indicator:
			# Create indicator if it doesn't exist
			prereq_indicator = _create_prerequisite_indicator(ability)
			prereq_indicator.name = "PrereqIndicator"
			button.add_child(prereq_indicator)
		else:
			# Update existing indicator
			prereq_indicator.visible = true
			_update_prerequisite_indicator(prereq_indicator, ability)
	elif prereq_indicator:
		prereq_indicator.visible = false

	_style_button(button, ability.rarity, ability if is_final_reveal else null)

func _update_tier_banner(banner: CenterContainer, ability: ActiveAbilityData) -> void:
	"""Update existing tier banner for a new ability."""
	var panel = banner.get_child(0) as PanelContainer
	if not panel:
		return

	var banner_color: Color
	var banner_text: String
	if ability.is_signature():
		banner_color = Color(1.0, 0.85, 0.3)  # Gold
		banner_text = "SIGNATURE"
	else:
		banner_color = Color(0.2, 0.9, 0.3)  # Green
		banner_text = "UPGRADE"

	var banner_style = panel.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	banner_style.bg_color = banner_color
	panel.add_theme_stylebox_override("panel", banner_style)

	var label = panel.get_child(0) as Label
	if label:
		label.text = banner_text

func _update_prerequisite_indicator(indicator: Control, ability: ActiveAbilityData) -> void:
	"""Update existing prerequisite indicator for a new ability."""
	var prereq_label = indicator.get_node_or_null("PrereqLabel") as Label
	if prereq_label:
		var prereq_id = ability.get_prerequisite_id()
		var prereq_ability = ActiveAbilityDatabase.get_ability_by_id(prereq_id)
		var prereq_name = prereq_ability.name if prereq_ability else prereq_id
		prereq_label.text = " " + prereq_name

func _on_ability_selected(index: int) -> void:
	if is_rolling:
		return

	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	if index >= 0 and index < current_choices.size():
		var ability = current_choices[index]
		var selected_button = ability_buttons[index]

		# Disable all buttons to prevent double selection
		for button in ability_buttons:
			button.disabled = true

		# Animate the selected card with a pulse
		_animate_card_selected(selected_button, func():
			# Acquire the ability after animation
			ActiveAbilityManager.acquire_ability(ability)

			# Play sound
			if SoundManager and SoundManager.has_method("play_buff"):
				SoundManager.play_buff()

			emit_signal("ability_selected", ability)
			hide_selection()
		)

func _animate_card_selected(button: Button, on_complete: Callable) -> void:
	"""Animate the selected card growing bigger."""
	button.pivot_offset = button.size / 2

	var tween = create_tween()
	tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Grow bigger
	tween.tween_property(button, "scale", Vector2(1.15, 1.15), 0.15).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Brief hold then complete
	tween.tween_interval(0.1)

	# Call completion callback
	tween.tween_callback(on_complete)

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

	# Clear old cards and recreate with new abilities (fly-in animation)
	for button in ability_buttons:
		button.queue_free()
	ability_buttons.clear()
	particle_containers.clear()

	# Create new cards with final abilities
	for i in current_choices.size():
		var card = _create_ability_card(current_choices[i], i)
		card.disabled = false
		choices_container.add_child(card)
		ability_buttons.append(card)
		# Show particle container immediately
		var particle_container = card.get_node_or_null("ParticleContainer")
		if particle_container:
			particle_container.visible = true

	# Animate the new cards flying in
	_animate_reroll_entrance()

	# SLOT MACHINE DISABLED - old reroll logic commented out
	#is_rolling = true
	#roll_timer = 0.0
	#slots_settled = []
	#roll_tick_timers = []
	#slot_settle_times = []
	#for i in current_choices.size():
		#slots_settled.append(false)
		#roll_tick_timers.append(0.0)
		#slot_settle_times.append(0.6 + i * 0.2)
	#for button in ability_buttons:
		#button.disabled = true

func _animate_reroll_entrance() -> void:
	"""Animate cards flying in after reroll - from top corners with weight."""
	# Wait for layout to complete before animating
	await get_tree().process_frame
	await get_tree().process_frame
	_animate_cards_fly_in()

func _animate_entrance() -> void:
	# Animate the panel fading in quickly
	if panel:
		panel.modulate.a = 0.0
		var tween = create_tween()
		tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(panel, "modulate:a", 1.0, 0.1).set_ease(Tween.EASE_OUT)

	# Animate title with a bounce
	if title_label:
		title_label.scale = Vector2(1.5, 1.5)
		title_label.pivot_offset = Vector2(title_label.size.x / 2, title_label.size.y / 2)

		var title_tween = create_tween()
		title_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		title_tween.tween_property(title_label, "scale", Vector2(1.0, 1.0), 0.25).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_ELASTIC)

	# Fly-in animation from corners - wait for layout to complete
	await get_tree().process_frame
	await get_tree().process_frame
	_animate_cards_fly_in()

func _animate_cards_fly_in() -> void:
	"""Animate cards flying in sequentially from top-left, top-middle, top-right."""
	# Hide all cards initially so they're not visible before their animation
	for button in ability_buttons:
		button.modulate.a = 0.0
	_animate_card_fly_in_sequential(0)

func _animate_card_fly_in_sequential(index: int) -> void:
	"""Animate a single card flying in, then trigger the next one."""
	if index >= ability_buttons.size():
		return

	# Starting positions: top-left, top-center, top-right
	var start_offsets = [
		Vector2(-300, -400),  # Top-left
		Vector2(0, -450),     # Top-center
		Vector2(300, -400),   # Top-right
	]

	var button = ability_buttons[index]
	button.pivot_offset = button.size / 2
	var original_pos = button.position
	var original_scale = Vector2(1.0, 1.0)

	# Get start offset (cycle through if more than 3 cards)
	var offset = start_offsets[index % start_offsets.size()]
	button.position += offset
	button.scale = Vector2(0.5, 0.5)

	var card_tween = create_tween()
	card_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	# Phase 1: Fly in VERY FAST with acceleration
	card_tween.set_parallel(true)
	card_tween.tween_property(button, "position", original_pos, 0.08).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	card_tween.tween_property(button, "modulate:a", 1.0, 0.04).set_ease(Tween.EASE_OUT)
	card_tween.tween_property(button, "scale", Vector2(1.08, 0.92), 0.08).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)

	# Phase 2: Big impact squash
	card_tween.chain()
	card_tween.set_parallel(true)
	card_tween.tween_property(button, "scale", Vector2(1.2, 0.82), 0.02).set_ease(Tween.EASE_OUT)
	card_tween.tween_callback(_spawn_dust_particles.bind(button))
	card_tween.tween_callback(_play_land_sound)

	# Phase 3: Overshoot bounce
	card_tween.chain()
	card_tween.tween_property(button, "scale", Vector2(0.9, 1.12), 0.03).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

	# Phase 4: Second smaller bounce
	card_tween.chain()
	card_tween.tween_property(button, "scale", Vector2(1.05, 0.96), 0.025).set_ease(Tween.EASE_IN_OUT)

	# Phase 5: Settle to normal
	card_tween.chain()
	card_tween.tween_property(button, "scale", original_scale, 0.04).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Trigger next card after this one lands
	card_tween.chain().tween_callback(_animate_card_fly_in_sequential.bind(index + 1))

func _play_land_sound() -> void:
	"""Play the landing sound at 25% volume."""
	var sound_path = "res://assets/sounds/land.mp3"
	if ResourceLoader.exists(sound_path):
		var player = AudioStreamPlayer.new()
		player.stream = load(sound_path)
		player.volume_db = -12.0  # 25% volume
		player.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		add_child(player)
		player.play()
		player.finished.connect(player.queue_free)

func _spawn_dust_particles(button: Button) -> void:
	"""Spawn dust particles at the bottom of the card on impact."""
	var particle_count = 8
	var card_bottom = button.global_position + Vector2(button.size.x / 2, button.size.y + 20)

	for j in particle_count:
		var dust = ColorRect.new()
		dust.size = Vector2(randf_range(4, 10), randf_range(4, 10))
		dust.color = Color(0.8, 0.75, 0.6, 0.9)  # Dusty tan color
		dust.position = card_bottom + Vector2(randf_range(-60, 60), randf_range(-10, 10))
		dust.pivot_offset = dust.size / 2
		dust.z_index = 10
		add_child(dust)

		# Animate dust particle
		var dust_tween = create_tween()
		dust_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		dust_tween.set_parallel(true)

		# Random outward velocity
		var angle = randf_range(-PI * 0.8, -PI * 0.2)  # Mostly upward arc
		var distance = randf_range(30, 80)
		var target_pos = dust.position + Vector2(cos(angle), sin(angle)) * distance

		dust_tween.tween_property(dust, "position", target_pos, 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		dust_tween.tween_property(dust, "modulate:a", 0.0, 0.4).set_ease(Tween.EASE_IN)
		dust_tween.tween_property(dust, "scale", Vector2(0.3, 0.3), 0.4).set_ease(Tween.EASE_IN)

		# Clean up
		dust_tween.chain().tween_callback(dust.queue_free)

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

# ============================================
# IDLE ANIMATIONS - DISABLED
# ============================================

#func _start_idle_animation(button: Button) -> void:
	#"""Start a subtle idle flutter animation on the card."""
	#if not is_instance_valid(button):
		#return
	#
	## Store original position for reference
	#var original_y = button.position.y
	#button.set_meta("original_y", original_y)
	#button.pivot_offset = button.size / 2
	#
	## Create looping idle animation - gentle floating motion
	#var idle_tween = create_tween()
	#idle_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	#idle_tween.set_loops()
	#
	#var float_amount = 3.0
	#var float_duration = 2.0 + randf() * 0.5  # Slight randomness for organic feel
	#
	#idle_tween.tween_property(button, "position:y", original_y - float_amount, float_duration / 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#idle_tween.tween_property(button, "position:y", original_y + float_amount, float_duration / 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#idle_tween.tween_property(button, "position:y", original_y, float_duration / 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#
	#button.set_meta("idle_tween", idle_tween)
	#
	## Also add subtle rotation sway
	#var sway_tween = create_tween()
	#sway_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	#sway_tween.set_loops()
	#
	#var sway_amount = 0.015  # Subtle rotation in radians
	#var sway_duration = 3.0 + randf() * 0.5
	#
	#sway_tween.tween_property(button, "rotation", sway_amount, sway_duration / 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#sway_tween.tween_property(button, "rotation", -sway_amount, sway_duration).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#sway_tween.tween_property(button, "rotation", 0.0, sway_duration / 2).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	#
	#button.set_meta("sway_tween", sway_tween)

#func _stop_idle_animation(button: Button) -> void:
	#"""Stop the idle animation on a card."""
	#if not is_instance_valid(button):
		#return
	#
	## Kill any running idle tweens
	#if button.has_meta("idle_tween"):
		#var idle_tween = button.get_meta("idle_tween") as Tween
		#if idle_tween and idle_tween.is_valid():
			#idle_tween.kill()
		#button.remove_meta("idle_tween")
	#
	#if button.has_meta("sway_tween"):
		#var sway_tween = button.get_meta("sway_tween") as Tween
		#if sway_tween and sway_tween.is_valid():
			#sway_tween.kill()
		#button.remove_meta("sway_tween")
	#
	## Reset position and rotation
	#if button.has_meta("original_y"):
		#button.position.y = button.get_meta("original_y")
	#button.rotation = 0.0
