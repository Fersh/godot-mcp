extends CanvasModulate

# Day/Night Cycle System
# Transitions from day to night over 10 minutes, then back again (20 min full cycle)
# Characters and enemies remain visible during night (darkness applies below them)

const CYCLE_DURATION := 600.0  # 10 minutes per half-cycle (day->night or night->day)
const FULL_CYCLE := CYCLE_DURATION * 2.0  # 20 minutes for full day/night cycle

# Time of day phases (0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset)
var cycle_time := 0.5  # Start at noon (brightest)
var cycle_speed := 1.0 / FULL_CYCLE  # How much cycle_time advances per second

# Color palette for different times of day - brighter values so characters stand out
const COLOR_MIDNIGHT := Color(0.35, 0.35, 0.45, 1.0)  # Lighter night (was 0.15)
const COLOR_DAWN := Color(0.8, 0.65, 0.7, 1.0)  # Pink/purple dawn
const COLOR_SUNRISE := Color(1.0, 0.9, 0.8, 1.0)  # Warm golden sunrise
const COLOR_MORNING := Color(1.0, 0.98, 0.95, 1.0)  # Bright morning
const COLOR_NOON := Color(1.0, 1.0, 1.0, 1.0)  # Full bright
const COLOR_AFTERNOON := Color(1.0, 0.97, 0.9, 1.0)  # Slightly warm
const COLOR_SUNSET := Color(1.0, 0.8, 0.6, 1.0)  # Orange sunset
const COLOR_DUSK := Color(0.7, 0.55, 0.65, 1.0)  # Purple dusk
const COLOR_NIGHT := Color(0.4, 0.4, 0.5, 1.0)  # Lighter night blue (was 0.2)

# Torch light intensity based on time
var torch_intensity := 0.0
var torches: Array[Node] = []

# Ambient light for overall scene
var ambient_energy := 1.0

# Character brightness boost (makes characters lighter than environment at night)
const CHARACTER_BRIGHTNESS_BOOST := 0.4  # How much to counteract night darkness (0-1)

signal time_changed(time_of_day: float, is_night: bool)

func _ready() -> void:
	# Start with pure white (noon) - no darkening at game start
	color = Color.WHITE

	# Find all torches after a frame
	await get_tree().process_frame
	_find_torches()

func _find_torches() -> void:
	torches.clear()
	var torch_nodes = get_tree().get_nodes_in_group("torches")
	for torch in torch_nodes:
		torches.append(torch)

func _process(delta: float) -> void:
	# Keep color at white - disable day/night cycle darkening
	color = Color.WHITE

	# Advance time (for torch flickering only)
	cycle_time += delta * cycle_speed
	if cycle_time >= 1.0:
		cycle_time -= 1.0

	# Calculate if it's night (for torch brightness only)
	var night_factor = _get_night_factor(cycle_time)
	torch_intensity = night_factor

	# Update torch lights
	_update_torch_lights(night_factor)

	# Skip character brightness modification - no longer needed with disabled cycle
	# _update_character_brightness(night_factor)

	# Emit signal for other systems
	emit_signal("time_changed", cycle_time, night_factor > 0.3)

func _get_sky_color(time: float) -> Color:
	# Time phases:
	# 0.00 - 0.10: Midnight (darkest)
	# 0.10 - 0.20: Dawn (getting lighter, pink tint)
	# 0.20 - 0.30: Sunrise (golden)
	# 0.30 - 0.45: Morning (bright, slightly warm)
	# 0.45 - 0.55: Noon (brightest)
	# 0.55 - 0.70: Afternoon (bright, warm)
	# 0.70 - 0.80: Sunset (orange)
	# 0.80 - 0.90: Dusk (purple)
	# 0.90 - 1.00: Night (dark blue)

	if time < 0.10:
		# Midnight
		return COLOR_MIDNIGHT
	elif time < 0.20:
		# Midnight -> Dawn
		var t = (time - 0.10) / 0.10
		return COLOR_MIDNIGHT.lerp(COLOR_DAWN, _smooth(t))
	elif time < 0.25:
		# Dawn -> Sunrise
		var t = (time - 0.20) / 0.05
		return COLOR_DAWN.lerp(COLOR_SUNRISE, _smooth(t))
	elif time < 0.35:
		# Sunrise -> Morning
		var t = (time - 0.25) / 0.10
		return COLOR_SUNRISE.lerp(COLOR_MORNING, _smooth(t))
	elif time < 0.45:
		# Morning -> Noon
		var t = (time - 0.35) / 0.10
		return COLOR_MORNING.lerp(COLOR_NOON, _smooth(t))
	elif time < 0.55:
		# Noon (brightest)
		return COLOR_NOON
	elif time < 0.65:
		# Noon -> Afternoon
		var t = (time - 0.55) / 0.10
		return COLOR_NOON.lerp(COLOR_AFTERNOON, _smooth(t))
	elif time < 0.75:
		# Afternoon -> Sunset
		var t = (time - 0.65) / 0.10
		return COLOR_AFTERNOON.lerp(COLOR_SUNSET, _smooth(t))
	elif time < 0.85:
		# Sunset -> Dusk
		var t = (time - 0.75) / 0.10
		return COLOR_SUNSET.lerp(COLOR_DUSK, _smooth(t))
	elif time < 0.95:
		# Dusk -> Night
		var t = (time - 0.85) / 0.10
		return COLOR_DUSK.lerp(COLOR_NIGHT, _smooth(t))
	else:
		# Night -> Midnight
		var t = (time - 0.95) / 0.05
		return COLOR_NIGHT.lerp(COLOR_MIDNIGHT, _smooth(t))

