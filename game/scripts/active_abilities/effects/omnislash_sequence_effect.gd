extends Node2D

# Omnislash Sequence - Shows player zipping between enemies with anime slashes
# Creates the visual of a super fast character dashing through multiple enemies

var pixel_size := 4
var damage := 50.0
var hits_per_enemy := 3

# State
var player: Node2D = null
var targets: Array = []
var current_target_idx := 0
var player_start_pos := Vector2.ZERO

# Dash state
var is_dashing := false
var dash_from := Vector2.ZERO
var dash_to := Vector2.ZERO
var dash_progress := 0.0
var dash_speed := 2500.0  # Very fast!

# Timing
var hit_delay := 0.08  # Time between hits on same enemy
var current_hit := 0
var hit_timer := 0.0
var waiting_for_hits := false

# Visual trails
var dash_trails := []
var afterimages := []
var speed_lines := []

# Colors
const TRAIL_COLOR = Color(0.9, 0.95, 1.0, 0.8)
const AFTERIMAGE_COLOR = Color(0.5, 0.6, 0.9, 0.5)
const SPEED_LINE_COLOR = Color(1.0, 1.0, 1.0, 0.6)

# Preload anime slash scene
var anime_slash_scene: PackedScene = null

func _ready() -> void:
	anime_slash_scene = load("res://scenes/effects/ability_effects/anime_slash.tscn")

	# Auto-cleanup
	await get_tree().create_timer(10.0).timeout
	queue_free()

func setup(p_player: Node2D, p_targets: Array, p_damage: float, p_hits: int = 3) -> void:
	player = p_player
	damage = p_damage
	hits_per_enemy = p_hits

	if is_instance_valid(player):
		player_start_pos = player.global_position
		global_position = player_start_pos

	# Filter valid targets
	targets.clear()
	for t in p_targets:
		if is_instance_valid(t):
			targets.append(t)

	if targets.size() > 0:
		# Start the sequence!
		_start_dash_to_next()
	else:
		queue_free()

func _start_dash_to_next() -> void:
	if current_target_idx >= targets.size():
		# All done - return player to start or final position
		_finish_sequence()
		return

	var target = targets[current_target_idx]
	if not is_instance_valid(target):
		current_target_idx += 1
		_start_dash_to_next()
		return

	# Start dashing to this target
	if is_instance_valid(player):
		dash_from = player.global_position
	else:
		dash_from = global_position

	dash_to = target.global_position
	dash_progress = 0.0
	is_dashing = true
	current_hit = 0

	# Spawn afterimage at start position
	_spawn_afterimage(dash_from)

	# Spawn speed lines along path
	_spawn_speed_lines(dash_from, dash_to)

func _process(delta: float) -> void:
	if is_dashing:
		_process_dash(delta)
	elif waiting_for_hits:
		_process_hits(delta)

	# Update dash trails
	for i in range(dash_trails.size() - 1, -1, -1):
		var t = dash_trails[i]
		t.alpha -= delta * 8
		if t.alpha <= 0:
			dash_trails.remove_at(i)

	# Update afterimages
	for i in range(afterimages.size() - 1, -1, -1):
		var img = afterimages[i]
		img.alpha -= delta * 3
		if img.alpha <= 0:
			afterimages.remove_at(i)

	# Update speed lines
	for i in range(speed_lines.size() - 1, -1, -1):
		var line = speed_lines[i]
		line.alpha -= delta * 5
		if line.alpha <= 0:
			speed_lines.remove_at(i)

	queue_redraw()

func _process_dash(delta: float) -> void:
	var dist = dash_from.distance_to(dash_to)
	var move_amount = dash_speed * delta

	dash_progress += move_amount / max(dist, 1)

	# Spawn trail particles along path
	var current_pos = dash_from.lerp(dash_to, min(dash_progress, 1.0))
	dash_trails.append({
		"pos": current_pos,
		"alpha": 1.0
	})

	# Move player
	if is_instance_valid(player):
		player.global_position = current_pos

	if dash_progress >= 1.0:
		# Reached target!
		is_dashing = false
		waiting_for_hits = true
		hit_timer = 0.0

		# Snap to target position
		if is_instance_valid(player):
			player.global_position = dash_to

		# Start dealing hits
		_deal_hit()

