extends Node2D

# Impact smoke/dust effect using various smoke sprites
# Used for ground_slam, shield_bash landing, savage_leap_landing

enum ImpactType { SMALL_SMOKE, MEDIUM_SMOKE, BIG_SMOKE, DUST_KICK }

var sprite: AnimatedSprite2D
var effect_scale: float = 2.0
var impact_type: ImpactType = ImpactType.BIG_SMOKE

func _ready() -> void:
	_setup_sprite()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	sprite.scale = Vector2(effect_scale, effect_scale)
	add_child(sprite)

	var frames = SpriteFrames.new()
	frames.add_animation("default")
	frames.set_animation_speed("default", 18.0)
	frames.set_animation_loop("default", false)

	var source_path: String
	var frame_width: int
	var frame_height: int
	var frame_count: int

	match impact_type:
		ImpactType.SMALL_SMOKE:
			source_path = "res://assets/sprites/effects/slash/SMALL SMOKE.png"
		ImpactType.MEDIUM_SMOKE:
			source_path = "res://assets/sprites/effects/slash/MEDIUM SMOKE.png"
		ImpactType.BIG_SMOKE:
			source_path = "res://assets/sprites/effects/slash/BIG IMPACT SMOKE.png"
		ImpactType.DUST_KICK:
			source_path = "res://assets/sprites/effects/slash/IMPACT DUST KICK.png"

	# Use full image as single frame
	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			frames.add_frame("default", source_texture)

	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("default")

func _on_animation_finished() -> void:
	queue_free()

func set_impact_type(type: ImpactType) -> void:
	impact_type = type
