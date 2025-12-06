extends CanvasLayer

@onready var header: PanelContainer = $Header
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $Header/TitleLabel
@onready var preview_panel: PanelContainer = $MainContainer/CenterContainer/PreviewPanel
@onready var selector_container: GridContainer = $MainContainer/RightSide/SelectorContainer
@onready var select_button: Button = $MainContainer/RightSide/SelectButton

# Preview elements (created dynamically)
var preview_sprite: Sprite2D
var preview_name_label: Label
var preview_class_label: Label
var preview_desc_label: Label
var preview_stats_container: VBoxContainer
var preview_passive_container: VBoxContainer

var selector_buttons: Array = []
var selector_sprites: Array = []  # Store sprites for animation
var selected_index: int = 0
var animation_timer: float = 0.0
var selector_anim_timer: float = 0.0
var characters_list: Array = []

# Animation state
var is_playing_attack: bool = false
var attack_display_timer: float = 0.0
const IDLE_DURATION: float = 4.0  # Seconds of idle before attack
const ATTACK_ANIM_SPEED: float = 12.0
const SELECTOR_ANIM_SPEED: float = 5.0  # Slower for smoother idle animations

# Font for placeholder "?" labels
var pixelify_font: Font = null

func _ready() -> void:
	# Load pixelify font for placeholder labels
	pixelify_font = load("res://assets/fonts/Pixelify_Sans/static/PixelifySans-Bold.ttf")

	back_button.pressed.connect(_on_back_pressed)
	select_button.pressed.connect(_on_select_pressed)

	_style_header()
	_style_golden_button(select_button)
	_style_back_button(back_button)

	_setup_preview_panel()
	_create_selector_buttons()
	_select_current_character()

	# Keep menu music playing
	if SoundManager:
		SoundManager.play_menu_music()

func _style_header() -> void:
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.0)
	style.border_width_bottom = 2
	style.border_color = Color(0.15, 0.14, 0.2, 0.0)
	style.content_margin_left = 60
	style.content_margin_right = 60
	header.add_theme_stylebox_override("panel", style)

	# Darken title label shadow
	if title_label:
		title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
		title_label.add_theme_constant_override("shadow_offset_x", 3)
		title_label.add_theme_constant_override("shadow_offset_y", 3)

func _process(delta: float) -> void:
	# Update animation for preview sprite
	if preview_sprite and selected_index >= 0 and selected_index < characters_list.size():
		var char_data = characters_list[selected_index]
		if char_data == null:
			return

		# Get correct animation rows for special characters
		var idle_row = char_data.row_idle
		var attack_row = char_data.row_attack
		var idle_frames = max(1, char_data.frames_idle)  # Prevent divide by zero
		var attack_frames = max(1, char_data.frames_attack)

		# Special handling for characters with direction-based sprite sheets
		match char_data.id:
			"minotaur":
				# Minotaur has left-facing rows at offset 10
				idle_row = 10  # Left-facing idle
				attack_row = 13  # Left-facing attack (row 3 + 10)
				idle_frames = 5
				attack_frames = 10
				preview_sprite.flip_h = false
			"skeleton_king":
				# Skeleton King faces left by default, flip sprite
				preview_sprite.flip_h = true
			"orc":
				# Orc faces left by default, flip sprite
				preview_sprite.flip_h = true
			_:
				preview_sprite.flip_h = false

		if is_playing_attack:
			# Playing attack animation
			animation_timer += delta * ATTACK_ANIM_SPEED
			var current_frame = int(animation_timer) % attack_frames
			preview_sprite.frame = attack_row * char_data.hframes + current_frame

			# Check if attack animation completed
			if animation_timer >= attack_frames:
				is_playing_attack = false
				animation_timer = 0.0
				attack_display_timer = 0.0
		else:
			# Playing idle animation
			animation_timer += delta * 8.0
			var current_frame = int(animation_timer) % idle_frames
			preview_sprite.frame = idle_row * char_data.hframes + current_frame

			# Check if it's time to play attack
			attack_display_timer += delta
			if attack_display_timer >= IDLE_DURATION:
				is_playing_attack = true
				animation_timer = 0.0

	# Update animation for selector sprites (idle animation)
	selector_anim_timer += delta * SELECTOR_ANIM_SPEED
	for i in selector_sprites.size():
		if i < characters_list.size():
			var char_data = characters_list[i]
			var sprite: Sprite2D = selector_sprites[i]
			if not sprite or char_data == null:
				continue

			var idle_row = char_data.row_idle
			var frame_count = max(1, char_data.frames_idle)  # Prevent divide by zero

			# Special handling for characters with direction-based sprite sheets
			match char_data.id:
				"minotaur":
					# Minotaur has left-facing rows at offset 10
					idle_row = 10  # Left-facing idle
					frame_count = 5
				"skeleton_king":
					# Skeleton King faces left by default, flip sprite
					sprite.flip_h = true
				"orc":
					# Orc faces left by default, flip sprite
					sprite.flip_h = true

			var current_frame = int(selector_anim_timer) % frame_count
			sprite.frame = idle_row * char_data.hframes + current_frame

