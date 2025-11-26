extends Node2D

# Elite Spawner - Spawns elite enemies on a timer
# Currently spawns Cyclops every 2.5 minutes
# Designed to be modular for future elite types

@export var cyclops_scene: PackedScene
# Add future elite scenes here:
# @export var minotaur_scene: PackedScene
# @export var dragon_scene: PackedScene

@export var spawn_interval: float = 150.0  # 2.5 minutes in seconds
@export var warning_duration: float = 3.0  # How long to show "ELITE INCOMING"

# Arena bounds for spawn positioning
const ARENA_WIDTH = 1536
const ARENA_HEIGHT = 1382
const SPAWN_MARGIN = 100  # Spawn this far from edges

# Spawn state
var spawn_timer: float = 0.0
var warning_active: bool = false
var warning_timer: float = 0.0
var pending_spawn: bool = false

# Track active elites
var active_elites: Array[Node] = []

# Elite notification UI
var elite_notification: CanvasLayer = null
var notification_label: Label = null

# Available elite types (for future expansion)
enum EliteType { CYCLOPS }  # Add more as needed
var elite_pool: Array[EliteType] = [EliteType.CYCLOPS]

func _ready() -> void:
	_setup_notification_ui()

func _process(delta: float) -> void:
	spawn_timer += delta

	# Handle warning phase
	if warning_active:
		warning_timer -= delta
		_update_notification_fade()
		if warning_timer <= 0:
			warning_active = false
			if pending_spawn:
				_spawn_elite()
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

	# Style the label
	notification_label.add_theme_font_size_override("font_size", 64)
	notification_label.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))

	# Add shadow/outline for visibility
	notification_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	notification_label.add_theme_constant_override("shadow_offset_x", 3)
	notification_label.add_theme_constant_override("shadow_offset_y", 3)

	# Center on screen
	notification_label.set_anchors_preset(Control.PRESET_CENTER)
	notification_label.grow_horizontal = Control.GROW_DIRECTION_BOTH
	notification_label.grow_vertical = Control.GROW_DIRECTION_BOTH
	notification_label.size = Vector2(800, 100)
	notification_label.position = Vector2(-400, -50)

	elite_notification.add_child(notification_label)
	notification_label.visible = false

func _start_warning() -> void:
	warning_active = true
	warning_timer = warning_duration
	pending_spawn = true

	# Show notification
	notification_label.visible = true
	notification_label.modulate.a = 1.0

	# Play warning sound if available
	if SoundManager and SoundManager.has_method("play_elite_warning"):
		SoundManager.play_elite_warning()

	# Screen shake for impact
	if JuiceManager:
		JuiceManager.shake_medium()

func _update_notification_fade() -> void:
	# Pulse effect then fade out
	var progress = 1.0 - (warning_timer / warning_duration)

	if progress < 0.7:
		# Pulsing phase
		var pulse = 0.8 + sin(progress * 20.0) * 0.2
		notification_label.modulate.a = pulse
		# Scale pulse
		var scale_pulse = 1.0 + sin(progress * 15.0) * 0.05
		notification_label.scale = Vector2(scale_pulse, scale_pulse)
	else:
		# Fade out phase
		var fade_progress = (progress - 0.7) / 0.3
		notification_label.modulate.a = 1.0 - fade_progress
		notification_label.scale = Vector2(1.0, 1.0)

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

	notification_label.visible = false

func _select_elite_type() -> EliteType:
	# For now, just return Cyclops
	# Future: weighted random selection based on game time, player level, etc.
	return EliteType.CYCLOPS

func _get_scene_for_elite(elite_type: EliteType) -> PackedScene:
	match elite_type:
		EliteType.CYCLOPS:
			return cyclops_scene
		_:
			return cyclops_scene

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
