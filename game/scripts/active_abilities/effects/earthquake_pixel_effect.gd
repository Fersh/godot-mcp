extends Node2D

# Earthquake Pixel Effect - T3 Seismic Ground Slam of Cataclysm
# Screen-wide pixelated seismic devastation

var duration: float = 3.0
var earthquake_radius: float = 400.0
var earthquake_damage: float = 80.0
var stun_duration: float = 1.5
var pixel_size: int = 4

var damage_tick_interval: float = 0.5
var damage_tick_timer: float = 0.0
var total_ticks: int = 0
var is_active: bool = false
var _time: float = 0.0

# Cracks and fissures
var _major_fissures: Array[Dictionary] = []
var _rock_eruptions: Array[Dictionary] = []
var _dust_clouds: Array[Dictionary] = []
var _shockwaves: Array[Dictionary] = []
var shake_intensity: float = 8.0

# Colors - deeper, more dramatic earth tones
const FISSURE_COLOR = Color(0.12, 0.08, 0.05, 1.0)  # Very dark crack
const FISSURE_GLOW = Color(0.8, 0.4, 0.2, 0.7)  # Magma glow
const ROCK_COLOR = Color(0.35, 0.28, 0.2, 1.0)  # Brown rock
const DUST_COLOR = Color(0.55, 0.45, 0.35, 0.6)  # Tan dust
const WAVE_COLOR = Color(0.4, 0.3, 0.2, 0.5)  # Shockwave

func _ready() -> void:
	z_index = -2  # Below most things
	call_deferred("_start_earthquake")

func _start_earthquake() -> void:
	is_active = true
	_generate_major_fissures()
	_generate_rock_eruptions()
	_apply_initial_stun()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(_on_duration_finished)

func setup(damage: float, radius: float, effect_duration: float, stun_time: float) -> void:
	earthquake_damage = damage
	earthquake_radius = radius
	duration = effect_duration
	stun_duration = stun_time

func _generate_major_fissures() -> void:
	# Create major cracks radiating from center
	var fissure_count = randi_range(6, 10)
	for i in range(fissure_count):
		var angle = (TAU / fissure_count) * i + randf_range(-0.3, 0.3)
		var segments: Array[Dictionary] = []
		var current_pos = Vector2.ZERO
		var length = earthquake_radius * randf_range(0.8, 1.2)
		var width = randf_range(6.0, 12.0)

		while current_pos.length() < length:
			var next_angle = angle + randf_range(-0.4, 0.4)
			var seg_length = randf_range(20.0, 40.0)
			var next_pos = current_pos + Vector2.from_angle(next_angle) * seg_length

			segments.append({
				"from": current_pos,
				"to": next_pos,
				"width": width * randf_range(0.7, 1.3)
			})
			current_pos = next_pos
			angle = next_angle

		_major_fissures.append({
			"segments": segments,
			"delay": randf_range(0.0, 0.3),
			"has_glow": randf() < 0.4  # Some fissures glow
		})

func _generate_rock_eruptions() -> void:
	var eruption_count = randi_range(40, 60)
	for i in range(eruption_count):
		var angle = randf() * TAU
		var dist = randf_range(20.0, earthquake_radius * 0.9)
		_rock_eruptions.append({
			"pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(3, 8),
			"height": randf_range(30.0, 80.0),
			"spawn_time": randf(),
			"duration": randf_range(0.3, 0.8)
		})

func _process(delta: float) -> void:
	if not is_active:
		return

	_apply_screen_shake()

	damage_tick_timer += delta
	if damage_tick_timer >= damage_tick_interval:
		damage_tick_timer = 0.0
		total_ticks += 1
		_apply_damage_tick()
		_spawn_shockwave()

	queue_redraw()

func _apply_initial_stun() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= earthquake_radius:
			if enemy.has_method("apply_stun"):
				enemy.apply_stun(stun_duration)
			elif enemy.has_method("stun"):
				enemy.stun(stun_duration)

func _apply_damage_tick() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var tick_damage = max(1.0, earthquake_damage * damage_tick_interval / duration * 2.0)

	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		var dist = global_position.distance_to(enemy.global_position)
		if dist <= earthquake_radius:
			if enemy.has_method("take_damage"):
				enemy.take_damage(tick_damage, false)
			if total_ticks % 2 == 0:
				if enemy.has_method("apply_stun"):
					enemy.apply_stun(0.3)

func _spawn_shockwave() -> void:
	_shockwaves.append({
		"start_time": _time,
		"radius": 0.0
	})

func _apply_screen_shake() -> void:
	var intensity = shake_intensity * (1.0 - _time * 0.5)  # Fade shake over time
	var camera = get_viewport().get_camera_2d()
	if camera and camera.has_method("add_shake"):
		camera.add_shake(intensity * 0.15)
	elif camera:
		camera.offset = Vector2(
			randf_range(-intensity, intensity),
			randf_range(-intensity, intensity)
		)

