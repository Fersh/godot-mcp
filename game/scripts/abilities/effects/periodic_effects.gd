extends RefCounted
class_name PeriodicEffects

# Handles all periodic/tick-based ability effects
# Extracted from ability_manager.gd for modularity

# Constants for periodic effects
const TESLA_INTERVAL: float = 0.8
const RING_OF_FIRE_INTERVAL: float = 3.0
const LIGHTNING_INTERVAL: float = 2.0
const TOXIC_INTERVAL: float = 0.5
const TOXIC_RADIUS: float = 100.0

# Timers
var regen_timer: float = 0.0
var tesla_timer: float = 0.0
var ring_of_fire_timer: float = 0.0
var lightning_timer: float = 0.0
var toxic_timer: float = 0.0

# Reference to ability manager for state access
var _manager: Node = null

func _init(manager: Node) -> void:
	_manager = manager

func reset() -> void:
	regen_timer = 0.0
	tesla_timer = 0.0
	ring_of_fire_timer = 0.0
	lightning_timer = 0.0
	toxic_timer = 0.0

func process(delta: float, player: Node2D) -> void:
	_process_regeneration(delta, player)
	_process_focus_regen(delta, player)
	_process_divine_shield(delta)
	_process_tesla_coil(delta, player)
	_process_ring_of_fire(delta, player)
	_process_lightning_strike(delta, player)
	_process_toxic_cloud(delta, player)
	_process_static_charge(delta)
	_process_berserker_fury(delta)
	_process_vengeance(delta)
	_process_kill_streaks(delta)
	_process_soul_reaper(delta)
	_process_warmup()
	_process_summoner(delta, player)
	_process_chrono_trigger(delta)
	_process_mirror_shield(delta)
	_process_immortal_oath(delta, player)
	_process_transcendence(delta, player)

# ============================================
# REGENERATION
# ============================================

func _process_regeneration(delta: float, player: Node2D) -> void:
	var total_regen = _manager.get_regen_rate()
	if total_regen > 0 or _manager.has_regen or _manager.has_permanent_regen():
		regen_timer += delta
		if regen_timer >= 1.0:
			regen_timer = 0.0
			# Heal as percentage of max HP
			heal_player(player, player.max_health * total_regen * 0.01)

func _process_focus_regen(delta: float, player: Node2D) -> void:
	if _manager.has_focus_regen and player.has_method("get_velocity"):
		var velocity = player.get_velocity() if player.has_method("get_velocity") else player.velocity
		if velocity.length() < 5.0:  # Standing still
			heal_player(player, _manager.focus_regen_rate * delta)

# ============================================
# DIVINE SHIELD
# ============================================

func _process_divine_shield(delta: float) -> void:
	if _manager.divine_shield_active:
		_manager.divine_shield_timer -= delta
		if _manager.divine_shield_timer <= 0:
			_manager.divine_shield_active = false

# ============================================
# TESLA COIL
# ============================================

func _process_tesla_coil(delta: float, player: Node2D) -> void:
	if _manager.has_tesla_coil:
		tesla_timer += delta
		if tesla_timer >= TESLA_INTERVAL:
			tesla_timer = 0.0
			fire_tesla_coil(player)

func fire_tesla_coil(player: Node2D) -> void:
	var enemies = player.get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = 200.0  # Tesla range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	if closest and closest.has_method("take_damage"):
		closest.take_damage(_manager.tesla_damage * _manager.get_passive_damage_multiplier())
		spawn_lightning_effect(player, player.global_position, closest.global_position)

# ============================================
# RING OF FIRE
# ============================================

func _process_ring_of_fire(delta: float, player: Node2D) -> void:
	if _manager.has_ring_of_fire:
		ring_of_fire_timer += delta
		if ring_of_fire_timer >= RING_OF_FIRE_INTERVAL:
			ring_of_fire_timer = 0.0
			fire_ring_of_fire(player)

