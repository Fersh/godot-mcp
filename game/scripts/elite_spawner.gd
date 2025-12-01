extends Node2D

# Elite/Boss Spawner - Spawns elite and boss enemies on a timer
# Alternates: Elite at 2.5m, Boss at 5m, Elite at 7.5m, Boss at 10m, etc.

@export var cyclops_scene: PackedScene
@export var goblin_king_scene: PackedScene
@export var minotaur_scene: PackedScene  # Boss

@export var spawn_interval: float = 150.0  # 2.5 minutes between spawns
@export var warning_duration: float = 3.0  # How long to show warning

# Arena bounds for spawn positioning (dynamic, set by procedural map)
var arena_bounds: Rect2 = Rect2(0, 0, 2500, 2500)
var ARENA_WIDTH: float = 2500
var ARENA_HEIGHT: float = 2500
var ARENA_LEFT: float = 0
var ARENA_RIGHT: float = 2500
var ARENA_TOP: float = 0
var ARENA_BOTTOM: float = 2500
const SPAWN_MARGIN = 100  # Spawn this far from edges

# Spawn state
var spawn_timer: float = 0.0
var warning_active: bool = false
var warning_timer: float = 0.0
var pending_spawn: bool = false
var spawn_count: int = 0  # Track how many spawns (0=boss, 1=elite, 2=boss...)

# Elite alternation tracking
# First 2 elites alternate (0=Cyclops, 1=GoblinKing or vice versa based on random start)
# Then 3rd is random, 4th is the other, and repeat
var elite_spawn_count: int = 0
var last_elite_type: int = -1  # -1=none, 0=Cyclops, 1=GoblinKing
var initial_elite_chosen: bool = false

# Scaling per spawn - each elite/boss is 15% stronger than the last
const ELITE_SCALING_PER_SPAWN: float = 0.15
const BOSS_SCALING_PER_SPAWN: float = 0.15
var total_elites_killed: int = 0  # Track for scaling
var total_bosses_killed: int = 0

# Track active elites/bosses
var active_elites: Array[Node] = []
var active_boss: Node = null

# Challenge mode integration
var is_challenge_mode: bool = false
var challenge_mode_spawning_paused: bool = false

# Signals for challenge mode
signal boss_killed_challenge()
signal elite_killed_challenge()

# Notification UI
var elite_notification: CanvasLayer = null
var notification_label: Label = null

# Boss health bar UI
var boss_health_bar_container: CanvasLayer = null
var boss_health_bar: ProgressBar = null
var boss_name_label: Label = null

# Elite health bar UI
var elite_health_bar_container: CanvasLayer = null
var elite_health_bar: ProgressBar = null
var elite_name_label: Label = null
var current_tracked_elite: Node = null

# Pixel font
var pixel_font: Font = null

# Available elite types
enum EliteType { CYCLOPS, GOBLIN_KING }
enum BossType { MINOTAUR }
var elite_pool: Array[EliteType] = [EliteType.CYCLOPS, EliteType.GOBLIN_KING]
var boss_pool: Array[BossType] = [BossType.MINOTAUR]

# Portal spawn system
var portal_script = preload("res://scripts/effects/elite_portal.gd")
var pending_elite_scene: PackedScene = null
var pending_boss_scene: PackedScene = null
var pending_scale_multiplier: float = 1.0
var pending_is_boss: bool = false