func _on_duration_finished() -> void:
	is_active = false

	var camera = get_viewport().get_camera_2d()
	if camera:
		var tween = create_tween()
		tween.tween_property(camera, "offset", Vector2.ZERO, 0.3)

	var fade_tween = create_tween()
	fade_tween.tween_property(self, "modulate:a", 0.0, 0.5)
	fade_tween.tween_callback(queue_free)

func _draw() -> void:
	var fade = 1.0 - pow(_time, 1.5)

	# Draw shockwaves
	_draw_shockwaves(fade)

	# Draw major fissures
	_draw_fissures(fade)

	# Draw rock eruptions
	_draw_eruptions(fade)

	# Draw dust clouds
	_draw_dust(fade)

func _draw_shockwaves(fade: float) -> void:
	var to_remove: Array[int] = []

	for i in range(_shockwaves.size()):
		var wave = _shockwaves[i]
		var wave_age = _time - wave.start_time
		var wave_progress = wave_age * 3.0  # Expand over ~0.33s of effect time

		if wave_progress > 1.0:
			to_remove.append(i)
			continue

		var wave_radius = earthquake_radius * wave_progress
		var wave_alpha = (1.0 - wave_progress) * 0.5 * fade

		var color = WAVE_COLOR
		color.a = wave_alpha

		# Draw pixelated ring
		var segments = int(wave_radius * 0.3)
		segments = max(segments, 24)
		for j in range(segments):
			var angle = (TAU / segments) * j
			var pos = Vector2.from_angle(angle) * wave_radius
			_draw_pixel_rect(pos, pixel_size * 3, color)

	# Remove completed waves (in reverse order)
	for i in range(to_remove.size() - 1, -1, -1):
		_shockwaves.remove_at(to_remove[i])

func _draw_fissures(fade: float) -> void:
	var anim_time = _time * duration

	for fissure in _major_fissures:
		var fissure_progress = clamp((_time - fissure.delay) * 2.0, 0.0, 1.0)
		if fissure_progress <= 0:
			continue

		var segments: Array = fissure.segments
		var visible_count = int(segments.size() * fissure_progress)

		for j in range(visible_count):
			var seg: Dictionary = segments[j]

			# Draw dark fissure line
			var color = FISSURE_COLOR
			color.a = fade
			_draw_pixel_line(seg.from, seg.to, int(seg.width), color)

			# Draw glow if this fissure has it
			if fissure.has_glow:
				var glow_pulse = sin(anim_time * 4.0 + j * 0.5) * 0.3 + 0.7
				var glow_color = FISSURE_GLOW
				glow_color.a = fade * glow_pulse * 0.6
				_draw_pixel_line(seg.from, seg.to, int(seg.width * 0.6), glow_color)

func _draw_eruptions(fade: float) -> void:
	var anim_time = _time * duration

	for rock in _rock_eruptions:
		var rock_time = fmod(anim_time + rock.spawn_time, rock.duration) / rock.duration

		var pos: Vector2 = rock.pos
		# Parabolic arc
		var height = sin(rock_time * PI) * rock.height
		pos.y -= height

		# Rotate slightly
		pos = pos.rotated(rock_time * 0.5)

		var alpha = sin(rock_time * PI) * fade
		var color = ROCK_COLOR
		color.a = alpha

		_draw_pixel_rect(pos, rock.size * pixel_size, color)

func _draw_dust(fade: float) -> void:
	var dust_alpha = fade * 0.4
	if dust_alpha <= 0.05:
		return

	# Procedural dust cloud
	var dust_count = 40
	for i in range(dust_count):
		var angle = (TAU / dust_count) * i + _time * 0.3
		var dist = earthquake_radius * (0.4 + sin(_time * 3.0 + i) * 0.3)
		var pos = Vector2.from_angle(angle) * dist
		pos.y -= _time * 30.0  # Rise

		var color = DUST_COLOR
		color.a = dust_alpha * randf_range(0.5, 1.0)

		_draw_pixel_rect(pos, randi_range(6, 14), color)

func _draw_pixel_rect(pos: Vector2, size: int, color: Color) -> void:
	var snapped_pos = Vector2(
		snapped(pos.x, pixel_size) - size * 0.5,
		snapped(pos.y, pixel_size) - size * 0.5
	)
	draw_rect(Rect2(snapped_pos, Vector2(size, size)), color)

func _draw_pixel_line(from: Vector2, to: Vector2, width: int, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps + 1):
		var t = float(i) / max(steps, 1)
		var pos = from.lerp(to, t)
		_draw_pixel_rect(pos, width, color)