func fire_ring_of_fire(player: Node2D) -> void:
	if not player.has_method("spawn_arrow"):
		return

	var angle_step = TAU / _manager.ring_projectile_count
	for i in _manager.ring_projectile_count:
		var angle = i * angle_step
		var direction = Vector2(cos(angle), sin(angle))
		spawn_ring_projectile(player, direction)

func spawn_ring_projectile(player: Node2D, direction: Vector2) -> void:
	if player.arrow_scene == null:
		return

	var arrow = player.arrow_scene.instantiate()
	arrow.global_position = player.global_position
	arrow.direction = direction
	player.get_parent().add_child(arrow)

# ============================================
# LIGHTNING STRIKE
# ============================================

func _process_lightning_strike(delta: float, player: Node2D) -> void:
	if _manager.has_lightning_strike:
		lightning_timer += delta
		if lightning_timer >= LIGHTNING_INTERVAL:
			lightning_timer = 0.0
			strike_lightning(player)

func strike_lightning(player: Node2D) -> void:
	var enemies = player.get_tree().get_nodes_in_group("enemies")
	if enemies.size() == 0:
		return

	# Filter to only enemies visible on screen
	var camera = player.get_tree().get_first_node_in_group("camera")
	var visible_enemies: Array = []

	if camera:
		var viewport_size = player.get_viewport().get_visible_rect().size
		var cam_pos = camera.global_position
		var half_width = viewport_size.x / 2 * 1.2
		var half_height = viewport_size.y / 2 * 1.2

		for enemy in enemies:
			if is_instance_valid(enemy):
				var diff = enemy.global_position - cam_pos
				if abs(diff.x) < half_width and abs(diff.y) < half_height:
					visible_enemies.append(enemy)
	else:
		visible_enemies = enemies.filter(func(e): return is_instance_valid(e))

	if visible_enemies.size() == 0:
		return

	# Pick random visible enemy
	var target = visible_enemies[randi() % visible_enemies.size()]
	if target and target.has_method("take_damage"):
		target.take_damage(_manager.lightning_damage * _manager.get_passive_damage_multiplier())
		spawn_lightning_bolt(player, target.global_position)

# ============================================
# TOXIC CLOUD
# ============================================

func _process_toxic_cloud(delta: float, player: Node2D) -> void:
	if _manager.has_toxic_cloud:
		toxic_timer += delta
		if toxic_timer >= TOXIC_INTERVAL:
			toxic_timer = 0.0
			apply_toxic_damage(player)

func apply_toxic_damage(player: Node2D) -> void:
	var enemies = player.get_tree().get_nodes_in_group("enemies")
	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = player.global_position.distance_to(enemy.global_position)
			if dist <= TOXIC_RADIUS and enemy.has_method("take_damage"):
				enemy.take_damage(_manager.toxic_dps * _manager.get_passive_damage_multiplier())

# ============================================
# STATIC CHARGE
# ============================================

func _process_static_charge(delta: float) -> void:
	if _manager.has_static_charge:
		_manager.static_charge_timer += delta
		if _manager.static_charge_timer >= _manager.static_charge_interval:
			_manager.static_charge_timer = 0.0
			_manager.static_charge_ready = true

# ============================================
# BERSERKER FURY
# ============================================

func _process_berserker_fury(delta: float) -> void:
	if _manager.has_berserker_fury and _manager.berserker_fury_stacks > 0:
		_manager.berserker_fury_timer -= delta
		if _manager.berserker_fury_timer <= 0:
			_manager.berserker_fury_stacks = 0

# ============================================
# VENGEANCE
# ============================================

func _process_vengeance(delta: float) -> void:
	if _manager.vengeance_active:
		_manager.vengeance_timer -= delta
		if _manager.vengeance_timer <= 0:
			_manager.vengeance_active = false

# ============================================
# KILL STREAKS
# ============================================

