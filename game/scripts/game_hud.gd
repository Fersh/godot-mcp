extends CanvasLayer

# Game HUD - Top-left portrait with health bar and progress bar
# Clicking portrait opens pause menu

const PORTRAIT_SIZE := 80  # 66 * 1.21
const HEALTH_BAR_WIDTH := 200  # 165 * 1.21
const HEALTH_BAR_HEIGHT := 29  # 24 * 1.21
const PROGRESS_BAR_WIDTH := 200  # 165 * 1.21
const PROGRESS_BAR_HEIGHT := 29  # 24 * 1.21
const MARGIN := 48  # Distance from edge of screen (40 * 1.21)
const SPACING := 11  # 9 * 1.21
const ICON_SIZE := 29  # Same as bar height (24 * 1.21)
const ICON_MARGIN_RIGHT := 13  # 11 * 1.21

const HEALTH_ICON_PATH := "res://assets/sprites/icons/raven/32x32/fb659.png"
const XP_ICON_PATH := "res://assets/sprites/icons/raven/32x32/fb101.png"

var health_icon_texture: Texture2D = null
var xp_icon_texture: Texture2D = null

var player: Node2D = null
var pixel_font: Font = null
var pause_menu_scene: PackedScene = preload("res://scenes/pause_menu.tscn")
var pause_menu: CanvasLayer = null

# UI References
var portrait_button: Button = null
var portrait_texture: TextureRect = null
var portrait_bg: Panel = null
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
var previous_health: float = 100.0
var current_shield: float = 0.0
var max_shield: float = 0.0
var displayed_xp: float = 0.0
var previous_xp: float = 0.0
var current_tween: Tween = null

# Low HP heartbeat animation
var low_hp_active: bool = false
var heartbeat_phase: float = 0.0
var health_bar_original_scale: Vector2 = Vector2.ONE
var health_bar_original_rotation: float = 0.0

# Animation constants (matching combo style)
const BAR_BASE_ROTATION: float = 0.0  # Return to no rotation (original position)
const BAR_SHAKE_AMOUNT: float = 0.06
const BAR_PULSE_SCALE: float = 1.08
const BAR_FILL_PULSE_SCALE: float = 1.04  # Slightly smaller pulse for fill bar

# Kill streak fire effect
var fire_container: Control = null
var fire_particles: Array[Dictionary] = []
var current_fire_tier: int = 0
const FIRE_PARTICLE_COUNT: int = 12
const FIRE_UPDATE_RATE: float = 0.08  # Update every ~12fps for pixelated look

