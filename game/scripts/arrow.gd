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
# Ricochet - bounces to nearby enemies on hit
var has_ricochet: bool = false
var ricochet_count: int = 0
var max_ricochets: int = 0
var sniper_bonus: float = 0.0
var damage_multiplier: float = 1.0
var crit_chance: float = 0.0
var crit_multiplier: float = 2.0
var has_knockback: bool = false
var knockback_force: float = 0.0
var speed_multiplier: float = 1.0
var is_mage_orb: bool = false
var is_kobold_orb: bool = false  # White magic orb for Kobold Priest
var is_necro_orb: bool = false  # Dark skull orb for Necromancer
var is_assassin_dagger: bool = false

signal enemy_hit  # For Assassin Shadow Dance tracking

# Boomerang ability
var has_boomerang: bool = false
var is_returning: bool = false
var return_target: Node2D = null

var trail_line: Line2D = null
var trail_points: Array[Vector2] = []
const MAX_TRAIL_POINTS: int = 12
const TRAIL_UPDATE_INTERVAL: float = 0.016  # ~60fps
var trail_timer: float = 0.0

func _ready() -> void:
	# Rotate arrow to face direction
	rotation = direction.angle()
	start_position = global_position
	speed *= speed_multiplier

	# Setup projectile trail (#19)
	_setup_trail()

	# Transform into mage orb if needed
	if is_mage_orb:
		_setup_mage_orb()

	# Transform into kobold orb if needed
	if is_kobold_orb:
		_setup_kobold_orb()

	# Transform into necro orb if needed
	if is_necro_orb:
		_setup_necro_orb()

	# Transform into assassin dagger if needed
	if is_assassin_dagger:
		_setup_assassin_dagger()

func _setup_assassin_dagger() -> void:
	# Remove arrow visuals
	var sprite = get_node_or_null("Sprite")
	var tip = get_node_or_null("Tip")
	if sprite:
		sprite.queue_free()
	if tip:
		tip.queue_free()

	# Create dagger shape
	var dagger = Node2D.new()
	dagger.name = "Dagger"
	add_child(dagger)

	# Blade (main body) - triangular shape
	var blade = Polygon2D.new()
	var blade_points: PackedVector2Array = [
		Vector2(-8, 0),    # Back of blade
		Vector2(8, -2),    # Top edge going forward
		Vector2(12, 0),    # Tip
		Vector2(8, 2),     # Bottom edge going forward
	]
	blade.polygon = blade_points
	blade.color = Color(0.8, 0.85, 0.9, 1.0)  # Silvery metal color
	dagger.add_child(blade)

	# Cutting edge highlight
	var edge = Line2D.new()
	edge.add_point(Vector2(-6, 0))
	edge.add_point(Vector2(12, 0))
	edge.width = 1.5
	edge.default_color = Color(1.0, 1.0, 1.0, 0.8)  # Bright edge
	dagger.add_child(edge)

	# Handle/grip (dark part at back)
	var handle = Polygon2D.new()
	var handle_points: PackedVector2Array = [
		Vector2(-12, -2),
		Vector2(-8, -2),
		Vector2(-8, 2),
		Vector2(-12, 2),
	]
	handle.polygon = handle_points
	handle.color = Color(0.3, 0.2, 0.15, 1.0)  # Dark brown grip
	dagger.add_child(handle)

	# Update trail color to purple/dark
	if trail_line:
		trail_line.default_color = Color(0.6, 0.4, 0.8, 0.5)

func _setup_mage_orb() -> void:
	# Remove arrow visuals
	var sprite = get_node_or_null("Sprite")
	var tip = get_node_or_null("Tip")
	if sprite:
		sprite.queue_free()
	if tip:
		tip.queue_free()

	# Create blue pixel orb
	var orb = Node2D.new()
	orb.name = "MageOrb"
	add_child(orb)

	# Core orb (bright blue center)
	var core = Polygon2D.new()
	var core_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		core_points.append(Vector2(cos(angle), sin(angle)) * 4)
	core.polygon = core_points
	core.color = Color(0.4, 0.7, 1.0, 1.0)  # Light blue
	orb.add_child(core)

	# Outer glow (darker blue)
	var glow = Polygon2D.new()
	var glow_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		glow_points.append(Vector2(cos(angle), sin(angle)) * 7)
	glow.polygon = glow_points
	glow.color = Color(0.2, 0.4, 0.9, 0.6)  # Darker blue, semi-transparent
	glow.z_index = -1
	orb.add_child(glow)

	# Reset rotation since orb is circular
	rotation = 0

