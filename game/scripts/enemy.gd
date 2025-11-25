extends CharacterBody2D

@export var speed: float = 150.0

var player: Node2D = null

func _ready() -> void:
	# Find the player in the scene
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if player and is_instance_valid(player):
		var direction = (player.global_position - global_position).normalized()
		velocity = direction * speed
		move_and_slide()