func _get_night_factor(time: float) -> float:
	# Returns 0.0 during day, 1.0 at midnight
	# Night is roughly 0.85 to 0.15 (wrapping around midnight)
	if time >= 0.85 or time <= 0.15:
		# Full night
		if time >= 0.95 or time <= 0.05:
			return 1.0  # Deepest night
		elif time >= 0.85:
			return (time - 0.85) / 0.10  # Transitioning to night
		else:
			return 1.0 - (time / 0.15)  # Transitioning to day
	elif time >= 0.75:
		# Dusk - getting darker
		return (time - 0.75) / 0.10 * 0.5
	elif time <= 0.25:
		# Dawn - still some darkness
		return (0.25 - time) / 0.10 * 0.3
	else:
		return 0.0  # Full day

func _update_torch_lights(night_factor: float) -> void:
	for torch in torches:
		if not is_instance_valid(torch):
			continue

		# Find or create the light
		var light = torch.get_node_or_null("PointLight2D")
		if light:
			# Scale energy based on night factor
			# Torches are dim during day, brighter at night (but not too bright)
			var base_energy = 0.15 + night_factor * 0.6
			# Add dynamic flicker using multiple sine waves
			var time_ms = Time.get_ticks_msec() * 0.001
			var torch_offset = float(torch.get_instance_id() % 1000) * 0.1
			var flicker = sin(time_ms * 8.0 + torch_offset) * 0.05
			flicker += sin(time_ms * 12.0 + torch_offset * 2.0) * 0.03
			flicker += sin(time_ms * 3.0 + torch_offset * 0.5) * 0.08
			light.energy = max(0.1, base_energy + flicker)
			# Also vary the scale slightly for more dynamic effect
			light.texture_scale = 2.5 + sin(time_ms * 5.0 + torch_offset) * 0.1
			light.enabled = night_factor > 0.1 or base_energy > 0.2

func _update_character_brightness(night_factor: float) -> void:
	# Make characters and enemies brighter than the environment during night
	# by giving them a brighter modulate to counteract the CanvasModulate darkness

	if night_factor <= 0.05:
		# During day, reset to normal
		_set_group_brightness("player", Color.WHITE)
		_set_group_brightness("enemies", Color.WHITE)
		return

	# Calculate brightness boost based on how dark it is
	# The darker the night, the more we boost character brightness
	var boost = 1.0 + (night_factor * CHARACTER_BRIGHTNESS_BOOST)
	var bright_color = Color(boost, boost, boost, 1.0)

	_set_group_brightness("player", bright_color)
	_set_group_brightness("enemies", bright_color)

func _set_group_brightness(group_name: String, mod_color: Color) -> void:
	var nodes = get_tree().get_nodes_in_group(group_name)
	for node in nodes:
		if is_instance_valid(node) and node is CanvasItem:
			# Only modify the self_modulate so it doesn't affect children unexpectedly
			node.self_modulate = mod_color

func _smooth(t: float) -> float:
	# Smoothstep for nice transitions
	return t * t * (3.0 - 2.0 * t)

# Public API
func get_time_of_day() -> float:
	return cycle_time

func is_night() -> bool:
	return _get_night_factor(cycle_time) > 0.3

func get_time_name() -> String:
	if cycle_time < 0.10:
		return "Midnight"
	elif cycle_time < 0.20:
		return "Dawn"
	elif cycle_time < 0.30:
		return "Sunrise"
	elif cycle_time < 0.45:
		return "Morning"
	elif cycle_time < 0.55:
		return "Noon"
	elif cycle_time < 0.70:
		return "Afternoon"
	elif cycle_time < 0.80:
		return "Sunset"
	elif cycle_time < 0.90:
		return "Dusk"
	else:
		return "Night"

# Debug: Set time manually (0.0 to 1.0)
func set_time(time: float) -> void:
	cycle_time = clamp(time, 0.0, 1.0)
