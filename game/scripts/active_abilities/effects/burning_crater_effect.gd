extends Node2D

# Burning Crater Effect - T2 Crater Ground Slam
# Persistent fiery/ashy ground effect with pixelated flames

var radius: float = 120.0
var duration: float = 4.0
var damage_per_tick: float = 10.0
var pixel_size: int = 4

var _time: float = 0.0
var _crater_pixels: Array[Dictionary] = []
var _embers: Array[Dictionary] = []
var _flames: Array[Dictionary] = []
var _ash_cracks: Array[Dictionary] = []

# Fire/Lava colors - reds, oranges, dark burnt
const CRATER_COLOR_HOT = Color(0.9, 0.3, 0.1, 0.85)  # Hot orange-red
const CRATER_COLOR_COOL = Color(0.3, 0.15, 0.1, 0.7)  # Cooled dark red/brown
const ASH_COLOR = Color(0.2, 0.18, 0.15, 0.8)  # Dark ash
const EMBER_COLOR = Color(1.0, 0.6, 0.2, 1.0)  # Bright orange embers
const FLAME_COLOR_BASE = Color(1.0, 0.4, 0.1, 0.9)  # Orange flame base
const FLAME_COLOR_TIP = Color(1.0, 0.85, 0.3, 0.7)  # Yellow flame tip

var _player_ref: Node2D = null
var _damage_timer: float = 0.0

func _ready() -> void:
	z_index = -1  # Draw below entities
	_generate_crater()
	_generate_embers()
	_generate_flames()
	_generate_ash_cracks()

	var tween = create_tween()
	tween.tween_property(self, "_time", 1.0, duration)
	tween.tween_callback(queue_free)

func setup(p_damage: float, p_radius: float, p_duration: float) -> void:
	damage_per_tick = p_damage
	radius = p_radius
	duration = p_duration

func _generate_crater() -> void:
	# Fill crater with pixelated lava/burnt ground
	var pixel_radius = int(radius / pixel_size)
	for x in range(-pixel_radius, pixel_radius + 1):
		for y in range(-pixel_radius, pixel_radius + 1):
			var pos = Vector2(x, y) * pixel_size
			var dist = pos.length()
			if dist < radius:
				var heat = 1.0 - (dist / radius)  # Hotter in center
				heat = pow(heat, 0.7)  # Adjust falloff
				# Add some noise
				heat += randf_range(-0.15, 0.15)
				heat = clamp(heat, 0.0, 1.0)

				_crater_pixels.append({
					"pos": pos,
					"base_heat": heat,
					"noise_offset": randf() * TAU
				})

func _generate_embers() -> void:
	var ember_count = randi_range(30, 50)
	for i in range(ember_count):
		var angle = randf() * TAU
		var dist = randf_range(10.0, radius * 0.9)
		_embers.append({
			"base_pos": Vector2.from_angle(angle) * dist,
			"size": randi_range(2, 4),
			"speed": randf_range(15.0, 40.0),
			"lifetime": randf_range(0.5, 1.5),
			"phase": randf() * TAU,
			"spawn_time": randf()
		})

func _generate_flames() -> void:
	# Concentrated flames near center
	var flame_count = randi_range(15, 25)
	for i in range(flame_count):
		var angle = randf() * TAU
		var dist = randf_range(5.0, radius * 0.6)
		_flames.append({
			"pos": Vector2.from_angle(angle) * dist,
			"height": randf_range(20.0, 45.0),
			"width": randf_range(8.0, 16.0),
			"phase": randf() * TAU,
			"speed": randf_range(3.0, 6.0)
		})

func _generate_ash_cracks() -> void:
	var crack_count = randi_range(8, 14)
	for i in range(crack_count):
		var angle = (TAU / crack_count) * i + randf_range(-0.2, 0.2)
		var segments: Array[Vector2] = []
		var current_pos = Vector2.ZERO
		var length = radius * randf_range(0.6, 0.95)

		while current_pos.length() < length:
			angle += randf_range(-0.3, 0.3)
			current_pos += Vector2.from_angle(angle) * randf_range(10.0, 18.0)
			segments.append(current_pos)

		_ash_cracks.append({"segments": segments})

