extends Area2D

# Generic ability projectile with animated sprite support

var direction: Vector2 = Vector2.RIGHT
var speed: float = 400.0
var damage: float = 10.0
var pierce_count: int = 0
var max_range: float = 800.0
var traveled: float = 0.0
var ability_id: String = ""
var explosion_radius: float = 0.0
var stun_duration: float = 0.0
var slow_percent: float = 0.0
var slow_duration: float = 0.0
var knockback_force: float = 0.0

var sprite: AnimatedSprite2D
var hit_enemies: Array = []

func _ready() -> void:
	collision_layer = 2
	collision_mask = 12  # Layer 4 (enemies) + Layer 8 (obstacles)
	_setup_sprite()
	rotation = direction.angle()

func _setup_sprite() -> void:
	sprite = AnimatedSprite2D.new()
	add_child(sprite)

	var frames = SpriteFrames.new()
	# SpriteFrames.new() already creates "default" animation, just configure it
	frames.set_animation_loop("default", true)

	var source_path: String
	var frame_size: int
	var anim_speed: float = 15.0

	match ability_id:
		"fireball":
			source_path = "res://assets/sprites/effects/pack2/FireBall_64x64.png"
			frame_size = 64
			sprite.scale = Vector2(1.0, 1.0)
			anim_speed = 20.0
		"throwing_bomb":
			source_path = "res://assets/sprites/effects/pack2/FireBall_2_64x64.png"
			frame_size = 64
			sprite.scale = Vector2(0.8, 0.8)
		"ice_spike", "frost":
			source_path = "res://assets/sprites/effects/pack2/IceSpike_64x64.png"
			frame_size = 64
			sprite.scale = Vector2(1.0, 1.0)
		"lightning_bolt":
			source_path = "res://assets/sprites/effects/pack2/LightningBolt_64x64.png"
			frame_size = 64
			sprite.scale = Vector2(1.0, 1.0)
		_:
			# Default fireball
			source_path = "res://assets/sprites/effects/pack2/FireBall_64x64.png"
			frame_size = 64
			sprite.scale = Vector2(0.8, 0.8)

	frames.set_animation_speed("default", anim_speed)

	if ResourceLoader.exists(source_path):
		var source_texture = load(source_path) as Texture2D
		if source_texture:
			var img = source_texture.get_image()
			var total_width = img.get_width()
			var frame_count = total_width / frame_size

			for i in range(frame_count):
				var frame_img = Image.create(frame_size, frame_size, false, img.get_format())
				frame_img.blit_rect(img, Rect2i(i * frame_size, 0, frame_size, frame_size), Vector2i.ZERO)
				frames.add_frame("default", ImageTexture.create_from_image(frame_img))

	sprite.sprite_frames = frames
	sprite.play("default")

	# Add collision shape
	var collision = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	collision.shape = shape
	add_child(collision)

func _physics_process(delta: float) -> void:
	var movement = direction * speed * delta
	position += movement
	traveled += movement.length()

	if traveled >= max_range:
		_on_max_range()

func setup_from_ability(ability, dmg: float, piercing: bool = false) -> void:
	ability_id = ability.id
	damage = dmg
	speed = ability.projectile_speed if ability.projectile_speed > 0 else 400.0
	max_range = ability.range_distance * 2 if ability.range_distance > 0 else 600.0
	explosion_radius = ability.radius
	stun_duration = ability.stun_duration
	slow_percent = ability.slow_percent
	slow_duration = ability.slow_duration
	knockback_force = ability.knockback_force

	if piercing:
		pierce_count = 99

func _on_body_entered(body: Node2D) -> void:
	if not body.is_in_group("enemies"):
		return

	if body in hit_enemies:
		return

	hit_enemies.append(body)

	# Deal damage
	if body.has_method("take_damage"):
		body.take_damage(damage, false)

	# Apply effects
	if stun_duration > 0 and body.has_method("apply_stun"):
		body.apply_stun(stun_duration)

	if slow_percent > 0 and body.has_method("apply_slow"):
		body.apply_slow(slow_percent, slow_duration)

	if knockback_force > 0 and body.has_method("apply_knockback"):
		body.apply_knockback(direction * knockback_force)

	# Check piercing
	if pierce_count > 0:
		pierce_count -= 1
	else:
		_explode()

func _on_max_range() -> void:
	if explosion_radius > 0:
		_explode()
	else:
		queue_free()

func _explode() -> void:
	# Spawn explosion effect
	_spawn_explosion_effect()

	# AOE damage if has radius
	if explosion_radius > 0:
		var enemies = get_tree().get_nodes_in_group("enemies")
		for enemy in enemies:
			if not is_instance_valid(enemy):
				continue
			if enemy in hit_enemies:
				continue

			var dist = global_position.distance_to(enemy.global_position)
			if dist <= explosion_radius:
				if enemy.has_method("take_damage"):
					enemy.take_damage(damage * 0.75, false)  # 75% damage for AOE (buffed from 50%)
				# Apply burn for fire abilities
				if ability_id == "fireball" and enemy.has_method("apply_burn"):
					enemy.apply_burn(3.0)

	queue_free()

func _spawn_explosion_effect() -> void:
	var effect_scene_path = "res://scenes/effects/ability_effects/fireball_sprite.tscn"
	if ResourceLoader.exists(effect_scene_path):
		var effect = load(effect_scene_path).instantiate()
		effect.global_position = global_position
		if effect.has_method("set_explosion_mode"):
			effect.set_explosion_mode(true)
		get_tree().current_scene.add_child(effect)