func _ready() -> void:
	_load_pixel_font()
	_setup_notification_ui()
	_setup_boss_health_bar()
	_setup_elite_health_bar()

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

	# In challenge mode, don't auto-spawn - controller handles timing
	if is_challenge_mode:
		return

	# Check if it's time to spawn (only in endless mode)
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
	notification_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input

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
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	boss_health_bar_container.add_child(container)

	# Health bar container positioned at bottom
	var bar_container = Control.new()
	bar_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	bar_container.anchor_top = 0.94
	bar_container.anchor_bottom = 0.98
	bar_container.offset_left = 200
	bar_container.offset_right = -200
	container.add_child(bar_container)

	# Health bar - taller with name inside
	boss_health_bar = ProgressBar.new()
	boss_health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	boss_health_bar.max_value = 100
	boss_health_bar.value = 100
	boss_health_bar.show_percentage = false
	boss_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input

	# Style the health bar - reduced border width (4px instead of 6px)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	bg_style.border_width_left = 4
	bg_style.border_width_right = 4
	bg_style.border_width_top = 4
	bg_style.border_width_bottom = 4
	bg_style.border_color = Color(0.5, 0.1, 0.1, 1.0)
	bg_style.set_corner_radius_all(2)  # Match HUD health bar
	boss_health_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.8, 0.15, 0.15, 1.0)
	fill_style.border_width_left = 4
	fill_style.border_width_top = 4
	fill_style.border_width_bottom = 4
	fill_style.border_width_right = 4
	fill_style.border_color = Color(0.5, 0.1, 0.1, 1.0)
	fill_style.set_corner_radius_all(1)  # Match HUD health bar fill
	boss_health_bar.add_theme_stylebox_override("fill", fill_style)

	bar_container.add_child(boss_health_bar)

	# Boss name label - centered inside the health bar
	boss_name_label = Label.new()
	boss_name_label.text = "BOSS"
	boss_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	boss_name_label.set_anchors_preset(Control.PRESET_CENTER)
	boss_name_label.anchor_left = 0.5
	boss_name_label.anchor_right = 0.5
	boss_name_label.anchor_top = 0.5
	boss_name_label.anchor_bottom = 0.5
	boss_name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	boss_name_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	boss_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	boss_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		boss_name_label.add_theme_font_override("font", pixel_font)
	boss_name_label.add_theme_font_size_override("font_size", 14)
	boss_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	boss_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	boss_name_label.add_theme_constant_override("shadow_offset_x", 2)
	boss_name_label.add_theme_constant_override("shadow_offset_y", 2)
	boss_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	boss_name_label.add_theme_constant_override("outline_size", 3)
	bar_container.add_child(boss_name_label)

	# Hide initially
	boss_health_bar_container.visible = false

func _setup_elite_health_bar() -> void:
	elite_health_bar_container = CanvasLayer.new()
	elite_health_bar_container.layer = 49  # Just below boss bar
	add_child(elite_health_bar_container)

	# Container for positioning at bottom (above boss bar position)
	var container = Control.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	elite_health_bar_container.add_child(container)

	# Health bar container positioned at bottom (slightly higher than boss)
	var bar_container = Control.new()
	bar_container.set_anchors_preset(Control.PRESET_BOTTOM_WIDE)
	bar_container.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	bar_container.anchor_top = 0.89
	bar_container.anchor_bottom = 0.93
	bar_container.offset_left = 250
	bar_container.offset_right = -250
	container.add_child(bar_container)

	# Health bar - taller with name inside
	elite_health_bar = ProgressBar.new()
	elite_health_bar.set_anchors_preset(Control.PRESET_FULL_RECT)
	elite_health_bar.max_value = 100
	elite_health_bar.value = 100
	elite_health_bar.show_percentage = false
	elite_health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input

	# Style the health bar - orange theme for elites, reduced border width (4px)
	var bg_style = StyleBoxFlat.new()
	bg_style.bg_color = Color(0.1, 0.1, 0.1, 0.9)
	bg_style.border_width_left = 4
	bg_style.border_width_right = 4
	bg_style.border_width_top = 4
	bg_style.border_width_bottom = 4
	bg_style.border_color = Color(0.5, 0.3, 0.1, 1.0)
	bg_style.set_corner_radius_all(2)  # Match HUD health bar
	elite_health_bar.add_theme_stylebox_override("background", bg_style)

	var fill_style = StyleBoxFlat.new()
	fill_style.bg_color = Color(0.9, 0.5, 0.1, 1.0)  # Orange for elites
	fill_style.border_width_left = 4
	fill_style.border_width_top = 4
	fill_style.border_width_bottom = 4
	fill_style.border_width_right = 4
	fill_style.border_color = Color(0.5, 0.3, 0.1, 1.0)
	fill_style.set_corner_radius_all(1)  # Match HUD health bar fill
	elite_health_bar.add_theme_stylebox_override("fill", fill_style)

	bar_container.add_child(elite_health_bar)

	# Elite name label - centered inside the health bar
	elite_name_label = Label.new()
	elite_name_label.text = "ELITE"
	elite_name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input
	elite_name_label.set_anchors_preset(Control.PRESET_CENTER)
	elite_name_label.anchor_left = 0.5
	elite_name_label.anchor_right = 0.5
	elite_name_label.anchor_top = 0.5
	elite_name_label.anchor_bottom = 0.5
	elite_name_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	elite_name_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	elite_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	elite_name_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if pixel_font:
		elite_name_label.add_theme_font_override("font", pixel_font)
	elite_name_label.add_theme_font_size_override("font_size", 12)
	elite_name_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
	elite_name_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	elite_name_label.add_theme_constant_override("shadow_offset_x", 2)
	elite_name_label.add_theme_constant_override("shadow_offset_y", 2)
	elite_name_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1.0))
	elite_name_label.add_theme_constant_override("outline_size", 3)
	bar_container.add_child(elite_name_label)

	# Hide initially
	elite_health_bar_container.visible = false