func _ready() -> void:
	layer = 50

	# Load pixel font
	if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
		pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

	# Load icon textures
	if ResourceLoader.exists(HEALTH_ICON_PATH):
		health_icon_texture = load(HEALTH_ICON_PATH)
	if ResourceLoader.exists(XP_ICON_PATH):
		xp_icon_texture = load(XP_ICON_PATH)

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
	# Slight rotation with right side down (~1 degree)
	container.pivot_offset = Vector2(0, 0)  # Rotate from top-left corner
	container.rotation = -0.017  # ~1 degree, right side down
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
	portrait_bg = Panel.new()
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

	# Health bar row (icon + bar) - vertically centered with portrait
	var health_row_x = PORTRAIT_SIZE + SPACING
	# Total height of both bars + spacing between them
	var total_bars_height = HEALTH_BAR_HEIGHT + SPACING + PROGRESS_BAR_HEIGHT
	var health_row_y = (PORTRAIT_SIZE - total_bars_height) / 2  # Center vertically

	# Health icon (vertically centered with bar)
	var icon_offset_y = (HEALTH_BAR_HEIGHT - ICON_SIZE) / 2
	var health_icon_panel = Panel.new()
	health_icon_panel.position = Vector2(health_row_x, health_row_y + icon_offset_y)
	health_icon_panel.size = Vector2(ICON_SIZE, ICON_SIZE)
	var icon_style = StyleBoxFlat.new()
	icon_style.bg_color = Color(0, 0, 0, 0)  # Transparent
	health_icon_panel.add_theme_stylebox_override("panel", icon_style)
	container.add_child(health_icon_panel)

	health_icon = TextureRect.new()
	health_icon.name = "HealthIcon"
	if health_icon_texture:
		health_icon.texture = health_icon_texture
	health_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	health_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	health_icon.stretch_mode = TextureRect.STRETCH_SCALE
	health_icon_panel.add_child(health_icon)

	# Health bar (to the right of icon with margin)
	var health_bar_x = health_row_x + ICON_SIZE + ICON_MARGIN_RIGHT
	var health_bar_y = health_row_y

	# Health bar background
	health_bar_bg = Panel.new()
	health_bar_bg.name = "HealthBarBG"
	health_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, HEALTH_BAR_HEIGHT)
	health_bar_bg.position = Vector2(health_bar_x, health_bar_y)
	health_bar_bg.pivot_offset = Vector2(HEALTH_BAR_WIDTH / 2, HEALTH_BAR_HEIGHT / 2)  # Pulse from center
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
	health_fill_style.bg_color = Color(0.2, 0.8, 0.2, 1.0)  # Green (will change based on health)
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

	# Progress bar row (icon + bar) - aligned with health bar
	var progress_row_y = health_row_y + HEALTH_BAR_HEIGHT + SPACING

	# XP icon (vertically centered with bar)
	var xp_icon_panel = Panel.new()
	xp_icon_panel.position = Vector2(health_row_x, progress_row_y + icon_offset_y)
	xp_icon_panel.size = Vector2(ICON_SIZE, ICON_SIZE)
	var xp_icon_style = StyleBoxFlat.new()
	xp_icon_style.bg_color = Color(0, 0, 0, 0)  # Transparent
	xp_icon_panel.add_theme_stylebox_override("panel", xp_icon_style)
	container.add_child(xp_icon_panel)

	xp_icon = TextureRect.new()
	xp_icon.name = "XPIcon"
	if xp_icon_texture:
		xp_icon.texture = xp_icon_texture
	xp_icon.set_anchors_preset(Control.PRESET_FULL_RECT)
	xp_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	xp_icon.stretch_mode = TextureRect.STRETCH_SCALE
	xp_icon_panel.add_child(xp_icon)

	# Progress bar (to the right of icon with margin - same x as health bar)
	var progress_bar_x = health_bar_x

	# Progress bar background (same radius as health bar)
	progress_bar_bg = Panel.new()
	progress_bar_bg.name = "ProgressBarBG"
	progress_bar_bg.size = Vector2(HEALTH_BAR_WIDTH, PROGRESS_BAR_HEIGHT)
	progress_bar_bg.position = Vector2(progress_bar_x, progress_row_y)
	var progress_bg_style = StyleBoxFlat.new()
	progress_bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	progress_bg_style.border_color = Color(0.3, 0.25, 0.2, 1.0)
	progress_bg_style.set_border_width_all(2)
	progress_bg_style.set_corner_radius_all(2)
	progress_bar_bg.add_theme_stylebox_override("panel", progress_bg_style)
	container.add_child(progress_bar_bg)

	# Progress bar fill
	progress_bar_fill = Panel.new()
	progress_bar_fill.name = "ProgressBarFill"
	progress_bar_fill.size = Vector2(0, PROGRESS_BAR_HEIGHT - 4)
	progress_bar_fill.position = Vector2(progress_bar_x + 2, progress_row_y + 2)
	var progress_fill_style = StyleBoxFlat.new()
	progress_fill_style.bg_color = Color(0.3, 0.7, 1.0, 1.0)  # Blue
	progress_fill_style.set_corner_radius_all(1)
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
	# Get character portrait from dedicated portrait images
	if not CharacterManager:
		return

	var character_id = CharacterManager.selected_character_id
	if character_id == "":
		return

	# Load portrait texture from assets/sprites/portraits/
	var portrait_path = "res://assets/sprites/portraits/" + character_id + ".png"
	if ResourceLoader.exists(portrait_path):
		var texture = load(portrait_path) as Texture2D
		if texture:
			portrait_texture.texture = texture
			# Ensure full image is shown centered
			portrait_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			portrait_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Setup fire effect container for kill streaks
	_setup_fire_effect()

