extends Area2D

@export var xp_value: float = 1.0
@export var bob_speed: float = 3.0
@export var bob_height: float = 5.0

var initial_y: float = 0.0
var time: float = 0.0

func _ready() -> void:
	initial_y = position.y
	# Random starting phase for variety
	time = randf() * TAU

func _physics_process(delta: float) -> void:
	time += delta * bob_speed
	position.y = initial_y + sin(time) * bob_height

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player") and body.has_method("add_xp"):
		body.add_xp(xp_value)
		queue_free()
