extends CanvasLayer

# Game HUD - Top-left portrait with health bar and progress bar
# Clicking portrait opens pause menu

const PORTRAIT_SIZE := 64
const HEALTH_BAR_WIDTH := 150
const HEALTH_BAR_HEIGHT := 20
const PROGRESS_BAR_WIDTH := 150
const PROGRESS_BAR_HEIGHT := 20
const MARGIN := 16
const SPACING := 8
const ICON_SIZE := 20
const ICON_SPACING := 4

const HEALTH_ICON_PATH := "res://assets/sprites/icons/raven/32x32/fb659.png"
const XP_ICON_PATH := "res://assets/sprites/icons/raven/32x32/fb663.png"

var player: Node2D = null
var pixel_font: Font = null
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
var pause_menu: CanvasLayer = null

# UI References
var portrait_button: Button = null
var portrait_texture: TextureRect = null
var pause_overlay: Label = null
var health_icon: TextureRect = null
var health_bar_bg: Panel = null
var health_bar_fill: Panel = null
var health_bar_shield: Panel = null
var health_label: Label = null
var xp_icon: TextureRect = null
var progress_bar_bg: Panel = null
var progress_bar_fill: Panel = null
var level_label: Label = null

# State
var current_health: float = 100.0
var max_health: float = 100.0
var current_shield: float = 0.0
var max_shield: float = 0.0
var displayed_xp: float = 0.0
var current_tween: Tween = null

func _ready() -> void:
	layer = 50

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	_create_ui()

	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("health_changed", _on_health_changed)
		player.connect("xp_changed", _on_xp_changed)
		player.connect("level_up", _on_level_up)

		# Initialize values
		_on_health_changed(player.current_health, player.max_health)
		displayed_xp = player.current_xp
		_update_progress_bar(player.current_xp, player.xp_to_next_level)
		_update_level_label(player.current_level)

		# Set portrait from character
		_setup_portrait()

