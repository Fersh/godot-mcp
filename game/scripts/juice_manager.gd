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
var original_camera_zoom: Vector2 = Vector2.ONE

# Zoom punch
var zoom_punch_tween: Tween = null

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

	# Extended processing for new features
	_process_extended(delta)

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
	else:
		if camera:
			camera.offset = original_camera_offset
			camera.rotation = 0.0

	# Decay and apply chromatic aberration (from both shake and pulse)
	if chromatic_intensity > 0:
		chromatic_intensity = lerp(chromatic_intensity, 0.0, chromatic_decay * delta)

	# Apply chromatic: use max of shake-based and pulse-based intensity
	if chromatic_overlay and chromatic_overlay.material:
		var shake_chromatic = shake_intensity * 0.003
		var total_chromatic = max(shake_chromatic, chromatic_intensity * 0.01)
		chromatic_overlay.material.set_shader_parameter("intensity", total_chromatic)

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
		# At 50% HP: moderate pulse (~1 beat per 1.5 seconds)
		# At 10% HP: faster pulse (2 beats per second)
		var health_urgency = 1.0 - (low_hp_ratio / 0.5)  # 0 at 50%, 1 at 0%
		health_urgency = clamp(health_urgency, 0.0, 1.0)
		var beats_per_second = lerp(0.7, 2.0, health_urgency)

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
		var base_intensity = lerp(0.35, 0.7, health_urgency)
		low_hp_overlay.material.set_shader_parameter("intensity", pulse_intensity * base_intensity)
	elif low_hp_overlay and low_hp_overlay.material:
		low_hp_overlay.material.set_shader_parameter("intensity", 0.0)

func register_camera(cam: Camera2D) -> void:
	camera = cam
	original_camera_offset = cam.offset
	original_camera_zoom = cam.zoom

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
	# Check if freeze frames are enabled in settings
	if GameSettings and not GameSettings.freeze_frames_enabled:
		return
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

# Zoom punch - brief zoom in then back out for impact
func zoom_punch(intensity: float = 0.02) -> void:
	# Check if visual effects are enabled in settings
	if GameSettings and not GameSettings.visual_effects_enabled:
		return
	if not camera:
		return

	# Kill any existing zoom tween
	if zoom_punch_tween and zoom_punch_tween.is_valid():
		zoom_punch_tween.kill()

	# Zoom in slightly (higher zoom value = more zoomed in)
	var punch_zoom = original_camera_zoom * (1.0 + intensity)
	camera.zoom = punch_zoom

	# Ease back to original
	zoom_punch_tween = create_tween()
	zoom_punch_tween.tween_property(camera, "zoom", original_camera_zoom, 0.1) \
		.set_trans(Tween.TRANS_QUAD) \
		.set_ease(Tween.EASE_OUT)

# Small zoom punch for regular hits
func zoom_punch_small() -> void:
	zoom_punch(0.015)

# Medium zoom punch for crits
func zoom_punch_medium() -> void:
	zoom_punch(0.03)

# Large zoom punch for kills
func zoom_punch_large() -> void:
	zoom_punch(0.05)

# Trigger chromatic aberration
func chromatic_pulse(intensity: float = 1.0) -> void:
	# Check if visual effects are enabled in settings
	if GameSettings and not GameSettings.visual_effects_enabled:
		return
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

# Level up shake - celebratory shake
func shake_levelup() -> void:
	shake(8.0, 0.025)

# Kill streak milestone shake
func shake_milestone(tier: int) -> void:
	var intensity = 4.0 + tier * 2.0
	var rotation_amt = 0.01 + tier * 0.005
	shake(intensity, rotation_amt)

# ============================================
# ENHANCED NEAR-DEATH SYSTEM (#11)
# ============================================

# Near death effects
var near_death_audio_active: bool = false
var heartbeat_sound_timer: float = 0.0
var near_death_shake_timer: float = 0.0

func update_near_death_audio(delta: float) -> void:
	if low_hp_active and low_hp_ratio <= 0.25:
		# Calculate urgency based on HP
		var health_urgency = 1.0 - (low_hp_ratio / 0.25)
		health_urgency = clamp(health_urgency, 0.0, 1.0)
		var beat_interval = lerp(1.2, 0.4, health_urgency)

		heartbeat_sound_timer -= delta
		if heartbeat_sound_timer <= 0:
			heartbeat_sound_timer = beat_interval
			# Haptic heartbeat pulse at very low HP
			if HapticManager and health_urgency > 0.5:
				HapticManager.light()

		# Subtle screen shake at critical HP (adds tension)
		near_death_shake_timer -= delta
		if near_death_shake_timer <= 0 and health_urgency > 0.7:
			near_death_shake_timer = randf_range(0.8, 1.5)
			shake(1.5, 0.005)  # Very subtle shake
	else:
		heartbeat_sound_timer = 0.0
		near_death_shake_timer = 0.0

# ============================================
# LEVEL UP CELEBRATION
# ============================================

var level_up_overlay: ColorRect = null

func register_level_up_overlay(overlay: ColorRect) -> void:
	level_up_overlay = overlay

func trigger_level_up_celebration() -> void:
	"""Epic level up celebration with multiple effects."""
	# Screen shake
	shake_levelup()

	# Chromatic pulse
	chromatic_pulse(0.8)

	# Brief hitstop for impact
	hitstop_small()

	# Haptic
	if HapticManager:
		HapticManager.level_up()

# ============================================
# PLAYER DAMAGE FREEZE
# ============================================

func player_damage_freeze() -> void:
	"""1-frame freeze when player takes damage for impact."""
	hitstop_micro()

# ============================================
# CRITICAL HIT EFFECTS
# ============================================

var crit_streak: int = 0
var crit_streak_timer: float = 0.0
const CRIT_STREAK_DECAY: float = 2.0

func register_crit() -> void:
	"""Track critical hit streaks for escalating effects."""
	crit_streak += 1
	crit_streak_timer = CRIT_STREAK_DECAY

	# Escalating effects based on crit streak
	if crit_streak >= 3:
		shake_small()
		chromatic_pulse(0.3)
	elif crit_streak >= 5:
		shake_medium()
		chromatic_pulse(0.5)

func update_crit_streak(delta: float) -> void:
	if crit_streak > 0:
		crit_streak_timer -= delta
		if crit_streak_timer <= 0:
			crit_streak = 0

func _process_extended(delta: float) -> void:
	"""Extended processing for new features."""
	update_crit_streak(delta)
	update_near_death_audio(delta)
