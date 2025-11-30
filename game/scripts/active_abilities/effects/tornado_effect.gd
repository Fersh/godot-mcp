extends Node2D

# Tornado/Whirlwind effect - using Weapon sprite animation
# Used for whirlwind, bladestorm

var duration: float = 3.0
var radius: float = 100.0
var damage: float = 0.0
var damage_multiplier: float = 1.0
var _initialized: bool = false

# Visual components
var weapon_sprite: Sprite2D = null
var weapon_frames: Array[Texture2D] = []
var current_frame: int = 0
var frame_timer: float = 0.0
const FRAME_DURATION: float = 0.08  # Time per frame

func _ready() -> void:
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	if _initialized:
		return
	_initialized = true
	_setup_visuals()
	_start_duration_timer()

func _setup_visuals() -> void:
	# Load Weapon animation frames
	for i in range(1, 9):
		var frame_path = "res://assets/sprites/effects/40/Other/Weapon/weapon%02d.png" % i
		if ResourceLoader.exists(frame_path):
			weapon_frames.append(load(frame_path))

	# Create the sprite
	weapon_sprite = Sprite2D.new()
	weapon_sprite.z_index = 10
	if weapon_frames.size() > 0:
		weapon_sprite.texture = weapon_frames[0]

	# Scale based on radius
	var scale_factor = radius / 50.0
	weapon_sprite.scale = Vector2(scale_factor, scale_factor)

	add_child(weapon_sprite)

func _process(delta: float) -> void:
	if weapon_frames.size() == 0:
		return

	# Animate through frames
	frame_timer += delta
	if frame_timer >= FRAME_DURATION:
		frame_timer -= FRAME_DURATION
		current_frame = (current_frame + 1) % weapon_frames.size()
		weapon_sprite.texture = weapon_frames[current_frame]

func _start_duration_timer() -> void:
	get_tree().create_timer(duration).timeout.connect(_on_duration_finished)

func _on_duration_finished() -> void:
	var tween = create_tween()
	tween.tween_property(self, "modulate:a", 0.0, 0.3)
	tween.tween_callback(queue_free)

func setup(ability_duration: float, ability_radius: float, ability_damage: float, ability_multiplier: float = 1.0) -> void:
	duration = ability_duration
	radius = ability_radius
	damage = ability_damage
	damage_multiplier = ability_multiplier

	# If setup called before deferred init, trigger init now
	if not _initialized:
		_initialized = true
		_setup_visuals()
		_start_duration_timer()
	elif weapon_sprite:
		# Update scale if already initialized
		var scale_factor = radius / 50.0
		weapon_sprite.scale = Vector2(scale_factor, scale_factor)