func _start_warning() -> void:
	warning_active = true
	warning_timer = warning_duration
	pending_spawn = true

	# Determine if boss or elite based on spawn count
	# Elite at 2.5m, 7.5m, 12.5m... (spawn 0, 2, 4...) - even counts
	# Boss at 5m, 10m, 15m... (spawn 1, 3, 5...) - odd counts
	var is_boss = (spawn_count % 2 == 1)

	# Set notification text with more dramatic messages (#3)
	if is_boss:
		notification_label.text = "BOSS APPROACHES"
		notification_label.add_theme_color_override("font_color", Color(1.0, 0.15, 0.15, 1.0))
		notification_label.add_theme_font_size_override("font_size", 56)  # Bigger for boss
	else:
		notification_label.text = "ELITE INCOMING"
		notification_label.add_theme_color_override("font_color", Color(1.0, 0.5, 0.2, 1.0))
		notification_label.add_theme_font_size_override("font_size", 48)

	# Show notification with slam-in animation (#3)
	notification_label.visible = true
	notification_label.modulate.a = 1.0
	notification_label.scale = Vector2(2.0, 2.0)  # Start big
	notification_label.pivot_offset = notification_label.size / 2

	var slam_tween = create_tween()
	slam_tween.tween_property(notification_label, "scale", Vector2(1.0, 1.0), 0.2).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)

	# Play warning sound if available
	if SoundManager and SoundManager.has_method("play_elite_warning"):
		SoundManager.play_elite_warning()

	# Screen shake for impact (bigger for boss) with chromatic aberration (#3)
	if JuiceManager:
		if is_boss:
			JuiceManager.shake_large()
			JuiceManager.chromatic_pulse(0.8)
			JuiceManager.hitstop_small()
		else:
			JuiceManager.shake_medium()
			JuiceManager.chromatic_pulse(0.4)

	# Haptic feedback (#3)
	if HapticManager:
		if is_boss:
			HapticManager.heavy()
		else:
			HapticManager.medium()

	# Darken screen briefly for dramatic effect (#3)
	_flash_screen_dark(is_boss)

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

	# Store pending spawn info
	pending_boss_scene = scene
	pending_scale_multiplier = 1.0 + (total_bosses_killed * BOSS_SCALING_PER_SPAWN)
	pending_is_boss = true

	# Create portal at center
	var spawn_pos = _get_spawn_position()
	_spawn_portal(spawn_pos, true)

func _do_spawn_boss_from_portal(spawn_pos: Vector2) -> void:
	"""Actually spawn the boss after portal animation."""
	if pending_boss_scene == null:
		return

	var boss = pending_boss_scene.instantiate()
	boss.global_position = spawn_pos
	get_parent().add_child(boss)

	# Apply scaling based on previous bosses killed (15% per boss)
	if boss.has_method("apply_scaling"):
		boss.apply_scaling(pending_scale_multiplier)
	else:
		# Manual scaling fallback
		if "max_health" in boss:
			boss.max_health *= pending_scale_multiplier
			boss.current_health = boss.max_health
		if "attack_damage" in boss:
			boss.attack_damage *= pending_scale_multiplier

	active_boss = boss
	pending_boss_scene = null

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

	# Store pending spawn info
	pending_elite_scene = scene
	pending_scale_multiplier = 1.0 + (total_elites_killed * ELITE_SCALING_PER_SPAWN)
	pending_is_boss = false

	# Create portal at center
	var spawn_pos = _get_spawn_position()
	_spawn_portal(spawn_pos, false)