func _get_portrait_crop_settings(character_id: String) -> Dictionary:
	# Per-character crop settings to show face properly
	# start_y: how far down to start (0 = top of frame)
	# height: how much height to take
	# width: how much width to take (centered)
	match character_id:
		"archer":
			return {"start_y": 0.0, "height": 0.70, "width": 0.85}
		"knight":
			# Knight is 128x64 (wide), zoom in more on upper body
			return {"start_y": 0.0, "height": 0.95, "width": 0.45}
		"beast":
			# Beast is 128x128, zoom in on head/upper body
			return {"start_y": 0.0, "height": 0.50, "width": 0.55}
		"mage":
			return {"start_y": 0.0, "height": 0.70, "width": 0.85}
		"monk":
			# Monk is 96x96
			return {"start_y": 0.0, "height": 0.55, "width": 0.65}
		_:
			return {"start_y": 0.0, "height": 0.70, "width": 0.85}

var fire_update_timer: float = 0.0

func _process(delta: float) -> void:
	# Update shield display from AbilityManager (always update when transcendence is active)
	if AbilityManager and AbilityManager.has_transcendence:
		current_shield = AbilityManager.transcendence_shields
		max_shield = AbilityManager.transcendence_max
		_update_shield_display()

	# Update kill streak fire effect
	if KillStreakManager:
		var new_tier = KillStreakManager.get_current_tier()
		if new_tier != current_fire_tier:
			current_fire_tier = new_tier
			_update_fire_intensity()

		# Update fire particles at low framerate for pixelated look
		if current_fire_tier > 0:
			fire_update_timer += delta
			if fire_update_timer >= FIRE_UPDATE_RATE:
				fire_update_timer = 0.0
				_update_fire_particles()

	# Update low HP heartbeat animation on health bar
	_update_low_hp_heartbeat(delta)

func _on_health_changed(current: float, maximum: float) -> void:
	var health_changed = abs(current - previous_health) > 0.5
	previous_health = current
	current_health = current
	max_health = maximum
	_update_health_bar()

	# Update low HP state
	var health_ratio = current / maximum if maximum > 0 else 1.0
	var was_low_hp = low_hp_active
	low_hp_active = health_ratio <= 0.5 and health_ratio > 0

	# Reset heartbeat phase when entering/leaving low HP
	if low_hp_active != was_low_hp:
		heartbeat_phase = 0.0
		if not low_hp_active and health_bar_bg:
			# Reset bar to original state
			health_bar_bg.scale = health_bar_original_scale
			health_bar_bg.rotation = health_bar_original_rotation

	# Animate health bar on change (both bg and fill)
	if health_changed and health_bar_bg:
		_animate_bar_shake(health_bar_bg)
		_animate_bar_fill_shake(health_bar_fill)

func _update_health_bar() -> void:
	if health_bar_fill == null:
		return

	var ratio = clamp(current_health / max_health, 0.0, 1.0)
	var fill_width = (HEALTH_BAR_WIDTH - 4) * ratio
	health_bar_fill.size.x = fill_width

	# Update health bar color based on percentage (green > yellow > orange > red)
	var health_color: Color
	if current_shield > 0:
		health_color = Color(0.3, 0.5, 0.9, 1.0)  # Blue when shielded
	elif ratio > 0.5:
		health_color = Color(0.2, 0.8, 0.2, 1.0)  # Green
	elif ratio > 0.25:
		health_color = Color(0.9, 0.7, 0.1, 1.0)  # Yellow
	else:
		health_color = Color(0.9, 0.2, 0.2, 1.0)  # Red

	var style = health_bar_fill.get_theme_stylebox("panel").duplicate() as StyleBoxFlat
	style.bg_color = health_color
	health_bar_fill.add_theme_stylebox_override("panel", style)

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

