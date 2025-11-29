extends Node2D

# Chain lightning hit effect - uses Lightning sprite sequence

var color: Color = Color(0.6, 0.8, 1.0, 0.9)
var duration: float = 0.3

var sprite: AnimatedSprite2D

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(2.0, 2.0)
	sprite.centered = true
	sprite.offset = Vector2(0, 20)  # Move down 20px to align with target
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 28.0)  # Fast lightning
	frames.set_animation_loop("default", false)

	# Load individual Lightning frames 1-11
	for i in range(1, 12):
		var path = "res://assets/sprites/effects/Lightning/Lightning%d.png" % i
		if ResourceLoader.exists(path):
			frames.add_frame("default", load(path))

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()