func _do_spawn_elite_from_portal(spawn_pos: Vector2) -> void:
	"""Actually spawn the elite after portal animation."""
	if pending_elite_scene == null:
		return

	var elite = pending_elite_scene.instantiate()
	elite.global_position = spawn_pos
	get_parent().add_child(elite)

	# Apply scaling based on previous elites killed (15% per elite)
	if elite.has_method("apply_scaling"):
		elite.apply_scaling(pending_scale_multiplier)
	else:
		# Manual scaling fallback
		if "max_health" in elite:
			elite.max_health *= pending_scale_multiplier
			elite.current_health = elite.max_health
		if "attack_damage" in elite:
			elite.attack_damage *= pending_scale_multiplier

	active_elites.append(elite)
	current_tracked_elite = elite
	pending_elite_scene = null

	# Connect to elite signals for health bar
	if elite.has_signal("elite_health_changed"):
		elite.elite_health_changed.connect(_on_elite_health_changed)
	if elite.has_signal("elite_died"):
		elite.elite_died.connect(_on_elite_died)

	# Update elite name on health bar
	if elite.get("elite_name"):
		elite_name_label.text = elite.elite_name

	# Show elite health bar
	elite_health_bar_container.visible = true
	elite_health_bar.value = 100

	# Screen shake on spawn
	if JuiceManager:
		JuiceManager.shake_large()

# ============================================
# PORTAL SPAWN SYSTEM
# ============================================

func _spawn_portal(spawn_pos: Vector2, is_boss: bool) -> void:
	"""Create a portal at the spawn position."""
	var portal = Node2D.new()
	portal.set_script(portal_script)
	portal.global_position = spawn_pos
	portal.name = "ElitePortal"

	# Longer idle for boss
	if is_boss:
		portal.set_idle_duration(0.8)
	else:
		portal.set_idle_duration(0.5)

	# Connect signals
	portal.spawn_ready.connect(_on_portal_spawn_ready.bind(spawn_pos, is_boss))

	get_parent().add_child(portal)

func _on_portal_spawn_ready(spawn_pos: Vector2, is_boss: bool) -> void:
	"""Called when the portal is ready for the entity to emerge."""
	if is_boss:
		_do_spawn_boss_from_portal(spawn_pos)
	else:
		_do_spawn_elite_from_portal(spawn_pos)

func _select_elite_type() -> EliteType:
	# Elite spawn pattern:
	# 1st elite: random (Cyclops or Goblin King)
	# 2nd elite: the other one
	# 3rd elite: random
	# 4th elite: the other one
	# ... and so on

	var selected_type: EliteType

	if elite_spawn_count == 0:
		# First elite: random choice
		selected_type = EliteType.CYCLOPS if randi() % 2 == 0 else EliteType.GOBLIN_KING
	elif elite_spawn_count == 1:
		# Second elite: must be the other one
		selected_type = EliteType.GOBLIN_KING if last_elite_type == EliteType.CYCLOPS else EliteType.CYCLOPS
	else:
		# From 3rd onwards: odd positions (2, 4, 6...) are random, even positions (3, 5, 7...) are the other
		# elite_spawn_count 2 = 3rd elite (random)
		# elite_spawn_count 3 = 4th elite (other)
		# elite_spawn_count 4 = 5th elite (random)
		# etc.
		var position_in_cycle = (elite_spawn_count - 2) % 2
		if position_in_cycle == 0:
			# Random choice
			selected_type = EliteType.CYCLOPS if randi() % 2 == 0 else EliteType.GOBLIN_KING
		else:
			# Must be the other one
			selected_type = EliteType.GOBLIN_KING if last_elite_type == EliteType.CYCLOPS else EliteType.CYCLOPS

	last_elite_type = selected_type
	elite_spawn_count += 1

	return selected_type