func _update_shield_display() -> void:
	# Update shield bar only (for real-time regeneration display)
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

	# Check if XP increased (not level up reset)
	var xp_increased = current_xp > previous_xp and current_xp > 0

	# If XP decreased (level up reset), snap to new value
	if current_xp < displayed_xp:
		displayed_xp = current_xp
		previous_xp = current_xp
		_update_progress_bar(current_xp, xp_needed)
		return

	previous_xp = current_xp

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

	# Animate XP bar on gain (both bg and fill)
	if xp_increased and progress_bar_bg:
		_animate_bar_shake(progress_bar_bg)
		_animate_bar_fill_shake(progress_bar_fill)

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

# ============================================
# BAR ANIMATION (rotate + pulse like combo)
# ============================================

func _animate_bar_shake(bar: Panel) -> void:
	"""Rotating shake and pulse animation for HP/XP bar background."""
	if bar == null:
		return

	# Set pivot to center of bar
	bar.pivot_offset = bar.size / 2

	# Rotating shake animation
	var tween = create_tween()
	tween.set_parallel(true)

	# Pulse scale
	tween.tween_property(bar, "scale", Vector2(BAR_PULSE_SCALE, BAR_PULSE_SCALE), 0.06).set_ease(Tween.EASE_OUT)

	# Rotation shake
	tween.tween_property(bar, "rotation", BAR_SHAKE_AMOUNT, 0.04)

	tween.set_parallel(false)
	tween.tween_property(bar, "rotation", -BAR_SHAKE_AMOUNT * 0.7, 0.04)
	tween.tween_property(bar, "rotation", BAR_SHAKE_AMOUNT * 0.3, 0.03)
	tween.tween_property(bar, "rotation", BAR_BASE_ROTATION, 0.03)

	# Return scale to normal
	tween.tween_property(bar, "scale", Vector2(1.0, 1.0), 0.1).set_ease(Tween.EASE_OUT)

func _animate_bar_fill_shake(fill_bar: Panel) -> void:
	"""Smaller rotating shake and pulse for the fill bar inside."""
	if fill_bar == null:
		return

	# Set pivot to center of fill bar
	fill_bar.pivot_offset = fill_bar.size / 2

	# Slight delay to offset from bg animation
	var tween = create_tween()
	tween.tween_interval(0.02)

	tween.set_parallel(true)

	# Smaller pulse scale for fill
	tween.tween_property(fill_bar, "scale", Vector2(BAR_FILL_PULSE_SCALE, BAR_FILL_PULSE_SCALE), 0.05).set_ease(Tween.EASE_OUT)

	# Smaller rotation shake
	var fill_shake = BAR_SHAKE_AMOUNT * 0.5
	tween.tween_property(fill_bar, "rotation", fill_shake, 0.03)

	tween.set_parallel(false)
	tween.tween_property(fill_bar, "rotation", -fill_shake * 0.6, 0.03)
	tween.tween_property(fill_bar, "rotation", fill_shake * 0.2, 0.02)
	tween.tween_property(fill_bar, "rotation", BAR_BASE_ROTATION, 0.02)

	# Return scale to normal
	tween.tween_property(fill_bar, "scale", Vector2(1.0, 1.0), 0.08).set_ease(Tween.EASE_OUT)

# ============================================
# KILL STREAK FIRE EFFECT
# ============================================

# Fire colors per tier (more intense at higher tiers)
const FIRE_TIER_COLORS: Array[Array] = [
	[],  # Tier 0 - no fire
	[Color(1.0, 0.9, 0.3), Color(1.0, 0.6, 0.1), Color(1.0, 0.3, 0.0)],  # Tier 1 - Yellow/Orange
	[Color(1.0, 0.7, 0.2), Color(1.0, 0.4, 0.0), Color(0.9, 0.2, 0.0)],  # Tier 2 - Orange/Red
	[Color(1.0, 0.3, 0.1), Color(0.9, 0.1, 0.0), Color(0.6, 0.0, 0.0)],  # Tier 3 - Red
	[Color(0.9, 0.2, 0.9), Color(0.7, 0.1, 0.7), Color(0.4, 0.0, 0.4)],  # Tier 4 - Purple
	[Color(0.3, 0.8, 1.0), Color(0.2, 0.5, 1.0), Color(0.1, 0.2, 0.8)],  # Tier 5 - Cyan/Blue
	[Color(1.0, 0.95, 0.5), Color(1.0, 0.85, 0.2), Color(1.0, 0.7, 0.0)],  # Tier 6 - Gold
	[Color(1.0, 1.0, 1.0), Color(0.9, 0.9, 1.0), Color(0.8, 0.8, 1.0)],  # Tier 7 - White/Prismatic
]

