extends Node2D

# Ground slam shockwave effect - uses BIG IMPACT SMOKE sprite

var radius: float = 100.0
var duration: float = 0.5

var sprite: AnimatedSprite2D

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(3.0, 3.0)  # Large impact
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_speed("default", 18.0)
	frames.set_animation_loop("default", false)

	# Load BIG IMPACT SMOKE sprite sheet - use full image as single frame
	var source_path = "res://assets/sprites/effects/slash/BIG IMPACT SMOKE.png"
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			frames.add_frame("default", source_texture)

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()