func _create_ui() -> void:
	var container = Control.new()
	container.name = "HUDContainer"
	container.set_anchors_preset(Control.PRESET_TOP_LEFT)
	container.offset_left = MARGIN
	container.offset_top = MARGIN
	container.offset_right = MARGIN + PORTRAIT_SIZE + SPACING + HEALTH_BAR_WIDTH
	container.offset_bottom = MARGIN + PORTRAIT_SIZE + SPACING + PROGRESS_BAR_HEIGHT
	add_child(container)

	# Portrait button (clickable for pause)
	portrait_button = Button.new()
	portrait_button.name = "PortraitButton"
	portrait_button.custom_minimum_size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait_button.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait_button.position = Vector2.ZERO
	portrait_button.pressed.connect(_on_pause_pressed)
	portrait_button.flat = true
	container.add_child(portrait_button)

	# Portrait background
	var portrait_bg = Panel.new()
	portrait_bg.name = "PortraitBG"
	portrait_bg.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	portrait_bg.position = Vector2.ZERO
	portrait_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.15, 0.95)
	bg_style.border_color = Color(0.4, 0.35, 0.3, 1.0)
	bg_style.set_border_width_all(3)
	bg_style.set_corner_radius_all(4)
	portrait_bg.add_theme_stylebox_override("panel", bg_style)
	portrait_button.add_child(portrait_bg)

	# Portrait texture (character face)
	portrait_texture = TextureRect.new()
	portrait_texture.name = "PortraitTexture"
	portrait_texture.size = Vector2(PORTRAIT_SIZE - 6, PORTRAIT_SIZE - 6)
	portrait_texture.position = Vector2(3, 3)
	portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait_texture.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_button.add_child(portrait_texture)

	# Pause overlay (|| symbol)
	pause_overlay = Label.new()
	pause_overlay.name = "PauseOverlay"
	pause_overlay.text = "||"
	pause_overlay.size = Vector2(PORTRAIT_SIZE, PORTRAIT_SIZE)
	pause_overlay.position = Vector2.ZERO
	pause_overlay.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	pause_overlay.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pause_overlay.add_theme_color_override("font_color", Color(1, 1, 1, 0.35))
	pause_overlay.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	pause_overlay.add_theme_constant_override("shadow_offset_x", 2)
	pause_overlay.add_theme_constant_override("shadow_offset_y", 2)
	if pixel_font:
		pause_overlay.add_theme_font_override("font", pixel_font)
	pause_overlay.add_theme_font_size_override("font_size", 18)
	pause_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	portrait_button.add_child(pause_overlay)

	# Health bar row (icon + bar)
	var health_row_x = PORTRAIT_SIZE + SPACING
	var health_row_y = 2  # Slight offset from top

	# Health icon
	health_icon = TextureRect.new()
	health_icon.name = "HealthIcon"
	health_icon.texture = load(HEALTH_ICON_PATH)
	health_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	health_icon.position = Vector2(health_row_x, health_row_y + (HEALTH_BAR_HEIGHT - ICON_SIZE) / 2)
	health_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	health_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(health_icon)

	# Health bar (to the right of icon)
	var health_bar_x = health_row_x + ICON_SIZE + ICON_SPACING
	var health_bar_y = health_row_y

	# Health bar background
	health_bar_bg = Panel.new()
	health_bar_bg.name = "HealthBarBG"
	health_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar_bg.position = Vector2(health_bar_x, health_bar_y)
	var health_bg_style = StyleBoxFlat.new()
	health_bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	health_bg_style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	health_bg_style.set_border_width_all(2)
	health_bg_style.set_corner_radius_all(2)
	health_bar_bg.add_theme_stylebox_override("panel", health_bg_style)
	container.add_child(health_bar_bg)

	# Health bar fill
	health_bar_fill = Panel.new()
	health_bar_fill.name = "HealthBarFill"
	health_bar_fill.size = Vector2(HEALTH_BAR_WIDTH - 4, HEALTH_BAR_HEIGHT - 4)
	health_bar_fill.position = Vector2(health_bar_x + 2, health_bar_y + 2)
	var health_fill_style = StyleBoxFlat.new()
	health_fill_style.bg_color = Color(0.8, 0.2, 0.2, 1.0)  # Red
	health_fill_style.set_corner_radius_all(1)
	health_bar_fill.add_theme_stylebox_override("panel", health_fill_style)
	container.add_child(health_bar_fill)

	# Shield bar (overlay on health)
	health_bar_shield = Panel.new()
	health_bar_shield.name = "HealthBarShield"
	health_bar_shield.size = Vector2(0, HEALTH_BAR_HEIGHT - 4)
	health_bar_shield.position = Vector2(health_bar_x + 2, health_bar_y + 2)
	health_bar_shield.visible = false
	var shield_style = StyleBoxFlat.new()
	shield_style.bg_color = Color(0.4, 0.6, 1.0, 0.9)
	shield_style.set_corner_radius_all(1)
	health_bar_shield.add_theme_stylebox_override("panel", shield_style)
	container.add_child(health_bar_shield)

	# Health label (HP numbers inside bar)
	health_label = Label.new()
	health_label.name = "HealthLabel"
	health_label.text = "100/100"
	health_label.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_label.position = Vector2(health_bar_x, health_bar_y)
	health_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	health_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	health_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	health_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	health_label.add_theme_constant_override("shadow_offset_x", 1)
	health_label.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		health_label.add_theme_font_override("font", pixel_font)
	health_label.add_theme_font_size_override("font_size", 10)
	container.add_child(health_label)

	# Progress bar row (icon + bar)
	var progress_row_y = health_row_y + HEALTH_BAR_HEIGHT + SPACING

	# XP icon
	xp_icon = TextureRect.new()
	xp_icon.name = "XPIcon"
	xp_icon.texture = load(XP_ICON_PATH)
	xp_icon.custom_minimum_size = Vector2(ICON_SIZE, ICON_SIZE)
	xp_icon.position = Vector2(health_row_x, progress_row_y + (PROGRESS_BAR_HEIGHT - ICON_SIZE) / 2)
	xp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xp_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	container.add_child(xp_icon)

	# Progress bar (to the right of icon)
	var progress_bar_x = health_row_x + ICON_SIZE + ICON_SPACING

	# Progress bar background
	progress_bar_bg = Panel.new()
	progress_bar_bg.name = "ProgressBarBG"
	progress_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, PROGRESS_BAR_HEIGHT)
	progress_bar_bg.position = Vector2(progress_bar_x, progress_row_y)
	var progress_bg_style = StyleBoxFlat.new()
	progress_bg_style.bg_color = Color(0.15, 0.15, 0.2, 0.9)
	progress_bg_style.border_color = Color(0.1, 0.15, 0.35, 1.0)
	progress_bg_style.set_border_width_all(2)
	progress_bg_style.set_corner_radius_all(4)
	progress_bar_bg.add_theme_stylebox_override("panel", progress_bg_style)
	container.add_child(progress_bar_bg)

	# Progress bar fill
	progress_bar_fill = Panel.new()
	progress_bar_fill.name = "ProgressBarFill"
	progress_bar_fill.size = Vector2(0, PROGRESS_BAR_HEIGHT - 4)
	progress_bar_fill.position = Vector2(progress_bar_x + 2, progress_row_y + 2)
	var progress_fill_style = StyleBoxFlat.new()
	progress_fill_style.bg_color = Color(0.3, 0.7, 1.0, 1.0)  # Blue
	progress_fill_style.set_corner_radius_all(2)
	progress_bar_fill.add_theme_stylebox_override("panel", progress_fill_style)
	container.add_child(progress_bar_fill)

	# Level label (centered on progress bar)
	level_label = Label.new()
	level_label.name = "LevelLabel"
	level_label.text = "Lv 1"
	level_label.size = Vector2(HEALTH_BAR_WIDTH, PROGRESS_BAR_HEIGHT)
	level_label.position = Vector2(progress_bar_x, progress_row_y)
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.add_theme_color_override("font_color", Color(1, 1, 1, 1))
	level_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	level_label.add_theme_constant_override("shadow_offset_x", 1)
	level_label.add_theme_constant_override("shadow_offset_y", 1)
	if pixel_font:
		level_label.add_theme_font_override("font", pixel_font)
	level_label.add_theme_font_size_override("font_size", 10)
	container.add_child(level_label)