func _setup_fire_effect() -> void:
	"""Create the container for fire particles ABOVE portrait (not on it)."""
	fire_container = Control.new()
	fire_container.name = "FireContainer"
	fire_container.size = Vector2(PORTRAIT_SIZE + 30, 50)  # Wide enough, height for flames above
	fire_container.position = Vector2(-15, -50)  # Position ABOVE the portrait
	fire_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fire_container.clip_contents = false
	portrait_button.add_child(fire_container)

	# Initialize fire particles (hidden initially)
	for i in range(FIRE_PARTICLE_COUNT):
		var particle = ColorRect.new()
		particle.name = "FireParticle" + str(i)
		particle.size = Vector2(6, 6)  # Pixelated square blocks
		particle.color = Color(1.0, 0.5, 0.0, 0.0)  # Start invisible
		particle.mouse_filter = Control.MOUSE_FILTER_IGNORE
		fire_container.add_child(particle)

		fire_particles.append({
			"node": particle,
			"x": randf_range(5, PORTRAIT_SIZE + 5),
			"y": float(PORTRAIT_SIZE),  # Start at bottom
			"speed": randf_range(40, 80),
			"wobble": randf_range(-1.0, 1.0),
			"lifetime": 0.0,
			"max_lifetime": randf_range(0.4, 0.8)
		})

func _update_fire_intensity() -> void:
	"""Update fire visibility and portrait border based on kill streak tier."""
	if fire_container == null:
		return

	if current_fire_tier <= 0:
		# Hide all fire particles
		for p in fire_particles:
			p["node"].color.a = 0.0
		# Reset portrait border to default
		_update_portrait_border(Color(0.4, 0.35, 0.3, 1.0))
	else:
		# Reset particles for new intensity
		for p in fire_particles:
			_reset_fire_particle(p)
		# Update portrait border to match fire tier color
		var tier_colors = FIRE_TIER_COLORS[min(current_fire_tier, FIRE_TIER_COLORS.size() - 1)]
		if tier_colors.size() > 0:
			_update_portrait_border(tier_colors[0])  # Use the brightest color

func _update_portrait_border(color: Color) -> void:
	"""Update the portrait background border color."""
	if portrait_bg == null:
		return
	var style = portrait_bg.get_theme_stylebox("panel")
	if style:
		style = style.duplicate()
		style.border_color = color
		portrait_bg.add_theme_stylebox_override("panel", style)

func _update_fire_particles() -> void:
	"""Update fire particle positions and colors (called at low framerate for pixelated look)."""
	if current_fire_tier <= 0 or fire_container == null:
		return

	var tier_colors = FIRE_TIER_COLORS[min(current_fire_tier, FIRE_TIER_COLORS.size() - 1)]
	if tier_colors.size() == 0:
		return

	for p in fire_particles:
		# Move particle upward
		p["y"] -= p["speed"] * FIRE_UPDATE_RATE
		p["x"] += p["wobble"] * 3.0  # Slight horizontal wobble
		p["lifetime"] += FIRE_UPDATE_RATE

		# Check if particle should reset
		if p["lifetime"] >= p["max_lifetime"] or p["y"] < -10:
			_reset_fire_particle(p)
			continue

		# Calculate color based on lifetime (hotter at bottom, cooler at top)
		var life_ratio = p["lifetime"] / p["max_lifetime"]
		var color_index = int(life_ratio * (tier_colors.size() - 1))
		color_index = clamp(color_index, 0, tier_colors.size() - 1)

		var base_color = tier_colors[color_index]

		# Fade out near end of lifetime
		var alpha = 1.0
		if life_ratio > 0.7:
			alpha = 1.0 - ((life_ratio - 0.7) / 0.3)

		# Higher tiers = more particles visible and brighter
		var tier_brightness = 0.6 + (current_fire_tier * 0.06)
		alpha *= tier_brightness

		p["node"].color = Color(base_color.r, base_color.g, base_color.b, alpha)

		# Snap position to grid for pixelated look (4px grid)
		var snapped_x = int(p["x"] / 4) * 4
		var snapped_y = int(p["y"] / 4) * 4
		p["node"].position = Vector2(snapped_x, snapped_y)

		# Vary particle size slightly based on tier
		var size_base = 5 + current_fire_tier
		var size_var = randi_range(-1, 1)
		p["node"].size = Vector2(size_base + size_var, size_base + size_var)

