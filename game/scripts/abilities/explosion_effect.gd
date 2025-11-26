extends Node2D

# Animated pixel explosion effect using FireBomb sprites

var sprite: AnimatedSprite2D
var scale_multiplier: float = 1.5  # Scale up the 64x64 sprite

func _ready() -> void:
	_create_animated_sprite()

func _create_animated_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(scale_multiplier, scale_multiplier)
	add_child(sprite)

	# Create SpriteFrames resource
	var frames = SpriteFrames.new()
	frames.add_animation("explode")
	frames.set_animation_speed("explode", 20.0)  # 20 FPS for snappy explosion
	frames.set_animation_loop("explode", false)

	# Load all 15 FireBomb frames
	for i in range(1, 16):
		var path = "res://assets/sprites/effects/FireBomb/Fire-bomb%d.png" % i
		if ResourceLoader.exists(path):
			var texture = load(path)
			frames.add_frame("explode", texture)

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("explode")

func _on_animation_finished() -> void:
	queue_free()

# Allow setting custom scale for different explosion sizes
func set_explosion_scale(new_scale: float) -> void:
	scale_multiplier = new_scale
	if sprite:
		sprite.scale = Vector2(scale_multiplier, scale_multiplier)