func _setup_portrait() -> void:
	# Get character portrait from CharacterManager
	if not CharacterManager:
		return

	var character = CharacterManager.get_selected_character()
	if character == null or character.sprite_texture == null:
		return

	# Create an AtlasTexture to show just the face (first frame of idle, zoomed in)
	var atlas = AtlasTexture.new()
	atlas.atlas = character.sprite_texture

	# Calculate the region for the first idle frame
	var frame_w = character.frame_size.x
	var frame_h = character.frame_size.y
	var idle_row = character.row_idle

	# For face close-up, we want the upper portion of the first idle frame
	# Adjust region to focus on the face area (top 60-70% of frame)
	var face_region_y = idle_row * frame_h
	var face_height = frame_h * 0.7  # Top 70% for face

	# Center horizontally but focus on upper portion
	atlas.region = Rect2(0, face_region_y, frame_w, face_height)

	portrait_texture.texture = atlas

func _process(_delta: float) -> void:
	# Update shield display from AbilityManager
	if AbilityManager and AbilityManager.has_transcendence:
		var new_shield = AbilityManager.transcendence_shields
		var new_max = AbilityManager.transcendence_max
		if new_shield != current_shield or new_max != max_shield:
			current_shield = new_shield
			max_shield = new_max
			_update_health_bar()

func _on_health_changed(current: float, maximum: float) -> void:
	current_health = current
	max_health = maximum
	_update_health_bar()

func _update_health_bar() -> void:
	if health_bar_fill == null:
		return

	var ratio = clamp(current_health / max_health, 0.0, 1.0)
	var fill_width = (HEALTH_BAR_WIDTH - 4) * ratio
	health_bar_fill.size.x = fill_width

	# Update health label
	if health_label:
		health_label.text = str(int(current_health)) + "/" + str(int(max_health))

	# Update shield display
	if current_shield > 0 and max_shield > 0:
		health_bar_shield.visible = true
		var shield_ratio = clamp(current_shield / max_shield, 0.0, 1.0)
		health_bar_shield.size.x = (HEALTH_BAR_WIDTH - 4) * shield_ratio
	else:
		health_bar_shield.visible = false

func _on_xp_changed(current_xp: float, xp_needed: float, level: int) -> void:
	_update_level_label(level)

	# Cancel existing tween
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	# If XP decreased (level up reset), snap to new value
	if current_xp < displayed_xp:
		displayed_xp = current_xp
		_update_progress_bar(current_xp, xp_needed)
		return

	# Smoothly animate to new XP value
	var start_xp = displayed_xp
	displayed_xp = current_xp
	current_tween = create_tween()
	current_tween.tween_method(
		func(val): _update_progress_bar(val, xp_needed),
		start_xp,
		current_xp,
		0.3
	).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)

func _update_progress_bar(current_xp: float, xp_needed: float) -> void:
	if progress_bar_fill == null:
		return

	var ratio = clamp(current_xp / xp_needed, 0.0, 1.0) if xp_needed > 0 else 0.0
	var fill_width = (HEALTH_BAR_WIDTH - 4) * ratio
	progress_bar_fill.size.x = fill_width

func _update_level_label(level: int) -> void:
	if level_label:
		level_label.text = "Lv " + str(level)

func _on_level_up(new_level: int) -> void:
	_update_level_label(new_level)

	# Pulse animation on level label
	if level_label:
		var original_scale = level_label.scale
		level_label.pivot_offset = level_label.size / 2
		var tween = create_tween()
		tween.tween_property(level_label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
		tween.tween_property(level_label, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN)

func _on_pause_pressed() -> void:
	if pause_menu == null:
		pause_menu = pause_menu_scene.instantiate()
		pause_menu.gave_up.connect(_on_gave_up)
		get_tree().root.add_child(pause_menu)

	pause_menu.show_menu()

func _on_gave_up() -> void:
	var main = get_tree().get_first_node_in_group("main")
	if main == null:
		main = get_node_or_null("/root/Main")

	if main and main.has_method("show_game_over"):
		main.show_game_over(true)
	else:
		get_tree().paused = false
		get_tree().change_scene_to_file("res://scenes/game_over.tscn")

func _input(event: InputEvent) -> void:
	# ESC to toggle pause when not in other menus
	if event is InputEventKey and event.pressed and event.keycode == KEY_ESCAPE:
		# Check if other UIs are open
		var ability_ui = get_tree().get_first_node_in_group("ability_selection")
		if ability_ui and ability_ui.visible:
			return

		var pickup_ui = get_tree().get_first_node_in_group("item_pickup_ui")
		if pickup_ui and pickup_ui.visible:
			return

		if pause_menu and pause_menu.visible:
			pause_menu.hide_menu()
		else:
			_on_pause_pressed()

		get_viewport().set_input_as_handled()
