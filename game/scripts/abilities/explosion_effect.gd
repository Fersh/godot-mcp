extends Node2D

# Animated pixel explosion effect using Explosion sprite sheets from pack2

var sprite: Sprite2D
var scale_multiplier: float = 1.5
var explosion_size: String = "medium"  # "small", "medium", "large"
var current_frame: int = 0
var frame_count: int = 12
var animation_speed: float = 24.0
var frame_timer: float = 0.0

func _ready() -> void:
	_create_sprite()

func _create_sprite() -> void:
	sprite = Sprite2D.new()
	add_child(sprite)

	var source_path: String
	var frame_size: int

	match explosion_size:
		"small":
			source_path = "res://assets/sprites/effects/pack2/Explosion_2_64x64.png"
			frame_size = 64
			scale_multiplier = 1.5
		"large":
			source_path = "res://assets/sprites/effects/pack2/Explosion_3_133x133.png"
			frame_size = 133
			scale_multiplier = 2.0
		_:  # medium (default)
			source_path = "res://assets/sprites/effects/pack2/Explosion_96x96.png"
			frame_size = 96
			scale_multiplier = 1.8

	sprite.scale = Vector2(scale_multiplier, scale_multiplier)

	if ResourceLoader.exists(source_path):
		var texture = load(source_path) as Texture2D
		if texture:
			sprite.texture = texture
			var total_width = texture.get_width()
			frame_count = int(total_width / frame_size)
			sprite.hframes = frame_count
			sprite.vframes = 1
			sprite.frame = 0

func _process(delta: float) -> void:
	frame_timer += delta
	if frame_timer >= 1.0 / animation_speed:
		frame_timer = 0.0
		current_frame += 1
		if current_frame >= frame_count:
			queue_free()
		elif sprite:
			sprite.frame = current_frame

func set_explosion_scale(new_scale: float) -> void:
	scale_multiplier = new_scale
	if sprite:
		sprite.scale = Vector2(scale_multiplier, scale_multiplier)

func set_size(size: String) -> void:
	explosion_size = size
