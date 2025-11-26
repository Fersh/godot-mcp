extends Area2D

# Rock Projectile - Thrown by Cyclops elite
# Travels in an arc and deals damage on impact

@export var speed: float = 200.0
@export var damage: float = 12.0
@export var lifespan: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

# Arc motion
var initial_velocity: Vector2 = Vector2.ZERO
var rock_gravity: float = 300.0
var vertical_velocity: float = -150.0  # Initial upward arc

# Spin animation
var spin_speed: float = 720.0  # Degrees per second

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	# Set initial velocity with arc
	initial_velocity = direction * speed

	# Connect to player collision
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	# Apply gravity to create arc
	vertical_velocity += rock_gravity * delta

	# Move with arc
	var movement = initial_velocity * delta
	movement.y += vertical_velocity * delta
	position += movement

	# Spin the rock
	if sprite:
		sprite.rotation_degrees += spin_speed * delta

	lifetime += delta
	if lifetime >= lifespan:
		queue_free()
		return

	# Check if rock has fallen below screen (missed)
	if position.y > 2000:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		_spawn_impact_effect()
		queue_free()

func _spawn_impact_effect() -> void:
	# Could spawn particles here if desired
	pass