func _process_kill_streaks(delta: float) -> void:
	# Rampage decay
	if _manager.has_rampage and _manager.rampage_stacks > 0:
		_manager.rampage_timer -= delta
		if _manager.rampage_timer <= 0:
			_manager.rampage_stacks = 0

	# Killing Frenzy decay
	if _manager.has_killing_frenzy and _manager.killing_frenzy_stacks > 0:
		_manager.killing_frenzy_timer -= delta
		if _manager.killing_frenzy_timer <= 0:
			_manager.killing_frenzy_stacks = 0

	# Massacre decay
	if _manager.has_massacre and _manager.massacre_stacks > 0:
		_manager.massacre_timer -= delta
		if _manager.massacre_timer <= 0:
			_manager.massacre_stacks = 0

# ============================================
# SOUL REAPER
# ============================================

func _process_soul_reaper(delta: float) -> void:
	if _manager.has_soul_reaper and _manager.soul_reaper_stacks > 0:
		_manager.soul_reaper_timer -= delta
		if _manager.soul_reaper_timer <= 0:
			_manager.soul_reaper_stacks = 0

# ============================================
# WARMUP
# ============================================

func _process_warmup() -> void:
	if _manager.has_warmup and _manager.warmup_active:
		var current_time = Time.get_ticks_msec() / 1000.0
		if current_time - _manager.run_start_time > _manager.run_duration_for_warmup:
			_manager.warmup_active = false

# ============================================
# SUMMONER
# ============================================

func _process_summoner(delta: float, player: Node2D) -> void:
	if _manager.has_summoner:
		_manager.summoner_timer += delta
		if _manager.summoner_timer >= _manager.summoner_interval and _manager.skeleton_count < _manager.MAX_SKELETONS:
			_manager.summoner_timer = 0.0
			_manager.spawn_skeleton(player)

# ============================================
# CHRONO TRIGGER
# ============================================

func _process_chrono_trigger(delta: float) -> void:
	if _manager.has_chrono_trigger:
		_manager.chrono_trigger_timer += delta
		if _manager.chrono_trigger_timer >= _manager.chrono_trigger_interval:
			_manager.chrono_trigger_timer = 0.0
			_manager.trigger_chrono_freeze()

# ============================================
# MIRROR SHIELD
# ============================================

func _process_mirror_shield(delta: float) -> void:
	if _manager.has_mirror_shield:
		_manager.mirror_shield_timer += delta
		if _manager.mirror_shield_timer >= _manager.mirror_shield_interval:
			_manager.mirror_shield_timer = 0.0
			_manager.mirror_shield_ready = true

# ============================================
# IMMORTAL OATH
# ============================================

func _process_immortal_oath(delta: float, player: Node2D) -> void:
	if _manager.immortal_oath_active:
		_manager.immortal_oath_timer -= delta
		if _manager.immortal_oath_timer <= 0:
			_manager.immortal_oath_active = false
			# If player didn't heal above 1 HP, they die
			if player.has_method("get_health") and player.get_health() <= 1:
				if player.has_method("force_death"):
					player.force_death()

# ============================================
# TRANSCENDENCE
# ============================================

func _process_transcendence(delta: float, player: Node2D) -> void:
	if _manager.has_transcendence and _manager.transcendence_shields < _manager.transcendence_max:
		var regen_amount = minf(delta * 2.5, _manager.transcendence_max - _manager.transcendence_shields)
		_manager.transcendence_shields += regen_amount
		_manager.transcendence_accumulated_regen += regen_amount
		# Show +x every time we accumulate 1 or more
		if _manager.transcendence_accumulated_regen >= 1.0:
			var display_amount = floor(_manager.transcendence_accumulated_regen)
			_manager.spawn_shield_gain_number(player, display_amount)
			_manager.transcendence_accumulated_regen -= display_amount

# ============================================
# HELPER FUNCTIONS
# ============================================

func heal_player(player: Node2D, amount: float, play_sound: bool = false) -> void:
	if player.has_method("heal"):
		player.heal(amount, play_sound)

func spawn_lightning_effect(player: Node2D, from: Vector2, to: Vector2) -> void:
	# Delegate to manager for now (has scene references)
	_manager.spawn_lightning_effect(from, to)

func spawn_lightning_bolt(player: Node2D, pos: Vector2) -> void:
	# Delegate to manager for now (has scene references)
	_manager.spawn_lightning_bolt(pos)
