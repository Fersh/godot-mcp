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

# Damage flash
var damage_flash_intensity: float = 0.0
var damage_flash_decay: float = 6.0

# Low HP pulse
var low_hp_active: bool = false
var low_hp_ratio: float = 1.0
var heartbeat_timer: float = 0.0
var heartbeat_phase: float = 0.0  # 0 to 1 for one full beat

# References
var camera: Camera2D = null
var vignette_overlay: ColorRect = null
var chromatic_overlay: ColorRect = null
var damage_flash_overlay: ColorRect = null
var low_hp_overlay: ColorRect = null
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

	# Update damage flash
	if damage_flash_intensity > 0:
		damage_flash_intensity = lerp(damage_flash_intensity, 0.0, damage_flash_decay * delta)
		if damage_flash_overlay and damage_flash_overlay.material:
			damage_flash_overlay.material.set_shader_parameter("intensity", damage_flash_intensity)
		if damage_flash_intensity < 0.01:
			damage_flash_intensity = 0.0

	# Update low HP heartbeat pulse
	if low_hp_active and low_hp_overlay and low_hp_overlay.material:
		# Calculate heartbeat speed based on health
		# At 50% HP: slow pulse (1 beat per 3 seconds)
		# At 10% HP: faster pulse (1.75 beats per second)
		var health_urgency = 1.0 - (low_hp_ratio / 0.5)  # 0 at 50%, 1 at 0%
		health_urgency = clamp(health_urgency, 0.0, 1.0)
		var beats_per_second = lerp(0.35, 1.75, health_urgency)

		heartbeat_phase += delta * beats_per_second
		if heartbeat_phase >= 1.0:
			heartbeat_phase -= 1.0

		# Create heartbeat pattern: quick double-pulse
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

		# Scale intensity based on how low HP is (more intense at lower HP)
		var base_intensity = lerp(0.15, 0.5, health_urgency)
		low_hp_overlay.material.set_shader_parameter("intensity", pulse_intensity * base_intensity)
	elif low_hp_overlay and low_hp_overlay.material:
		low_hp_overlay.material.set_shader_parameter("intensity", 0.0)

func register_camera(cam: Camera2D) -> void:
	camera = cam
	original_camera_offset = cam.offset

func register_vignette(overlay: ColorRect) -> void:
	vignette_overlay = overlay

func register_chromatic(overlay: ColorRect) -> void:
	chromatic_overlay = overlay

func register_damage_flash(overlay: ColorRect) -> void:
	damage_flash_overlay = overlay

func register_low_hp_vignette(overlay: ColorRect) -> void:
	low_hp_overlay = overlay

# Screen shake with optional rotation
func shake(intensity: float, rotation: float = 0.0) -> void:
	# Check if screen shake is enabled
	if GameSettings and not GameSettings.screen_shake_enabled:
		return
	shake_intensity = max(shake_intensity, intensity)
	shake_rotation = max(shake_rotation, rotation)

# Tiny shake for critical hits
func shake_crit() -> void:
	shake(2.0, 0.005)

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

# Micro hitstop for hits (1 frame at 60fps)
func hitstop_micro() -> void:
	hitstop(0.016)

# Short hitstop for significant events
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

# Trigger damage flash (red vignette)
func damage_flash(intensity: float = 0.7) -> void:
	damage_flash_intensity = intensity

# Update player health for low HP vignette
func update_player_health(health_ratio: float) -> void:
	low_hp_ratio = health_ratio
	low_hp_active = health_ratio <= 0.5 and health_ratio > 0

# Ultimate shake - massive epic shake for ultimate activation
func shake_ultimate() -> void:
	shake(20.0, 0.06)
