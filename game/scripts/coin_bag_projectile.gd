extends Area2D

# Coin Bag Projectile - Thrown by Goblin King elite
# Travels to target and explodes on contact with player or when reaching destination
# Sprite sheet: 3 columns x 2 rows (frames 0-2 fly, frames 3-5 explode)

@export var speed: float = 180.0
@export var damage: float = 25.0
@export var explosion_radius: float = 60.0
@export var lifespan: float = 3.0

var direction: Vector2 = Vector2.RIGHT
var target_position: Vector2 = Vector2.ZERO
var lifetime: float = 0.0
var has_exploded: bool = false

# Arc motion
var initial_velocity: Vector2 = Vector2.ZERO
var bag_gravity: float = 250.0
var vertical_velocity: float = -120.0  # Initial upward arc

# Animation
@onready var sprite: Sprite2D = $Sprite
var animation_frame: float = 0.0
var animation_speed: float = 8.0
var is_flying: bool = true
var explosion_frame: int = 0

# Fly frames: 0, 1, 2 (row 0)
# Explode frames: 3, 4, 5 (row 1)
const FLY_FRAMES = [0, 1, 2]
const EXPLODE_FRAMES = [3, 4, 5]

func _ready() -> void:
	# Set initial velocity with arc
	initial_velocity = direction * speed

	# Connect to player collision
	body_entered.connect(_on_body_entered)

	# Start at first fly frame
	if sprite:
		sprite.frame = FLY_FRAMES[0]

func _physics_process(delta: float) -> void:
	if has_exploded:
		# Play explosion animation
		_animate_explosion(delta)
		return

	# Apply gravity to create arc
	vertical_velocity += bag_gravity * delta

	# Move with arc
	var movement = initial_velocity * delta
	movement.y += vertical_velocity * delta
	position += movement

	# Animate flying
	_animate_fly(delta)

	lifetime += delta
	if lifetime >= lifespan:
		_explode()
		return

	# Check if we've reached the ground (target area)
	# Explode when the bag starts falling and reaches a certain Y threshold
	if vertical_velocity > 0 and position.y > target_position.y:
		_explode()
		return

	# Check if bag has fallen below screen (missed)
	if position.y > 2000:
		queue_free()

func _animate_fly(delta: float) -> void:
	if sprite == null:
		return

	animation_frame += animation_speed * delta
	var frame_index = int(animation_frame) % FLY_FRAMES.size()
	sprite.frame = FLY_FRAMES[frame_index]

func _animate_explosion(delta: float) -> void:
	if sprite == null:
		return

	animation_frame += animation_speed * delta
	var frame_index = int(animation_frame)

	if frame_index >= EXPLODE_FRAMES.size():
		queue_free()
		return

	sprite.frame = EXPLODE_FRAMES[frame_index]

func _on_body_entered(body: Node2D) -> void:
	if has_exploded:
		return

	if body.is_in_group("player"):
		_explode()

func _explode() -> void:
	if has_exploded:
		return

	has_exploded = true
	is_flying = false
	animation_frame = 0.0

	# Start explosion animation at first explode frame
	if sprite:
		sprite.frame = EXPLODE_FRAMES[0]

	# Deal AOE damage
	_deal_explosion_damage()

	# Stop movement
	initial_velocity = Vector2.ZERO
	vertical_velocity = 0

func _deal_explosion_damage() -> void:
	# Find player and check if in explosion radius
	var players = get_tree().get_nodes_in_group("player")
	for player in players:
		if is_instance_valid(player):
			var dist = global_position.distance_to(player.global_position)
			if dist <= explosion_radius:
				if player.has_method("take_damage"):
					player.take_damage(damage)

	# Screen shake for impact
	if JuiceManager:
		JuiceManager.shake_medium()

	# Spawn gold coin particles for visual effect
	_spawn_coin_particles()

func _spawn_coin_particles() -> void:
	# Visual effect - spawn some gold particles
	for i in range(5):
		var particle = Sprite2D.new()
		particle.modulate = Color(1.0, 0.85, 0.2, 1.0)
		particle.scale = Vector2(0.3, 0.3)
		particle.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 20))
		get_parent().add_child(particle)

		# Tween the particle to fade and fall
		var tween = particle.create_tween()
		tween.set_parallel(true)
		tween.tween_property(particle, "position:y", particle.position.y + 30, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.chain().tween_callback(particle.queue_free)