func _reset_fire_particle(p: Dictionary) -> void:
	"""Reset a fire particle to start position (at bottom of fire container, rises up)."""
	# Position along width of container (centered over portrait)
	var spawn_spread = PORTRAIT_SIZE * (0.4 + current_fire_tier * 0.08)
	var center_x = (PORTRAIT_SIZE + 30) / 2.0  # Center of fire container

	p["x"] = center_x + randf_range(-spawn_spread / 2, spawn_spread / 2)
	p["y"] = 45 + randf_range(-5, 5)  # Start at bottom of fire container (which is above portrait)
	p["speed"] = randf_range(40 + current_fire_tier * 8, 70 + current_fire_tier * 12)
	p["wobble"] = randf_range(-1.0, 1.0)
	p["lifetime"] = 0.0
	p["max_lifetime"] = randf_range(0.25, 0.5)

	# Start with base fire color
	var tier_colors = FIRE_TIER_COLORS[min(current_fire_tier, FIRE_TIER_COLORS.size() - 1)]
	if tier_colors.size() > 0:
		p["node"].color = tier_colors[0]
		p["node"].color.a = 0.8

# ============================================
# LOW HP HEARTBEAT ANIMATION
# ============================================

func _update_low_hp_heartbeat(delta: float) -> void:
	"""Pulse and rotate the health bar like a heartbeat when at 50% HP or below."""
	if not low_hp_active or health_bar_bg == null:
		return

	# Calculate heartbeat speed based on health (same as juice_manager vignette)
	# At 50% HP: moderate pulse (~0.7 beats per second)
	# At 10% HP: faster pulse (~2 beats per second)
	var health_ratio = current_health / max_health if max_health > 0 else 1.0
	var health_urgency = 1.0 - (health_ratio / 0.5)  # 0 at 50%, 1 at 0%
	health_urgency = clamp(health_urgency, 0.0, 1.0)
	var beats_per_second = lerp(0.7, 2.0, health_urgency)

	heartbeat_phase += delta * beats_per_second
	if heartbeat_phase >= 1.0:
		heartbeat_phase -= 1.0

	# Create heartbeat pattern: quick double-pulse (matching vignette)
	var pulse_intensity: float = 0.0
	if heartbeat_phase < 0.1:
		# First beat rise
		pulse_intensity = heartbeat_phase / 0.1
	elif heartbeat_phase < 0.2:
		# First beat fall
		pulse_intensity = 1.0 - (heartbeat_phase - 0.1) / 0.1
	elif heartbeat_phase < 0.3:
		# Second beat rise
		pulse_intensity = (heartbeat_phase - 0.2) / 0.1 * 0.7
	elif heartbeat_phase < 0.4:
		# Second beat fall
		pulse_intensity = 0.7 * (1.0 - (heartbeat_phase - 0.3) / 0.1)
	# Rest of the cycle: no pulse

	# Scale pulse intensity based on how low HP is
	var base_intensity = lerp(0.3, 0.8, health_urgency)
	var final_pulse = pulse_intensity * base_intensity

	# Apply scale pulse to health bar
	var scale_boost = 1.0 + (final_pulse * 0.08)  # Up to 8% scale boost
	health_bar_bg.scale = health_bar_original_scale * scale_boost

	# Apply subtle rotation wobble
	var rotation_amount = final_pulse * 0.02  # Up to ~1 degree rotation
	health_bar_bg.rotation = health_bar_original_rotation + rotation_amount