func _setup_kobold_orb() -> void:
	# Remove arrow visuals
	var sprite = get_node_or_null("Sprite")
	var tip = get_node_or_null("Tip")
	if sprite:
		sprite.queue_free()
	if tip:
		tip.queue_free()

	# Create white pixel orb
	var orb = Node2D.new()
	orb.name = "KoboldOrb"
	add_child(orb)

	# Core orb (bright white center)
	var core = Polygon2D.new()
	var core_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		core_points.append(Vector2(cos(angle), sin(angle)) * 4)
	core.polygon = core_points
	core.color = Color(1.0, 1.0, 1.0, 1.0)  # Pure white
	orb.add_child(core)

	# Outer glow (light gray)
	var glow = Polygon2D.new()
	var glow_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		glow_points.append(Vector2(cos(angle), sin(angle)) * 7)
	glow.polygon = glow_points
	glow.color = Color(0.9, 0.9, 0.95, 0.6)  # Light gray, semi-transparent
	glow.z_index = -1
	orb.add_child(glow)

	# Reset rotation since orb is circular
	rotation = 0

func _setup_necro_orb() -> void:
	# Remove arrow visuals
	var sprite = get_node_or_null("Sprite")
	var tip = get_node_or_null("Tip")
	if sprite:
		sprite.queue_free()
	if tip:
		tip.queue_free()

	# Create dark skull orb
	var orb = Node2D.new()
	orb.name = "NecroOrb"
	add_child(orb)

	# Core orb (sickly green center)
	var core = Polygon2D.new()
	var core_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		core_points.append(Vector2(cos(angle), sin(angle)) * 5)
	core.polygon = core_points
	core.color = Color(0.5, 0.9, 0.4, 1.0)  # Sickly green
	orb.add_child(core)

	# Outer glow (dark purple)
	var glow = Polygon2D.new()
	var glow_points: PackedVector2Array = []
	for i in 8:
		var angle = i * TAU / 8
		glow_points.append(Vector2(cos(angle), sin(angle)) * 8)
	glow.polygon = glow_points
	glow.color = Color(0.4, 0.2, 0.5, 0.6)  # Dark purple, semi-transparent
	glow.z_index = -1
	orb.add_child(glow)

	# Skull face details (two eye sockets)
	var left_eye = Polygon2D.new()
	var right_eye = Polygon2D.new()
	var eye_points: PackedVector2Array = []
	for i in 6:
		var angle = i * TAU / 6
		eye_points.append(Vector2(cos(angle), sin(angle)) * 1.5)
	left_eye.polygon = eye_points
	right_eye.polygon = eye_points
	left_eye.color = Color(0.1, 0.0, 0.15, 1.0)  # Dark void
	right_eye.color = Color(0.1, 0.0, 0.15, 1.0)
	left_eye.position = Vector2(-2, -1)
	right_eye.position = Vector2(2, -1)
	orb.add_child(left_eye)
	orb.add_child(right_eye)

	# Reset rotation since orb is circular
	rotation = 0

func _physics_process(delta: float) -> void:
	# Handle boomerang return
	if is_returning:
		_process_boomerang_return(delta)
		return

	position += direction * speed * delta

	# Update trail (#19)
	_update_trail(delta)

	lifetime += delta
	if lifetime >= lifespan:
		# If boomerang, start returning instead of despawning
		if has_boomerang and not is_returning:
			_start_boomerang_return()
			return
		queue_free()
		return

	# Wall bounce check
	if can_bounce:
		check_wall_bounce()

func _start_boomerang_return() -> void:
	is_returning = true
	pierced_enemies.clear()  # Allow hitting enemies again on return

	# Find player to return to
	return_target = get_tree().get_first_node_in_group("player")

	# Extend lifespan for return journey
	lifetime = 0.0
	lifespan = 2.0  # Give plenty of time to return

