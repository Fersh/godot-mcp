extends Area2D

@export var speed: float = 250.0
@export var damage: float = 6.0
@export var lifespan: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

# Animation
var animation_frame: float = 0.0
var animation_speed: float = 15.0
const TOTAL_FRAMES: int = 8
const FRAME_SIZE: int = 100  # Each frame is 100x100 in the spritesheet

@onready var sprite: Sprite2D = $Sprite

func _ready() -> void:
	rotation = direction.angle()

	# Connect to player collision
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	lifetime += delta
	if lifetime >= lifespan:
		queue_free()
		return

	# Animate the fireball
	animation_frame += animation_speed * delta
	if animation_frame >= TOTAL_FRAMES:
		animation_frame = 0.0

	if sprite:
		# Calculate frame position in the 8x8 grid (but we only use first row)
		sprite.frame = int(animation_frame)

func _on_body_entered(body: Node2D) -> void:
	# Check for obstacles first - they block projectiles
	if body.is_in_group("obstacles"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		queue_free()
		return

	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
