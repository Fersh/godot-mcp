extends Node2D

# Elite/Boss Spawner - Spawns elite and boss enemies on a timer
# Alternates: Boss at 5m, Elite at 10m, Boss at 15m, etc.

@export var cyclops_scene: PackedScene
@export var minotaur_scene: PackedScene  # Boss

@export var spawn_interval: float = 150.0  # 2.5 minutes in seconds
@export var warning_duration: float = 3.0  # How long to show warning

# Arena bounds for spawn positioning
const ARENA_WIDTH = 1536
const ARENA_HEIGHT = 1382
const SPAWN_MARGIN = 100  # Spawn this far from edges

# Spawn state
var spawn_timer: float = 0.0
var warning_active: bool = false
var warning_timer: float = 0.0
var pending_spawn: bool = false
var spawn_count: int = 0  # Track how many spawns (0=boss, 1=elite, 2=boss...)

# Track active elites/bosses
var active_elites: Array[Node] = []
var active_boss: Node = null

# Notification UI
var elite_notification: CanvasLayer = null
var notification_label: Label = null

# Boss health bar UI
var boss_health_bar_container: CanvasLayer = null
var boss_health_bar: ProgressBar = null
var boss_name_label: Label = null

# Pixel font
var pixel_font: Font = null

# Available elite types (for future expansion)
enum EliteType { CYCLOPS }
enum BossType { MINOTAUR }
var elite_pool: Array[EliteType] = [EliteType.CYCLOPS]
var boss_pool: Array[BossType] = [BossType.MINOTAUR]

func _ready() -> void:
	_load_pixel_font()
	_setup_notification_ui()
	_setup_boss_health_bar()

func _load_pixel_font() -> void:
	pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")

func _process(delta: float) -> void:
	spawn_timer += delta

	# Handle warning phase
	if warning_active:
		warning_timer -= delta
		_update_notification_fade()
		if warning_timer <= 0:
			warning_active = false
			if pending_spawn:
				_do_spawn()
				pending_spawn = false

	# Check if it's time to spawn
	if spawn_timer >= spawn_interval and not warning_active:
		spawn_timer = 0.0
		_start_warning()

func _setup_notification_ui() -> void:
	elite_notification = CanvasLayer.new()
	elite_notification.layer = 100  # Above most UI
	add_child(elite_notification)

	# Create centered label
	notification_label = Label.new()
	notification_label.text = "ELITE INCOMING"
	notification_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	notification_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# Use pixel font - very bold and large
	if pixel_font:
		notification_label.add_theme_font_override("font", pixel_font)
	notification_label.add_theme_font_size_override("font_size", 48)
	notification_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15, 1.0))

	# Heavy shadow/outline for bold visibility
	notification_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1.0))
	notification_label.add_theme_constant_override("shadow_offset_x", 5)
	notification_label.add_theme_constant_override("shadow_offset_y", 5)

	# Add outline for extra boldness
	notification_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	notification_label.add_theme_constant_override("outline_size", 6)

	# Position at 33% from top (66% up the screen)
	notification_label.set_anchors_preset(Control.PRESET_TOP_WIDE)
	notification_label.anchor_top = 0.33
	notification_label.anchor_bottom = 0.33
	notification_label.offset_top = -30
	notification_label.offset_bottom = 30
	notification_label.grow_horizontal = Control.GROW_DIRECTION_BOTH

	elite_notification.add_child(notification_label)
	notification_label.visible = false

func _setup_boss_health_bar() -> void:
	boss_health_bar_container = CanvasLayer.new()
	boss_health_bar_container.layer = 50
	add_child(boss_health_bar_container)

	# Container for positioning at bottom
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_health_bar_container.add_child(container)

	# VBox for name + health bar
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	vbox.anchor_top = 0.92
	vbox.anchor_bottom = 0.98
	vbox.offset_left = 200
	vbox.offset_right = -200
	vbox.add_theme_constant_override("separation", 4)
	container.add_child(vbox)

	# Boss name label
	boss_name_label = Label.new()
	boss_name_label.text = "BULLSH*T"
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	if pixel_font:
		boss_name_label.add_theme_font_override("font", pixel_font)
	boss_name_label.add_theme_font_size_override("font_size", 16)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))
	boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
	vbox.add_child(boss_name_label)

	# Health bar
	boss_health_bar = ProgressBar.new()
	boss_health_bar.custom_minimum_size = Vector2(0, 24)
	boss_health_bar.max_value = 100
	boss_health_bar.value = 100
	boss_health_bar.show_percentage = false

	# Style the health bar - doubled border width, corner radius, darker border
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	bg_style.border_width_left = 6
	bg_style.border_width_right = 6
	bg_style.border_width_top = 6
	bg_style.border_width_bottom = 6
	bg_style.border_color = Color(0.4, 0.08, 0.08, 1.0)  # Darker border
	bg_style.corner_radius_top_left = 6
	bg_style.corner_radius_top_right = 6
	bg_style.corner_radius_bottom_left = 6
	bg_style.corner_radius_bottom_right = 6
	boss_health_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.15, 0.15, 1.0)
	fill_style.corner_radius_top_left = 3
	fill_style.corner_radius_top_right = 3
	fill_style.corner_radius_bottom_left = 3
	fill_style.corner_radius_bottom_right = 3
	boss_health_bar.add_theme_stylebox_override("fill", fill_style)

	vbox.add_child(boss_health_bar)

	# Hide initially
	boss_health_bar_container.visible = false