func _process_boomerang_return(delta: float) -> void:
	if return_target == null or not is_instance_valid(return_target):
		queue_free()
		return

	# Home in on player
	var to_player = return_target.global_position - global_position
	var distance = to_player.length()

	# Reached player - despawn
	if distance < 30.0:
		queue_free()
		return

	# Update direction to track player
	direction = to_player.normalized()
	rotation = direction.angle()

	# Move slightly faster on return
	position += direction * speed * 1.2 * delta

	lifetime += delta
	if lifetime >= lifespan:
		queue_free()

func check_wall_bounce() -> void:
	const ARENA_LEFT = -80
	const ARENA_RIGHT = 1616
	const ARENA_HEIGHT = 1382
	const MARGIN_Y = 20

	var bounced = false

	if global_position.x < ARENA_LEFT:
		direction.x = abs(direction.x)
		global_position.x = ARENA_LEFT
		bounced = true
	elif global_position.x > ARENA_RIGHT:
		direction.x = -abs(direction.x)
		global_position.x = ARENA_RIGHT
		bounced = true

	if global_position.y < MARGIN_Y:
		direction.y = abs(direction.y)
		global_position.y = MARGIN_Y
		bounced = true
	elif global_position.y > ARENA_HEIGHT - MARGIN_Y:
		direction.y = -abs(direction.y)
		global_position.y = ARENA_HEIGHT - MARGIN_Y
		bounced = true

	if bounced:
		bounce_count += 1
		rotation = direction.angle()
		if bounce_count >= max_bounces:
			can_bounce = false

func _on_body_entered(body: Node2D) -> void:
	# Handle obstacles (trees, rocks, etc.)
	if body.is_in_group("obstacles"):
		if body.has_method("take_damage"):
			body.take_damage(damage * damage_multiplier, false)
		# Arrows stop on obstacles unless piercing
		if pierce_count > 0:
			pierce_count -= 1
		else:
			queue_free()
		return

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

		# Check if player has ability-boosted attacks (e.g. Monster Energy)
		var player = get_tree().get_first_node_in_group("player")
		if player and player.has_method("has_ability_boosted_attacks"):
			if player.has_ability_boosted_attacks() and body.has_method("mark_ability_kill"):
				body.mark_ability_kill()

		# Deal damage
		body.take_damage(final_damage, is_crit)

		# Emit enemy_hit signal for Assassin Shadow Dance tracking
		emit_signal("enemy_hit")

		# Apply elemental effects
		_apply_elemental_effects(body)

		# Notify player of hit (for Heartseeker passive and other on-hit effects)
		if player:
			if player.has_method("on_arrow_hit_enemy"):
				player.on_arrow_hit_enemy(body, is_crit)
			# Adrenaline Rush - chance to dash on hit
			if AbilityManager:
				AbilityManager.check_adrenaline_dash_on_hit(player)

		# Apply knockback
		if has_knockback and body.has_method("apply_knockback"):
			body.apply_knockback(direction * knockback_force)

		# Handle pierce
		if pierce_count > 0:
			pierced_enemies.append(body)
			pierce_count -= 1
		elif has_ricochet and ricochet_count < max_ricochets:
			# Ricochet: bounce to nearby enemy
			pierced_enemies.append(body)
			if _try_ricochet(body):
				ricochet_count += 1
			else:
				queue_free()  # No valid target, despawn
		elif has_boomerang and not is_returning:
			# Boomerang: start returning on hit instead of despawning
			pierced_enemies.append(body)
			_start_boomerang_return()
		else:
			queue_free()

func _try_ricochet(current_enemy: Node2D) -> bool:
	"""Find nearest enemy and redirect arrow to it. Returns true if successful."""
	var nearest_enemy: Node2D = null
	var nearest_dist: float = 300.0  # Max ricochet range

	var enemies = get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if not is_instance_valid(enemy):
			continue
		if enemy == current_enemy:
			continue
		if enemy in pierced_enemies:
			continue
		if not enemy.has_method("take_damage"):
			continue
		# Check if enemy is alive
		if enemy.has_method("is_dead") and enemy.is_dead():
			continue

		var dist = global_position.distance_to(enemy.global_position)
		if dist < nearest_dist:
			nearest_dist = dist
			nearest_enemy = enemy

	if nearest_enemy:
		# Redirect arrow toward new target
		direction = (nearest_enemy.global_position - global_position).normalized()
		rotation = direction.angle()

		# Reset lifetime to give arrow time to reach target
		lifetime = 0.0
		lifespan = 0.5  # Short lifespan for ricochet

		# Brief visual feedback
		modulate = Color(1.2, 1.1, 0.8, 1.0)  # Slight golden flash

		return true

	return false

