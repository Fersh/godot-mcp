extends Area2D

@export var speed: float = 480.0  # 8 pixels/frame * 60fps
@export var damage: float = 10.0
@export var lifespan: float = 0.917  # 55 frames / 60fps

var direction: Vector2 = Vector2.RIGHT
var lifetime: float = 0.0
var start_position: Vector2

# Ability modifiers (set by player)
var pierce_count: int = 0
var pierced_enemies: Array = []
var can_bounce: bool = false
var bounce_count: int = 0
var max_bounces: int = 3
var has_sniper: bool = false
var sniper_bonus: float = 0.0
var damage_multiplier: float = 1.0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0
var has_knockback: bool = false
var knockback_force: float = 0.0
var speed_multiplier: float = 1.0

func _ready() -> void:
	# Rotate arrow to face direction
	rotation = direction.angle()
	start_position = global_position
	speed *= speed_multiplier

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

	lifetime += delta
	if lifetime >= lifespan:
		queue_free()
		return

	# Wall bounce check
	if can_bounce:
		check_wall_bounce()

func check_wall_bounce() -> void:
	const ARENA_WIDTH = 1536
	const ARENA_HEIGHT = 1382
	const MARGIN = 20

	var bounced = false

	if global_position.x < MARGIN:
		direction.x = abs(direction.x)
		global_position.x = MARGIN
		bounced = true
	elif global_position.x > ARENA_WIDTH - MARGIN:
		direction.x = -abs(direction.x)
		global_position.x = ARENA_WIDTH - MARGIN
		bounced = true

	if global_position.y < MARGIN:
		direction.y = abs(direction.y)
		global_position.y = MARGIN
		bounced = true
	elif global_position.y > ARENA_HEIGHT - MARGIN:
		direction.y = -abs(direction.y)
		global_position.y = ARENA_HEIGHT - MARGIN
		bounced = true

	if bounced:
		bounce_count += 1
		rotation = direction.angle()
		if bounce_count >= max_bounces:
			can_bounce = false

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and body.has_method("take_damage"):
		# Skip already pierced enemies
		if body in pierced_enemies:
			return

		# Calculate final damage
		var final_damage = calculate_damage(body)

		# Check for crit
		var is_crit = randf() < crit_chance
		if is_crit:
			final_damage *= crit_multiplier
			# Tiny screen shake on crit
			if JuiceManager:
				JuiceManager.shake_crit()

		# Deal damage
		body.take_damage(final_damage, is_crit)

		# Apply elemental effects
		_apply_elemental_effects(body)

		# Adrenaline Rush - chance to dash on hit
		if AbilityManager:
			var player = get_tree().get_first_node_in_group("player")
			if player:
				AbilityManager.check_adrenaline_dash_on_hit(player)

		# Apply knockback
		if has_knockback and body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)

		# Handle pierce
		if pierce_count > 0:
			pierced_enemies.append(body)
			pierce_count -= 1
		else:
			queue_free()

func _apply_elemental_effects(enemy: Node2D) -> void:
	if not AbilityManager:
		return

	# Ignite - apply burn damage
	if AbilityManager.check_ignite():
		if enemy.has_method("apply_burn"):
			enemy.apply_burn(3.0)  # 3 second burn
		_spawn_elemental_damage_number(enemy, "BURN", Color(1.0, 0.4, 0.2))

	# Frostbite - apply chill (slow)
	if AbilityManager.check_frostbite():
		if enemy.has_method("apply_slow"):
			enemy.apply_slow(0.5, 2.0)  # 50% slow for 2 seconds
		_spawn_elemental_damage_number(enemy, "CHILL", Color(0.4, 0.7, 1.0))

	# Toxic Tip - apply poison
	if AbilityManager.check_toxic_tip():
		if enemy.has_method("apply_poison"):
			enemy.apply_poison(50.0, 5.0)  # 50 damage over 5 seconds
		_spawn_elemental_damage_number(enemy, "POISON", Color(0.4, 1.0, 0.4))

	# Lightning Proc - trigger lightning
	if AbilityManager.check_lightning_proc():
		AbilityManager.trigger_lightning_at(enemy.global_position)
		_spawn_elemental_damage_number(enemy, "ZAP", Color(1.0, 0.9, 0.4))

func _spawn_elemental_damage_number(enemy: Node2D, text: String, color: Color) -> void:
	var damage_num_scene = load("res://scenes/damage_number.tscn")
	if damage_num_scene:
		var dmg_num = damage_num_scene.instantiate()
		dmg_num.global_position = enemy.global_position + Vector2(randf_range(-15, 15), -30)
		get_tree().root.add_child(dmg_num)
		if dmg_num.has_method("set_elemental"):
			dmg_num.set_elemental(text, color)

func calculate_damage(enemy: Node2D) -> float:
	var final_damage = damage * damage_multiplier

	# Sniper bonus based on distance
	if has_sniper:
		var distance = start_position.distance_to(global_position)
		var max_range = 400.0
		var distance_factor = clamp(distance / max_range, 0.0, 1.0)
		final_damage *= (1.0 + sniper_bonus * distance_factor)

	return final_damage