func _setup_preview_panel() -> void:
	# Style the preview panel - darker and less transparent like equipment screen
	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.98)
	style.border_width_left = 4
	style.border_width_right = 4
	style.border_width_top = 4
	style.border_width_bottom = 4
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.corner_radius_top_left = 16
	style.corner_radius_top_right = 16
	style.corner_radius_bottom_left = 16
	style.corner_radius_bottom_right = 16
	preview_panel.add_theme_stylebox_override("panel", style)

	# Create internal layout - use CenterContainer to center everything horizontally
	var outer_center = CenterContainer.new()
	outer_center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	outer_center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	preview_panel.add_child(outer_center)

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 0)  # We'll add manual spacers
	vbox.alignment = BoxContainer.ALIGNMENT_CENTER
	outer_center.add_child(vbox)

	# Sprite preview - fixed height container for all characters
	var sprite_center = CenterContainer.new()
	sprite_center.custom_minimum_size = Vector2(300, 120)
	sprite_center.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	sprite_center.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	vbox.add_child(sprite_center)

	# Use a Control as parent to center the Sprite2D properly
	# Fixed size so all characters use the same space
	var sprite_holder = Control.new()
	sprite_holder.custom_minimum_size = Vector2(120, 120)
	sprite_holder.clip_contents = true
	sprite_center.add_child(sprite_holder)

	preview_sprite = Sprite2D.new()
	preview_sprite.centered = true
	preview_sprite.position = Vector2(60, 60)  # Center within the 120x120 holder
	sprite_holder.add_child(preview_sprite)

	# Spacer after sprite
	var spacer1 = Control.new()
	spacer1.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer1)

	# Character name below sprite - fixed height
	var name_container = Control.new()
	name_container.custom_minimum_size = Vector2(340, 24)
	vbox.add_child(name_container)
	preview_name_label = Label.new()
	preview_name_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_name_label.add_theme_font_size_override("font_size", 20)
	preview_name_label.add_theme_color_override("font_color", Color(0.95, 0.85, 0.4, 1))
	name_container.add_child(preview_name_label)

	# Class label below name - fixed height
	var class_container = Control.new()
	class_container.custom_minimum_size = Vector2(340, 20)
	vbox.add_child(class_container)
	preview_class_label = Label.new()
	preview_class_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_class_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_class_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	preview_class_label.add_theme_font_size_override("font_size", 16)
	preview_class_label.add_theme_color_override("font_color", Color(0.6, 0.8, 1.0, 1))
	class_container.add_child(preview_class_label)

	# Spacer after class
	var spacer2 = Control.new()
	spacer2.custom_minimum_size = Vector2(0, 4)
	vbox.add_child(spacer2)

	# Description - fixed height for 2 lines
	var desc_container = Control.new()
	desc_container.custom_minimum_size = Vector2(340, 40)
	vbox.add_child(desc_container)
	preview_desc_label = Label.new()
	preview_desc_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	preview_desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	preview_desc_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	preview_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	preview_desc_label.add_theme_font_size_override("font_size", 14)
	preview_desc_label.add_theme_color_override("font_color", Color(0.8, 0.8, 0.8, 1))
	desc_container.add_child(preview_desc_label)

	# Spacer after description
	var spacer3 = Control.new()
	spacer3.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer3)

	# Stats section - fixed height for all stats (8 rows * ~16px each)
	preview_stats_container = VBoxContainer.new()
	preview_stats_container.custom_minimum_size = Vector2(150, 130)
	preview_stats_container.add_theme_constant_override("separation", 2)
	vbox.add_child(preview_stats_container)

	# Spacer after stats
	var spacer4 = Control.new()
	spacer4.custom_minimum_size = Vector2(0, 6)
	vbox.add_child(spacer4)

	# Passive section - fixed height
	preview_passive_container = VBoxContainer.new()
	preview_passive_container.custom_minimum_size = Vector2(340, 50)
	preview_passive_container.add_theme_constant_override("separation", 3)
	vbox.add_child(preview_passive_container)

	# Spacer after passive (bottom padding)
	var spacer5 = Control.new()
	spacer5.custom_minimum_size = Vector2(0, 10)
	vbox.add_child(spacer5)

