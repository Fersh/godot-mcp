extends CanvasModulate

# Day/Night Cycle System
# Transitions from day to night over 10 minutes, then back again (20 min full cycle)

const CYCLE_DURATION := 600.0  # 10 minutes per half-cycle (day->night or night->day)
const FULL_CYCLE := CYCLE_DURATION * 2.0  # 20 minutes for full day/night cycle

# Time of day phases (0.0 = midnight, 0.25 = sunrise, 0.5 = noon, 0.75 = sunset)
var cycle_time := 0.25  # Start at sunrise/early morning
var cycle_speed := 1.0 / FULL_CYCLE  # How much cycle_time advances per second

# Color palette for different times of day
const COLOR_MIDNIGHT := Color(0.15, 0.15, 0.25, 1.0)  # Deep blue night
const COLOR_DAWN := Color(0.7, 0.5, 0.6, 1.0)  # Pink/purple dawn
const COLOR_SUNRISE := Color(1.0, 0.85, 0.7, 1.0)  # Warm golden sunrise
const COLOR_MORNING := Color(1.0, 0.98, 0.95, 1.0)  # Bright morning
const COLOR_NOON := Color(1.0, 1.0, 1.0, 1.0)  # Full bright
const COLOR_AFTERNOON := Color(1.0, 0.97, 0.9, 1.0)  # Slightly warm
const COLOR_SUNSET := Color(1.0, 0.7, 0.5, 1.0)  # Orange sunset
const COLOR_DUSK := Color(0.6, 0.45, 0.55, 1.0)  # Purple dusk
const COLOR_NIGHT := Color(0.2, 0.2, 0.35, 1.0)  # Night blue

# Torch light intensity based on time
var torch_intensity := 0.0
var torches: Array[Node] = []

# Ambient light for overall scene
var ambient_energy := 1.0

signal time_changed(time_of_day: float, is_night: bool)

func _ready() -> void:
	# Start with morning color
	color = _get_sky_color(cycle_time)

	# Find all torches after a frame
	await get_tree().process_frame
	_find_torches()

func _find_torches() -> void:
	torches.clear()
	var torch_nodes = get_tree().get_nodes_in_group("torches")
	for torch in torch_nodes:
		torches.append(torch)

func _process(delta: float) -> void:
	# Advance time
	cycle_time += delta * cycle_speed
	if cycle_time >= 1.0:
		cycle_time -= 1.0

	# Update sky color
	color = _get_sky_color(cycle_time)

	# Calculate if it's night (for torch brightness)
	var night_factor = _get_night_factor(cycle_time)
	torch_intensity = night_factor

	# Update torch lights
	_update_torch_lights(night_factor)

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
			# Torches are dim during day, bright at night
			var base_energy = 0.3 + night_factor * 1.2
			# Add subtle flicker
			var flicker = sin(Time.get_ticks_msec() * 0.01 + torch.get_instance_id()) * 0.1
			light.energy = base_energy + flicker
			light.enabled = night_factor > 0.1 or base_energy > 0.4

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