func _start_warning() -> void:
	warning_active = true
	warning_timer = warning_duration
	pending_spawn = true

	# Determine if boss or elite based on spawn count
	# Elite at 2.5m, 7.5m, 12.5m... (spawn 0, 2, 4...) - even counts
	# Boss at 5m, 10m, 15m... (spawn 1, 3, 5...) - odd counts
	var is_boss = (spawn_count % 2 == 1)

	# Set notification text
	if is_boss:
		notification_label.text = "BOSS INCOMING"
		notification_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	else:
		notification_label.text = "ELITE INCOMING"
		notification_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2, 1.0))

	# Show notification
	notification_label.visible = true
	notification_label.modulate.a = 1.0

	# Play warning sound if available
	if SoundManager and SoundManager.has_method("play_elite_warning"):
		SoundManager.play_elite_warning()

	# Screen shake for impact (bigger for boss)
	if JuiceManager:
		if is_boss:
			JuiceManager.shake_large()
		else:
			JuiceManager.shake_medium()

func _update_notification_fade() -> void:
	# Stay solid on screen, then fade out at the end
	var progress = 1.0 - (warning_timer / warning_duration)

	if progress < 0.8:
		# Stay fully visible - no pulsing or flashing
		notification_label.modulate.a = 1.0
		notification_label.scale = Vector2(1.0, 1.0)
	else:
		# Fade out in final 20%
		var fade_progress = (progress - 0.8) / 0.2
		notification_label.modulate.a = 1.0 - fade_progress
		notification_label.scale = Vector2(1.0, 1.0)

func _do_spawn() -> void:
	# Elite at 2.5m, 7.5m, 12.5m... (spawn 0, 2, 4...) - even counts
	# Boss at 5m, 10m, 15m... (spawn 1, 3, 5...) - odd counts
	var is_boss = (spawn_count % 2 == 1)
	spawn_count += 1

	if is_boss:
		_spawn_boss()
	else:
		_spawn_elite()

	notification_label.visible = false

func _spawn_boss() -> void:
	var boss_type = _select_boss_type()
	var scene = _get_scene_for_boss(boss_type)

	if scene == null:
		push_warning("EliteSpawner: No scene configured for boss type")
		return

	var boss = scene.instantiate()
	boss.global_position = _get_spawn_position()
	get_parent().add_child(boss)

	active_boss = boss

	# Connect to boss signals for health bar
	if boss.has_signal("boss_health_changed"):
		boss.boss_health_changed.connect(_on_boss_health_changed)
	if boss.has_signal("boss_died"):
		boss.boss_died.connect(_on_boss_died)

	# Update boss name on health bar
	if boss.has_method("get") and boss.get("display_name"):
		boss_name_label.text = boss.display_name

	# Show boss health bar
	boss_health_bar_container.visible = true
	boss_health_bar.value = 100

	# Screen shake on spawn
	if JuiceManager:
		JuiceManager.shake_large()

func _spawn_elite() -> void:
	var elite_type = _select_elite_type()
	var scene = _get_scene_for_elite(elite_type)

	if scene == null:
		push_warning("EliteSpawner: No scene configured for elite type")
		return

	var elite = scene.instantiate()
	elite.global_position = _get_spawn_position()
	get_parent().add_child(elite)

	active_elites.append(elite)

	# Screen shake on spawn
	if JuiceManager:
		JuiceManager.shake_large()

func _select_elite_type() -> EliteType:
	return EliteType.CYCLOPS

func _select_boss_type() -> BossType:
	return BossType.MINOTAUR

func _get_scene_for_elite(elite_type: EliteType) -> PackedScene:
	match elite_type:
		EliteType.CYCLOPS:
			return cyclops_scene
		_:
			return cyclops_scene

func _get_scene_for_boss(boss_type: BossType) -> PackedScene:
	match boss_type:
		BossType.MINOTAUR:
			return minotaur_scene
		_:
			return minotaur_scene

func _on_boss_health_changed(current: float, max_hp: float) -> void:
	if max_hp > 0:
		boss_health_bar.value = (current / max_hp) * 100.0

func _on_boss_died(_boss: Node) -> void:
	active_boss = null
	# Fade out health bar
	var tween = create_tween()
	tween.tween_property(boss_health_bar_container, "modulate:a", 0.0, 1.0)
	tween.tween_callback(func(): boss_health_bar_container.visible = false; boss_health_bar_container.modulate.a = 1.0)

func _get_spawn_position() -> Vector2:
	# Spawn at a random edge of the arena
	var edge = randi() % 4
	var pos: Vector2

	match edge:
		0:  # Top
			pos = Vector2(
				randf_range(SPAWN_MARGIN, ARENA_WIDTH - SPAWN_MARGIN),
				-SPAWN_MARGIN
			)
		1:  # Bottom
			pos = Vector2(
				randf_range(SPAWN_MARGIN, ARENA_WIDTH - SPAWN_MARGIN),
				ARENA_HEIGHT + SPAWN_MARGIN
			)
		2:  # Left
			pos = Vector2(
				-SPAWN_MARGIN,
				randf_range(SPAWN_MARGIN, ARENA_HEIGHT - SPAWN_MARGIN)
			)
		3:  # Right
			pos = Vector2(
				ARENA_WIDTH + SPAWN_MARGIN,
				randf_range(SPAWN_MARGIN, ARENA_HEIGHT - SPAWN_MARGIN)
			)

	return pos

func on_elite_killed(elite: Node) -> void:
	# Remove from tracking
	var idx = active_elites.find(elite)
	if idx >= 0:
		active_elites.remove_at(idx)

func get_active_elite_count() -> int:
	# Clean up any freed references
	active_elites = active_elites.filter(func(e): return is_instance_valid(e))
	return active_elites.size()

# Debug function to force spawn an elite
func debug_spawn_elite() -> void:
	_start_warning()