func _create_selector_buttons() -> void:
	var all_chars = CharacterManager.get_all_characters()

	# Reorder: original 7 first, then new characters in thematic groups
	# Row 1: archer, knight, monk, mage, beast
	# Row 2: assassin, barbarian, golem, lizardfolk_king, shardsoul_slayer
	# Row 3: necromancer, kobold_priest, ratfolk, minotaur, skeleton_king
	# COMMENTED OUT: orc, cyclops
	var order = [
		"archer", "knight", "monk", "mage", "beast",
		"assassin", "barbarian", "golem", "lizardfolk_king", "shardsoul_slayer",
		"necromancer", "kobold_priest", "ratfolk", "minotaur", "skeleton_king"
	]
	characters_list = []
	print("CharacterSelect: Building character list from %d available characters" % all_chars.size())
	for id in order:
		var found = false
		for char_data in all_chars:
			if char_data == null:
				print("CharacterSelect: WARNING - null character in all_chars")
				continue
			if not (char_data is CharacterData):
				print("CharacterSelect: WARNING - non-CharacterData object: %s" % typeof(char_data))
				continue
			if char_data.id == id:
				characters_list.append(char_data)
				found = true
				break
		if not found:
			print("CharacterSelect: WARNING - Character '%s' not found!" % id)

	selector_sprites = []  # Reset sprites array
	for i in characters_list.size():
		var char_data: CharacterData = characters_list[i]

		# Check if character is locked (Chad/Barbarian requires beating Hell)
		var is_locked = UnlocksManager and not UnlocksManager.is_character_unlocked(char_data.id)

		if is_locked:
			var locked_panel = _create_locked_character_button(char_data, i)
			selector_container.add_child(locked_panel)
			selector_buttons.append(locked_panel)
			selector_sprites.append(null)  # No sprite for locked characters
		else:
			var result = _create_selector_button(char_data, i)
			selector_container.add_child(result.panel)
			selector_buttons.append(result.panel)
			selector_sprites.append(result.sprite)

	# Add 3 locked placeholder slots to fill out the grid (17 chars + 3 = 20, 4 rows of 5)
	for i in 3:
		selector_container.add_child(_create_placeholder_button())