func _apply_elemental_effects(enemy: Node2D) -> void:
	if not AbilityManager:
		return

	# Chaotic Strikes - random elemental effect each hit
	if AbilityManager.has_chaotic_strikes:
		var chaos_element = AbilityManager.get_chaotic_element()
		match chaos_element:
			"fire":
				if enemy.has_method("apply_burn"):
					enemy.apply_burn(3.0)
				_spawn_elemental_damage_number(enemy, "BURN", Color(1.0, 0.4, 0.2))
			"ice":
				if enemy.has_method("apply_slow"):
					enemy.apply_slow(0.5, 2.0)
				_spawn_elemental_damage_number(enemy, "CHILL", Color(0.4, 0.7, 1.0))
			"lightning":
				AbilityManager.trigger_lightning_at(enemy.global_position)
				_spawn_elemental_damage_number(enemy, "ZAP", Color(1.0, 0.9, 0.4))
		return  # Chaotic strikes replaces other elemental effects

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
	# Check if status text is enabled (these are status indicators like BURN, ZAP, etc.)
	if GameSettings and not GameSettings.status_text_enabled:
		return
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

	# Apply Glass Cannon damage bonus from curses
	if CurseEffects:
		final_damage = CurseEffects.modify_damage_dealt(final_damage)

	return final_damage

# ============================================
# PROJECTILE TRAIL SYSTEM (#19)
# ============================================

func _setup_trail() -> void:
	"""Setup the trail line for the projectile."""
	trail_line = Line2D.new()
	trail_line.width = 3.0
	trail_line.z_index = -1  # Behind the arrow

	# Determine trail color based on modulate/elemental effects
	var trail_color = Color(0.8, 0.8, 0.8, 0.6)  # Default white-ish

	# Will be updated based on arrow type
	if is_mage_orb:
		trail_color = Color(0.4, 0.7, 1.0, 0.7)  # Blue for mage
		trail_line.width = 4.0
	elif is_kobold_orb:
		trail_color = Color(1.0, 1.0, 1.0, 0.7)  # White for kobold priest
		trail_line.width = 4.0
	elif is_necro_orb:
		trail_color = Color(0.5, 0.9, 0.4, 0.7)  # Sickly green for necromancer
		trail_line.width = 4.0

	trail_line.default_color = trail_color

	# Gradient for fading trail
	var gradient = Gradient.new()
	gradient.set_offset(0, 0.0)
	gradient.set_offset(1, 1.0)
	gradient.set_color(0, Color(trail_color.r, trail_color.g, trail_color.b, 0.0))
	gradient.set_color(1, Color(trail_color.r, trail_color.g, trail_color.b, trail_color.a))
	trail_line.gradient = gradient

	# Add as sibling (not child) so it stays in world space
	get_parent().call_deferred("add_child", trail_line)

func _update_trail(delta: float) -> void:
	"""Update the trail with new positions."""
	if trail_line == null or not is_instance_valid(trail_line):
		return

	trail_timer += delta
	if trail_timer >= TRAIL_UPDATE_INTERVAL:
		trail_timer = 0.0

		# Add current position
		trail_points.append(global_position)

		# Limit trail length
		while trail_points.size() > MAX_TRAIL_POINTS:
			trail_points.pop_front()

		# Update line points
		trail_line.clear_points()
		for point in trail_points:
			trail_line.add_point(point)

	# Update trail color based on arrow modulate (for elemental effects)
	if modulate != Color.WHITE and trail_line.gradient:
		var c = modulate
		trail_line.gradient.set_color(0, Color(c.r, c.g, c.b, 0.0))
		trail_line.gradient.set_color(1, Color(c.r, c.g, c.b, 0.7))

func _exit_tree() -> void:
	"""Clean up trail when arrow is freed."""
	if trail_line and is_instance_valid(trail_line):
		# Fade out trail then free it
		var tween = trail_line.create_tween()
		tween.tween_property(trail_line, "modulate:a", 0.0, 0.15)
		tween.tween_callback(trail_line.queue_free)
