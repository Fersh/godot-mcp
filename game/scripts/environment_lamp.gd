extends StaticBody2D

## Environmental lamp with torch-like lighting.
## Destructible obstacle - blocks movement and can be destroyed.
## Registered with torches group so day_night_cycle controls it.

signal destroyed(lamp: Node2D)

@export var max_health: float = 30.0

var current_health: float
var is_destroyed: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var light: PointLight2D = $PointLight2D

func _ready() -> void:
	# Add to torches group so day/night cycle controls lighting
	add_to_group("torches")
	add_to_group("obstacles")

	current_health = max_health

	# Setup collision - layer 8 for obstacles
	collision_layer = 8
	collision_mask = 0

	# Set z_index based on Y position for depth sorting
	z_index = int(global_position.y / 10)

func take_damage(amount: float, _is_critical: bool = false) -> void:
	if is_destroyed:
		return

	current_health -= amount

	# Flash on hit
	if sprite:
		sprite.modulate = Color(2.0, 2.0, 2.0, 1.0)
		var tween = create_tween()
		tween.tween_property(sprite, "modulate", Color.WHITE, 0.1)

	if current_health <= 0:
		_destroy()

func _destroy() -> void:
	if is_destroyed:
		return
	is_destroyed = true

	emit_signal("destroyed", self)

	# Disable collision
	collision_layer = 0

	# Fade out and remove
	var tween = create_tween()
	tween.set_parallel(true)
	if sprite:
		tween.tween_property(sprite, "modulate:a", 0.0, 0.3)
		tween.tween_property(sprite, "scale", sprite.scale * 0.5, 0.3)
	if light:
		tween.tween_property(light, "energy", 0.0, 0.3)

	tween.chain().tween_callback(queue_free)