func _create_selector_button(char_data: CharacterData, index: int) -> Dictionary:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)  # 80x80 squares
	panel.set_meta("index", index)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.06, 0.055, 0.09, 0.98)
	# Use consistent 3px border so size doesn't change when selected
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.15, 0.14, 0.2, 1)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	# Add character sprite preview in the square - use Control holder to center properly
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)

	var sprite_holder = Control.new()
	sprite_holder.custom_minimum_size = Vector2(76, 76)
	sprite_holder.clip_contents = true
	center.add_child(sprite_holder)

	var sprite = Sprite2D.new()
	sprite.texture = char_data.sprite_texture
	sprite.hframes = char_data.hframes
	sprite.vframes = char_data.vframes
	sprite.frame = char_data.row_idle * char_data.hframes
	sprite.centered = true
	# Use region_rect if specified (for sprite sheets with extra pixels)
	if char_data.sprite_region.size.x > 0 and char_data.sprite_region.size.y > 0:
		sprite.region_enabled = true
		sprite.region_rect = char_data.sprite_region
	# Manual scales for 80x80 squares
	var sprite_scale = 2.0
	var sprite_pos = Vector2(38, 38)
	match char_data.id:
		"knight":
			sprite_scale = 1.7
		"monk":
			sprite_scale = 1.7
		"mage":
			sprite_pos = Vector2(33, 28)  # Move left 5px and up 5px
		"beast":
			sprite_scale = 0.88  # 10% bigger (was 0.8)
			sprite_pos = Vector2(38, 38)
			# Apply beast's sprite offset to center it properly
			sprite.offset = char_data.sprite_offset
		"barbarian":
			sprite_scale = 1.7  # Similar size to monk (96x96 frames)
			sprite_pos = Vector2(38, 38)
		"assassin":
			sprite_scale = 1.62  # Reduced 10% more to match other characters
			sprite_pos = Vector2(38, 35)  # Moved down 2px
		# New characters
		"golem":
			sprite_scale = 1.8  # 32x32 frames - smaller to fit
			sprite_pos = Vector2(38, 37)  # Move up 5px
		"orc":
			sprite_scale = 2.0  # 32x32 frames
		"minotaur":
			sprite_scale = 0.88  # 96x96 frames - 10% bigger
			sprite_pos = Vector2(38, 44)  # Move down 2px
		"cyclops":
			sprite_scale = 1.1  # 64x64 frames - 10% bigger
			sprite_pos = Vector2(38, 40)  # Move up 5px
		"lizardfolk_king":
			sprite_scale = 0.9  # 128x64 frames - smaller
			sprite_pos = Vector2(38, 45)  # Center better
		"skeleton_king":
			sprite_scale = 0.75  # 128x96 frames - adjusted for wider frame
			sprite_pos = Vector2(38, 40)  # Centered
		"shardsoul_slayer":
			sprite_scale = 1.1  # 64x64 frames - smaller
			sprite_pos = Vector2(38, 32)  # Move up
		"necromancer":
			sprite_scale = 1.8  # 32x32 frames - 10% smaller
			sprite_pos = Vector2(38, 33)  # Move up 5px
		"kobold_priest":
			sprite_scale = 2.0  # 32x32 frames
			sprite_pos = Vector2(38, 33)  # Move up 5px
		"ratfolk":
			sprite_scale = 1.5  # 64x32 frames
			sprite_pos = Vector2(38, 37)  # Move up 5px
	sprite.scale = Vector2(sprite_scale, sprite_scale)
	sprite.position = sprite_pos
	sprite_holder.add_child(sprite)

	# Clickable button overlay
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.pressed.connect(_on_selector_pressed.bind(index))
	panel.add_child(button)

	return {"panel": panel, "sprite": sprite}

func _create_placeholder_button() -> PanelContainer:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.08, 0.1, 0.7)
	# Use consistent 3px border to match character squares
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.2, 0.2, 0.25, 0.5)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	# Add a "?" label in the center
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)

	var label = Label.new()
	label.text = "?"
	if pixelify_font:
		label.add_theme_font_override("font", pixelify_font)
	label.add_theme_font_size_override("font_size", 30)
	label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.55, 0.8))
	center.add_child(label)

	return panel

func _create_locked_character_button(char_data: CharacterData, index: int) -> PanelContainer:
	"""Create a locked character button with a big red question mark."""
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(80, 80)
	panel.set_meta("index", index)
	panel.set_meta("locked", true)

	var style = StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.95)
	style.border_width_left = 3
	style.border_width_right = 3
	style.border_width_top = 3
	style.border_width_bottom = 3
	style.border_color = Color(0.4, 0.2, 0.2, 0.8)  # Reddish border for locked
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	panel.add_theme_stylebox_override("panel", style)

	# Center container for question mark
	var center = CenterContainer.new()
	center.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	center.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.add_child(center)

	# Big red question mark
	var question_label = Label.new()
	question_label.text = "?"
	question_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixelify_font:
		question_label.add_theme_font_override("font", pixelify_font)
	question_label.add_theme_font_size_override("font_size", 40)
	question_label.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 1.0))  # Red
	center.add_child(question_label)

	# Clickable button overlay (shows locked message)
	var button = Button.new()
	button.flat = true
	button.anchors_preset = Control.PRESET_FULL_RECT
	button.pressed.connect(_on_locked_character_pressed.bind(char_data))
	panel.add_child(button)

	return panel

