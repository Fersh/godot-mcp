extends Area2D

var orbit_index: int = 0
var orbit_radius: float = 80.0
var orbit_speed: float = 3.0  # radians per second
var angle: float = 0.0
var damage: float = 15.0

func _ready() -> void:
	# Offset starting angle based on index
	angle = orbit_index * (TAU / 3.0)

	# Set up collision
	collision_layer = 2  # Arrow layer
	collision_mask = 4   # Enemy layer

	# Create collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 12.0
	collision.shape = shape
	add_child(collision)

	# Connect signal
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	angle += orbit_speed * delta
	if angle > TAU:
		angle -= TAU

	# Update position relative to parent (player)
	position = Vector2(cos(angle), sin(angle)) * orbit_radius

	queue_redraw()

func _draw() -> void:
	# Draw as a glowing orb
	draw_circle(Vector2.ZERO, 10.0, Color(0.3, 0.6, 1.0, 0.8))
	draw_circle(Vector2.ZERO, 6.0, Color(0.6, 0.8, 1.0, 1.0))

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