func _process_hits(delta: float) -> void:
	hit_timer += delta

	if hit_timer >= hit_delay:
		hit_timer = 0.0
		current_hit += 1

		if current_hit < hits_per_enemy:
			_deal_hit()
		else:
			# Done with this target, move to next
			waiting_for_hits = false
			current_target_idx += 1
			_start_dash_to_next()

func _deal_hit() -> void:
	if current_target_idx >= targets.size():
		return

	var target = targets[current_target_idx]
	if is_instance_valid(target):
		# Deal damage
		if target.has_method("take_damage"):
			target.take_damage(damage)

		# Spawn anime slash effect!
		if anime_slash_scene:
			var slash = anime_slash_scene.instantiate()
			get_tree().current_scene.add_child(slash)
			slash.global_position = target.global_position
			if slash.has_method("setup"):
				slash.setup(1)  # Single hit worth of slashes

func _spawn_afterimage(pos: Vector2) -> void:
	afterimages.append({
		"pos": pos,
		"alpha": 0.7
	})

func _spawn_speed_lines(from: Vector2, to: Vector2) -> void:
	var dir = (to - from).normalized()
	var perp = dir.rotated(PI / 2)
	var dist = from.distance_to(to)

	for i in range(8):
		var t = randf_range(0.1, 0.9)
		var offset = perp * randf_range(-30, 30)
		var line_start = from.lerp(to, t) + offset
		var line_length = randf_range(40, 80)

		speed_lines.append({
			"start": line_start,
			"end": line_start + dir * line_length,
			"alpha": 0.8
		})

func _finish_sequence() -> void:
	# Small pause then cleanup
	await get_tree().create_timer(0.3).timeout
	queue_free()

func _draw() -> void:
	var offset = -global_position

	# Draw speed lines
	for line in speed_lines:
		if line.alpha > 0:
			var color = SPEED_LINE_COLOR
			color.a = line.alpha
			_draw_pixel_line(line.start + offset, line.end + offset, color)

	# Draw dash trails
	for t in dash_trails:
		if t.alpha > 0:
			var color = TRAIL_COLOR
			color.a = t.alpha * 0.6
			var pos = _snap(t.pos + offset)
			draw_rect(Rect2(pos, Vector2(pixel_size * 2, pixel_size * 2)), color)

	# Draw afterimages
	for img in afterimages:
		if img.alpha > 0:
			var color = AFTERIMAGE_COLOR
			color.a = img.alpha
			_draw_silhouette(img.pos + offset, color)

func _draw_silhouette(pos: Vector2, color: Color) -> void:
	# Simple character silhouette
	# Head
	_draw_pixel_circle(pos + Vector2(0, -12), 8, color)
	# Body
	for y in range(5):
		var body_pos = _snap(pos + Vector2(-4, y * pixel_size))
		draw_rect(Rect2(body_pos, Vector2(pixel_size * 2, pixel_size)), Color(color.r, color.g, color.b, color.a * 0.7))

func _draw_pixel_line(from: Vector2, to: Vector2, color: Color) -> void:
	var dist = from.distance_to(to)
	var steps = int(dist / pixel_size) + 1
	for i in range(steps):
		var t = float(i) / max(steps - 1, 1)
		var pos = _snap(from.lerp(to, t))
		draw_rect(Rect2(pos, Vector2(pixel_size, pixel_size)), color)

func _draw_pixel_circle(center: Vector2, radius: float, color: Color) -> void:
	var steps = max(int(radius / pixel_size), 2)
	for x in range(-steps, steps + 1):
		for y in range(-steps, steps + 1):
			var pos = Vector2(x, y) * pixel_size
			if pos.length() <= radius:
				var draw_pos = _snap(center + pos)
				draw_rect(Rect2(draw_pos, Vector2(pixel_size, pixel_size)), color)

func _snap(pos: Vector2) -> Vector2:
	return (pos / pixel_size).floor() * pixel_size
