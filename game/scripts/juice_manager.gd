extends Node

# Juice Manager - Handles all game feel effects
# Add to autoload as "JuiceManager"

# Screen shake
var shake_intensity: float = 0.0
var shake_rotation: float = 0.0
var shake_decay: float = 8.0

# Hit stop
var hitstop_timer: float = 0.0
var original_time_scale: float = 1.0

# Chromatic aberration
var chromatic_intensity: float = 0.0
var chromatic_decay: float = 5.0

# References
var camera: Camera2D = null
var vignette_overlay: ColorRect = null
var chromatic_overlay: ColorRect = null
var original_camera_offset: Vector2 = Vector2.ZERO

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

func _process(delta: float) -> void:
	# Handle hit stop
	if hitstop_timer > 0:
		hitstop_timer -= delta
		if hitstop_timer <= 0:
			Engine.time_scale = original_time_scale

	# Only process visual effects when not paused
	if get_tree().paused:
		return

	# Update screen shake
	if shake_intensity > 0:
		shake_intensity = lerp(shake_intensity, 0.0, shake_decay * delta)
		shake_rotation = lerp(shake_rotation, 0.0, shake_decay * delta)

		if camera:
			var shake_offset = Vector2(
				randf_range(-shake_intensity, shake_intensity),
				randf_range(-shake_intensity, shake_intensity)
			)
			camera.offset = original_camera_offset + shake_offset
			camera.rotation = randf_range(-shake_rotation, shake_rotation)

		# Chromatic aberration during shake
		if chromatic_overlay and chromatic_overlay.material:
			chromatic_overlay.material.set_shader_parameter("intensity", shake_intensity * 0.003)
	else:
		if camera:
			camera.offset = original_camera_offset
			camera.rotation = 0.0
		if chromatic_overlay and chromatic_overlay.material:
			chromatic_overlay.material.set_shader_parameter("intensity", 0.0)

	# Decay chromatic aberration
	if chromatic_intensity > 0:
		chromatic_intensity = lerp(chromatic_intensity, 0.0, chromatic_decay * delta)

func register_camera(cam: Camera2D) -> void:
	camera = cam
	original_camera_offset = cam.offset

func register_vignette(overlay: ColorRect) -> void:
	vignette_overlay = overlay

func register_chromatic(overlay: ColorRect) -> void:
	chromatic_overlay = overlay

# Screen shake with optional rotation
func shake(intensity: float, rotation: float = 0.0) -> void:
	shake_intensity = max(shake_intensity, intensity)
	shake_rotation = max(shake_rotation, rotation)

# Small shake for regular hits
func shake_small() -> void:
	shake(3.0, 0.01)

# Medium shake for kills
func shake_medium() -> void:
	shake(6.0, 0.02)

# Large shake for big events
func shake_large() -> void:
	shake(12.0, 0.04)

# Hit stop - freeze game for a moment
func hitstop(duration: float = 0.05) -> void:
	if hitstop_timer <= 0:
		original_time_scale = Engine.time_scale
	hitstop_timer = duration
	Engine.time_scale = 0.05

# Short hitstop for regular hits
func hitstop_small() -> void:
	hitstop(0.03)

# Medium hitstop for kills
func hitstop_medium() -> void:
	hitstop(0.06)

# Large hitstop for big events
func hitstop_large() -> void:
	hitstop(0.1)

# Trigger chromatic aberration
func chromatic_pulse(intensity: float = 1.0) -> void:
	chromatic_intensity = intensity