func _on_locked_character_pressed(char_data: CharacterData) -> void:
	"""Show a message when clicking a locked character."""
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()

	# Show locked notification
	_show_locked_notification(char_data)

func _select_current_character() -> void:
	var current = CharacterManager.get_selected_character()
	if current == null:
		_set_selected(0)  # Default to first character
		return
	for i in characters_list.size():
		var char_data: CharacterData = characters_list[i]
		if char_data.id == current.id:
			_set_selected(i)
			return
	# Character not found in list, default to first
	_set_selected(0)

func _set_selected(index: int) -> void:
	selected_index = index
	animation_timer = 0.0
	attack_display_timer = 0.0
	is_playing_attack = false

	# Update selector button highlights
	# Keep border width constant (3px) so size doesn't change when selected
	for i in selector_buttons.size():
		var panel: PanelContainer = selector_buttons[i]
		var style = panel.get_theme_stylebox("panel").duplicate()

		if i == index:
			style.border_color = Color(0.95, 0.75, 0.2, 1)  # Gold
			style.bg_color = Color(0.12, 0.10, 0.08, 0.95)
		else:
			style.border_color = Color(0.15, 0.14, 0.2, 1)
			style.bg_color = Color(0.06, 0.055, 0.09, 0.98)

		panel.add_theme_stylebox_override("panel", style)

	# Update preview
	_update_preview()

