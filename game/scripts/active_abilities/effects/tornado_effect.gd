extends Node2D

# Tornado/Whirlwind effect - procedurally generated spinning effect
# Used for whirlwind, bladestorm

var duration: float = 3.0
var radius: float = 100.0
var damage: float = 0.0
var damage_multiplier: float = 1.0
var _initialized: bool = false

# Visual components
var swirl_lines: Array[Line2D] = []
var particles: Array[Dictionary] = []
var rotation_speed: float = 8.0
var current_rotation: float = 0.0

const NUM_SWIRL_LINES: int = 6
const NUM_PARTICLES: int = 20

func _ready() -> void:
	call_deferred("_deferred_init")

func _deferred_init() -> void:
	if _initialized:
		return
	_initialized = true
	_setup_visuals()
	_start_duration_timer()

func _setup_visuals() -> void:
	# Create swirling lines
	for i in range(NUM_SWIRL_LINES):
		var line = Line2D.new()
		line.width = 4.0
		line.default_color = Color(0.7, 0.85, 1.0, 0.7)  # Light blue/white
		line.z_index = 10
		line.begin_cap_mode = Line2D.LINE_CAP_ROUND
		line.end_cap_mode = Line2D.LINE_CAP_ROUND
		add_child(line)
		swirl_lines.append(line)

	# Create particle data
	for i in range(NUM_PARTICLES):
		var particle = {
			"angle": randf() * TAU,
			"height": randf(),
			"dist": randf_range(0.3, 1.0),
			"speed": randf_range(0.8, 1.2),
			"size": randf_range(2.0, 5.0)
		}
		particles.append(particle)

	# Create particle visual nodes
	for i in range(NUM_PARTICLES):
		var particle_node = ColorRect.new()
		particle_node.size = Vector2(particles[i].size, particles[i].size)
		particle_node.color = Color(0.8, 0.9, 1.0, 0.6)
		particle_node.z_index = 11
		add_child(particle_node)

func _process(delta: float) -> void:
	current_rotation += rotation_speed * delta
	_update_swirl_lines()
	_update_particles(delta)

func _update_swirl_lines() -> void:
	var scale_factor = radius / 50.0

	for i in range(swirl_lines.size()):
		var line = swirl_lines[i]
		var base_angle = current_rotation + (TAU / NUM_SWIRL_LINES) * i
		var points: PackedVector2Array = []

		# Create spiral from bottom to top
		var segments = 20
		for j in range(segments):
			var t = float(j) / (segments - 1)
			var height = t * 80.0 * scale_factor - 40.0 * scale_factor
			var spiral_radius = (1.0 - t * 0.6) * 40.0 * scale_factor
			var angle = base_angle + t * TAU * 1.5

			var x = cos(angle) * spiral_radius
			var y = height + sin(angle) * spiral_radius * 0.3
			points.append(Vector2(x, y))

		line.points = points

		# Vary alpha based on line index for depth effect
		var alpha = 0.5 + 0.3 * sin(current_rotation + i)
		line.default_color = Color(0.7, 0.85, 1.0, alpha)

func _update_particles(delta: float) -> void:
	var scale_factor = radius / 50.0
	var particle_nodes = get_children().filter(func(n): return n is ColorRect)

	for i in range(min(particles.size(), particle_nodes.size())):
		var p = particles[i]
		var node = particle_nodes[i] as ColorRect

		# Update particle angle
		p.angle += rotation_speed * p.speed * delta

		# Calculate position in 3D-ish space
		var t = p.height
		var spiral_radius = (1.0 - t * 0.5) * 35.0 * scale_factor * p.dist
		var height = t * 70.0 * scale_factor - 35.0 * scale_factor

		var x = cos(p.angle) * spiral_radius
		var y = height + sin(p.angle) * spiral_radius * 0.25

		node.position = Vector2(x - node.size.x/2, y - node.size.y/2)

		# Fade based on depth (back particles dimmer)
		var depth_alpha = 0.4 + 0.4 * (0.5 + 0.5 * sin(p.angle))
		node.color = Color(0.8, 0.9, 1.0, depth_alpha)

		# Loop height
		p.height += delta * 0.3 * p.speed
		if p.height > 1.0:
			p.height = 0.0
			p.angle = randf() * TAU
			p.dist = randf_range(0.3, 1.0)

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