func _select_boss_type() -> BossType:
	return BossType.MINOTAUR

func _get_scene_for_elite(elite_type: EliteType) -> PackedScene:
	match elite_type:
		EliteType.CYCLOPS:
			return cyclops_scene
		EliteType.GOBLIN_KING:
			return goblin_king_scene
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
	total_bosses_killed += 1  # Track for scaling next boss
	# Hide health bar (CanvasLayer doesn't support modulate)
	boss_health_bar_container.visible = false
	# Emit signal for challenge mode controller
	if is_challenge_mode:
		boss_killed_challenge.emit()

func _on_elite_health_changed(current: float, max_hp: float) -> void:
	if max_hp > 0:
		elite_health_bar.value = (current / max_hp) * 100.0

func _on_elite_died(_elite: Node) -> void:
	current_tracked_elite = null
	total_elites_killed += 1  # Track for scaling next elite
	# Hide health bar
	elite_health_bar_container.visible = false
	# Emit signal for challenge mode controller
	if is_challenge_mode:
		elite_killed_challenge.emit()

func _get_spawn_position() -> Vector2:
	# Spawn at center of the arena
	var center_x = (ARENA_LEFT + ARENA_RIGHT) / 2.0
	var center_y = (ARENA_TOP + ARENA_BOTTOM) / 2.0
	return Vector2(center_x, center_y)

func set_arena_bounds(bounds: Rect2) -> void:
	"""Set the arena boundaries for elite/boss spawning."""
	arena_bounds = bounds
	ARENA_LEFT = bounds.position.x
	ARENA_TOP = bounds.position.y
	ARENA_RIGHT = bounds.end.x
	ARENA_BOTTOM = bounds.end.y
	ARENA_WIDTH = bounds.size.x
	ARENA_HEIGHT = bounds.size.y

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

# Screen darkening effect for dramatic elite/boss announcements (#3)
var dark_overlay: ColorRect = null

func _flash_screen_dark(is_boss: bool) -> void:
	"""Briefly darken the screen for dramatic effect."""
	if dark_overlay == null:
		# Create overlay if it doesn't exist
		var overlay_layer = CanvasLayer.new()
		overlay_layer.layer = 99
		add_child(overlay_layer)

		dark_overlay = ColorRect.new()
		dark_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
		dark_overlay.color = Color(0, 0, 0, 0)
		dark_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE  # Don't block input to UI below
		overlay_layer.add_child(dark_overlay)

	# Flash dark then fade back
	var intensity = 0.5 if is_boss else 0.3
	var tween = create_tween()
	tween.tween_property(dark_overlay, "color:a", intensity, 0.1)
	tween.tween_property(dark_overlay, "color:a", 0.0, 0.4)

# ============================================
# CHALLENGE MODE FUNCTIONS
# ============================================

func set_challenge_mode(enabled: bool) -> void:
	"""Enable or disable challenge mode (disables auto-spawning)."""
	is_challenge_mode = enabled

func force_spawn_elite() -> void:
	"""Force spawn an elite immediately (for challenge mode milestones)."""
	# Temporarily set spawn_count to an even number to ensure elite spawns
	var original_count = spawn_count
	if spawn_count % 2 == 1:
		spawn_count = spawn_count - 1
	_start_warning()
	# Note: spawn_count will be incremented by _do_spawn

func force_spawn_boss() -> void:
	"""Force spawn a boss immediately (for challenge mode final boss)."""
	# Temporarily set spawn_count to an odd number to ensure boss spawns
	if spawn_count % 2 == 0:
		spawn_count = spawn_count + 1
	_start_warning()
	# Note: spawn_count will be incremented by _do_spawn

func is_boss_alive() -> bool:
	"""Check if there's currently an active boss."""
	return active_boss != null and is_instance_valid(active_boss)

func get_active_enemies_count() -> int:
	"""Get the total count of active elite enemies and boss."""
	var count = 0
	active_elites = active_elites.filter(func(e): return is_instance_valid(e))
	count += active_elites.size()
	if is_boss_alive():
		count += 1
	return count