func _update_preview() -> void:
	if selected_index < 0 or selected_index >= characters_list.size():
		return
	if not preview_sprite:
		return

	var char_data = characters_list[selected_index]
	if char_data == null:
		print("CharacterSelect: ERROR - char_data is null at index %d" % selected_index)
		return
	if not (char_data is CharacterData):
		print("CharacterSelect: ERROR - char_data is not CharacterData, type: %s" % typeof(char_data))
		return

	# Update name
	if preview_name_label:
		preview_name_label.text = char_data.display_name

	# Update class label
	var class_type_text = "Ranger"
	match char_data.id:
		"archer":
			class_type_text = "Ranger"
		"knight":
			class_type_text = "Knight"
		"beast":
			class_type_text = "???"
		"mage":
			class_type_text = "Mage"
		"monk":
			class_type_text = "Monk"
		"barbarian":
			class_type_text = "Barbarian"
		"assassin":
			class_type_text = "Assassin"
		# New characters
		"golem":
			class_type_text = "Tank"
		"orc":
			class_type_text = "Warrior"
		"minotaur":
			class_type_text = "Minotaur"
		"cyclops":
			class_type_text = "Cyclops"
		"lizardfolk_king":
			class_type_text = "Lizard"
		"skeleton_king":
			class_type_text = "Undead"
		"shardsoul_slayer":
			class_type_text = "Slayer"
		"necromancer":
			class_type_text = "Summoner"
		"kobold_priest":
			class_type_text = "Priest"
		"ratfolk":
			class_type_text = "Rogue"
	if preview_class_label:
		preview_class_label.text = class_type_text

	# Update sprite
	preview_sprite.texture = char_data.sprite_texture
	preview_sprite.hframes = char_data.hframes
	preview_sprite.vframes = char_data.vframes
	preview_sprite.frame = char_data.row_idle * char_data.hframes
	# Use region_rect if specified (for sprite sheets with extra pixels)
	if char_data.sprite_region.size.x > 0 and char_data.sprite_region.size.y > 0:
		preview_sprite.region_enabled = true
		preview_sprite.region_rect = char_data.sprite_region
	else:
		preview_sprite.region_enabled = false

	# Manual scales to match mage visually
	var preview_scale = 2.5
	var preview_pos = Vector2(60, 60)  # Center within 120x120 holder
	var preview_offset = Vector2(0, 0)
	match char_data.id:
		"knight":
			preview_scale = 2.1
		"monk":
			preview_scale = 2.1
		"beast":
			preview_scale = 1.2
			# Apply beast's sprite offset to center it properly
			preview_offset = char_data.sprite_offset
		"barbarian":
			preview_scale = 2.1  # Similar to monk (96x96 frames)
		"assassin":
			preview_scale = 2.1  # Match monk size
		# New characters
		"golem":
			preview_scale = 2.2  # 32x32 frames - smaller
		"orc":
			preview_scale = 2.5  # 32x32 frames
		"minotaur":
			preview_scale = 1.32  # 96x96 frames - 20% bigger
		"cyclops":
			preview_scale = 1.4  # 64x64 frames - smaller
		"lizardfolk_king":
			preview_scale = 1.3  # 128x64 frames - smaller
		"skeleton_king":
			preview_scale = 1.0  # 128x96 frames - adjusted for wider frame
		"shardsoul_slayer":
			preview_scale = 1.5  # 64x64 frames - smaller
		"necromancer":
			preview_scale = 2.2  # 32x32 frames - 10% smaller
		"kobold_priest":
			preview_scale = 2.5  # 32x32 frames
		"ratfolk":
			preview_scale = 2.0  # 64x32 frames
	preview_sprite.scale = Vector2(preview_scale, preview_scale)
	preview_sprite.position = preview_pos
	preview_sprite.offset = preview_offset

	# Update description
	preview_desc_label.text = char_data.description

	# Update stats
	for child in preview_stats_container.get_children():
		child.queue_free()

	# Fixed width container for stats to keep alignment consistent
	var stats_box = VBoxContainer.new()
	stats_box.custom_minimum_size = Vector2(150, 0)
	stats_box.add_theme_constant_override("separation", 2)
	preview_stats_container.add_child(stats_box)

	var attack_type_text = "Ranged" if char_data.attack_type == CharacterData.AttackType.RANGED else "Melee"
	_add_stat_row_to_container(stats_box, "Type", attack_type_text, Color(0.9, 0.9, 0.9, 1))

	_add_stat_row_to_container(stats_box, "Health", "%.0f" % char_data.base_health, _get_stat_color(char_data.base_health, 25, 50))
	_add_stat_row_to_container(stats_box, "Speed", "%.0f" % char_data.base_speed, _get_stat_color(char_data.base_speed, 100, 200))
	_add_stat_row_to_container(stats_box, "Attack Speed", "%.2f/s" % (1.0 / char_data.base_attack_cooldown), _get_stat_color(1.0 / char_data.base_attack_cooldown, 0.8, 1.5))
	_add_stat_row_to_container(stats_box, "Damage", "x%.1f" % char_data.base_damage, _get_stat_color(char_data.base_damage, 0.8, 1.8))

	# Combat stats
	_add_stat_row_to_container(stats_box, "Armor", "%d" % char_data.base_armor, _get_stat_color(char_data.base_armor, 0, 2))
	_add_stat_row_to_container(stats_box, "Crit Rate", "%d%%" % int(char_data.base_crit_rate * 100), _get_stat_color(char_data.base_crit_rate, 0.0, 0.15))
	_add_stat_row_to_container(stats_box, "Block Rate", "%d%%" % int(char_data.base_block_rate * 100), _get_stat_color(char_data.base_block_rate, 0.0, 0.10))
	_add_stat_row_to_container(stats_box, "Dodge Rate", "%d%%" % int(char_data.base_dodge_rate * 100), _get_stat_color(char_data.base_dodge_rate, 0.0, 0.15))

	# Update passive
	for child in preview_passive_container.get_children():
		child.queue_free()

	var passive_title_container = MarginContainer.new()
	passive_title_container.custom_minimum_size = Vector2(340, 0)
	passive_title_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_passive_container.add_child(passive_title_container)
	var passive_title = Label.new()
	passive_title.text = "Specialty: " + char_data.passive_name
	passive_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_title.add_theme_font_size_override("font_size", 14)
	passive_title.add_theme_color_override("font_color", Color(1.0, 0.8, 0.3, 1))
	passive_title_container.add_child(passive_title)

	var passive_desc_container = MarginContainer.new()
	passive_desc_container.custom_minimum_size = Vector2(340, 24)  # Min height for 2 lines at font size 10
	passive_desc_container.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	preview_passive_container.add_child(passive_desc_container)
	var passive_desc = Label.new()
	passive_desc.text = char_data.passive_description
	passive_desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	passive_desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	passive_desc.add_theme_font_size_override("font_size", 12)
	passive_desc.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7, 1))
	passive_desc_container.add_child(passive_desc)