func _process(delta: float) -> void:
	_damage_timer += delta
	if _damage_timer >= 0.5:  # Damage every 0.5s
		_damage_timer = 0.0
		_deal_damage()

	queue_redraw()

func _deal_damage() -> void:
	# Find enemies in crater
	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage_per_tick)
				elif enemy.has_method("apply_damage"):
					enemy.apply_damage(damage_per_tick)

func _draw() -> void:
	var fade = 1.0 - pow(_time, 2.0)  # Slow fade, accelerate at end

	# Draw crater base
	_draw_crater(fade)

	# Draw ash cracks (glowing)
	_draw_ash_cracks(fade)

	# Draw flames
	_draw_flames(fade)

	# Draw floating embers
	_draw_embers(fade)

func _draw_crater(fade: float) -> void:
	var time_pulse = sin(_time * TAU * 2.0) * 0.1 + 0.9  # Subtle pulse

	for pixel in _crater_pixels:
		var pos: Vector2 = pixel.pos
		var heat: float = pixel.base_heat

		# Animate heat with time
		heat *= time_pulse
		heat *= fade

		# Interpolate color based on heat
		var color: Color
		if heat > 0.5:
			color = CRATER_COLOR_COOL.lerp(CRATER_COLOR_HOT, (heat - 0.5) * 2.0)
		else:
			color = ASH_COLOR.lerp(CRATER_COLOR_COOL, heat * 2.0)

		color.a *= fade

		_draw_pixel_rect(pos, pixel_size, color)

func _draw_ash_cracks(fade: float) -> void:
	var glow_pulse = sin(_time * TAU * 3.0) * 0.3 + 0.7

	for crack in _ash_cracks:
		var segments: Array = crack.segments
		var prev_pos = Vector2.ZERO

		for seg_pos in segments:
			# Glowing hot cracks
			var color = CRATER_COLOR_HOT
			color.a = glow_pulse * fade * 0.9
			_draw_pixel_line(prev_pos, seg_pos, pixel_size + 1, color)
			prev_pos = seg_pos

func _draw_flames(fade: float) -> void:
	var anim_time = _time * duration * 2.0  # Animation cycles

	for flame in _flames:
		var pos: Vector2 = flame.pos
		var height: float = flame.height * fade
		var width: float = flame.width

		# Flickering animation
		var flicker = sin(anim_time * flame.speed + flame.phase) * 0.3 + 0.7
		height *= flicker

		# Draw pixelated flame (stack of shrinking rectangles)
		var segments = int(height / pixel_size)
		for i in range(segments):
			var t = float(i) / max(segments - 1, 1)
			var seg_width = width * (1.0 - t * 0.7)  # Narrower at top
			var seg_y = -i * pixel_size

			var color = FLAME_COLOR_BASE.lerp(FLAME_COLOR_TIP, t)
			color.a *= fade * flicker

			# Offset for flickering
			var x_offset = sin(anim_time * 5.0 + flame.phase + i * 0.5) * 3.0

			var seg_pos = pos + Vector2(x_offset, seg_y)

			for px in range(-int(seg_width / pixel_size / 2), int(seg_width / pixel_size / 2) + 1):
				_draw_pixel_rect(seg_pos + Vector2(px * pixel_size, 0), pixel_size, color)

func _draw_embers(fade: float) -> void:
	var anim_time = _time * duration

	for ember in _embers:
		# Cycle embers
		var ember_time = fmod(anim_time + ember.spawn_time * ember.lifetime, ember.lifetime) / ember.lifetime

		var pos: Vector2 = ember.base_pos
		# Rise upward
		pos.y -= ember_time * ember.speed * 2.0
		# Slight horizontal drift
		pos.x += sin(anim_time * 3.0 + ember.phase) * 8.0

		var alpha = sin(ember_time * PI) * fade  # Fade in and out
		var color = EMBER_COLOR
		color.a = alpha

		# Embers glow brighter sometimes
		if randf() < 0.1:
			color = color.lightened(0.3)

		_draw_pixel_rect(pos, ember.size * pixel_size, color)

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
