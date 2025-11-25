extends Area2D

@export var speed: float = 480.0  # 8 pixels/frame * 60fps
@export var damage: float = 10.0
@export var lifespan: float = 0.917  # 55 frames / 60fps

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0

func _ready() -> void:
	# Rotate arrow to face direction
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	lifetime += delta
	if lifetime >= lifespan:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		body.take_damage(damage)
		queue_free()