func _add_stat_row_to_container(container: VBoxContainer, stat_name: String, stat_value: String, color: Color) -> void:
	var hbox = HBoxContainer.new()
	container.add_child(hbox)

	var name_label = Label.new()
	name_label.text = stat_name + ":"
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.add_theme_font_size_override("font_size", 13)
	name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1))
	hbox.add_child(name_label)

	var value_label = Label.new()
	value_label.text = stat_value
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_font_size_override("font_size", 13)
	value_label.add_theme_color_override("font_color", color)
	hbox.add_child(value_label)

func _get_stat_color(value: float, low: float, high: float) -> Color:
	var t = clamp((value - low) / (high - low), 0.0, 1.0)
	if t < 0.5:
		return Color(1.0, t * 2, 0.2, 1)
	else:
		return Color(1.0 - (t - 0.5) * 2, 1.0, 0.2, 1)

func _on_selector_pressed(index: int) -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	_set_selected(index)

func _on_back_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")

func _on_select_pressed() -> void:
	if SoundManager:
		SoundManager.play_click()
	if HapticManager:
		HapticManager.light()
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
	style_normal.bg_color = Color(0.8, 0.2, 0.2, 1)
	style_normal.border_width_left = 3
	style_normal.border_width_right = 3
	style_normal.border_width_top = 3
	style_normal.border_width_bottom = 8
	style_normal.border_color = Color(0.4, 0.1, 0.1, 1)
	style_normal.corner_radius_top_left = 6
	style_normal.corner_radius_top_right = 6
	style_normal.corner_radius_bottom_left = 6
	style_normal.corner_radius_bottom_right = 6

	var style_hover = StyleBoxFlat.new()
	style_hover.bg_color = Color(0.9, 0.25, 0.25, 1)
	style_hover.border_width_left = 3
	style_hover.border_width_right = 3
	style_hover.border_width_top = 3
	style_hover.border_width_bottom = 8
	style_hover.border_color = Color(0.5, 0.15, 0.15, 1)
	style_hover.corner_radius_top_left = 6
	style_hover.corner_radius_top_right = 6
	style_hover.corner_radius_bottom_left = 6
	style_hover.corner_radius_bottom_right = 6

	var style_pressed = StyleBoxFlat.new()
	style_pressed.bg_color = Color(0.65, 0.15, 0.15, 1)
	style_pressed.border_width_left = 3
	style_pressed.border_width_right = 3
	style_pressed.border_width_top = 6
	style_pressed.border_width_bottom = 5
	style_pressed.border_color = Color(0.35, 0.1, 0.1, 1)
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

	# Add darker text shadow
	button.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	button.add_theme_constant_override("shadow_offset_x", 2)
	button.add_theme_constant_override("shadow_offset_y", 2)

func _show_locked_notification(_char_data: CharacterData) -> void:
	"""Show a notification explaining how to unlock this character."""
	var notification = CanvasLayer.new()
	notification.layer = 100
	add_child(notification)

	# Black background panel
	var panel = PanelContainer.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.grow_horizontal = Control.GROW_DIRECTION_BOTH
	panel.grow_vertical = Control.GROW_DIRECTION_BOTH

	var panel_style = StyleBoxFlat.new()
	panel_style.bg_color = Color(0, 0, 0, 0.9)
	panel_style.corner_radius_top_left = 10
	panel_style.corner_radius_top_right = 10
	panel_style.corner_radius_bottom_left = 10
	panel_style.corner_radius_bottom_right = 10
	panel_style.content_margin_left = 30
	panel_style.content_margin_right = 30
	panel_style.content_margin_top = 20
	panel_style.content_margin_bottom = 20
	panel.add_theme_stylebox_override("panel", panel_style)
	notification.add_child(panel)

	var label = Label.new()
	label.text = "Beat Hell difficulty to unlock character"
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	if pixelify_font:
		label.add_theme_font_override("font", pixelify_font)
	label.add_theme_font_size_override("font_size", 24)
	label.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1))

	panel.add_child(label)

	# Animate in and fade out
	panel.modulate.a = 0.0
	var tween = create_tween()
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_interval(1.5)
	tween.tween_property(panel, "modulate:a", 0.0, 0.5)
	tween.tween_callback(func(): notification.queue_free())
