extends Area2D

# Kobold Priest spell projectile - purple magic bolt

@export var speed: float = 200.0
@export var damage: float = 12.0
@export var lifespan: float = 4.0

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

# Animation
var animation_frame: float = 0.0
var animation_speed: float = 12.0
const TOTAL_FRAMES: int = 7

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

	# Animate the spell
	animation_frame += animation_speed * delta
	if animation_frame >= TOTAL_FRAMES:
		animation_frame = 0.0

	if sprite:
		sprite.frame = int(animation_frame)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
