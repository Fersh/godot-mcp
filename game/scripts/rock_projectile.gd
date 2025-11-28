extends Area2D

# Rock Projectile - Thrown by Cyclops elite
# Travels in an arc and deals damage on impact

@export var speed: float = 200.0
@export var damage: float = 12.0
@export var lifespan: float = 4.0
@export var aoe_radius: float = 40.0  # Explosion radius

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var target_position: Vector2 = Vector2.ZERO  # Where the rock will land
var has_target: bool = false

# Arc motion
var start_position: Vector2 = Vector2.ZERO
var arc_height: float = 80.0  # How high the arc goes
var flight_time: float = 0.8  # Time to reach target
var flight_progress: float = 0.0

# Spin animation
var spin_speed: float = 720.0  # Degrees per second

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	start_position = global_position

	# Calculate flight time based on distance if we have a target
	if has_target:
		var distance = start_position.distance_to(target_position)
		flight_time = distance / speed
		arc_height = distance * 0.3  # Arc height proportional to distance

	# Connect to player collision
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	lifetime += delta

	if has_target:
		# Arc motion toward target
		flight_progress += delta / flight_time

		if flight_progress >= 1.0:
			# Reached target - explode
			_explode()
			return

		# Lerp position horizontally
		var horizontal_pos = start_position.lerp(target_position, flight_progress)

		# Add arc (parabola: 4 * h * t * (1 - t) where t is progress)
		var arc_offset = 4.0 * arc_height * flight_progress * (1.0 - flight_progress)

		global_position = horizontal_pos - Vector2(0, arc_offset)
	else:
		# Fallback: old behavior for backwards compatibility
		var vertical_velocity = -150.0 + 300.0 * lifetime
		var movement = direction * speed * delta
		movement.y += vertical_velocity * delta
		position += movement

		if lifetime >= lifespan or position.y > 2000:
			queue_free()
			return

	# Spin the rock
	if sprite:
		sprite.rotation_degrees += spin_speed * delta

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_explode()

func _explode() -> void:
	# Deal AOE damage at landing position
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and player.has_method("take_damage"):
		var dist = global_position.distance_to(player.global_position)
		if dist <= aoe_radius:
			player.take_damage(damage)

	_spawn_impact_effect()
	queue_free()

func _spawn_impact_effect() -> void:
	# Screen shake on impact
	if JuiceManager:
		JuiceManager.shake_small()

	# Could spawn particles here if desired
	pass
