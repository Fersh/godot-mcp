extends Node

# Curse Effects Handler - Modular handler for all princess curse effects
# Add to autoload as "CurseEffects"
# This keeps curse logic separate from core game systems for easy maintenance

# Cached effects (refreshed at start of each run)
var _cached_effects: Dictionary = {}
var _effects_cached: bool = false

# Temporal Pressure state
var _temporal_pressure_bonus: float = 0.0
var _game_time: float = 0.0

# Marked for Death state
var _marked_stacks: int = 0
var _marked_timer: float = 0.0

func _ready() -> void:
	# Connect to scene changes to reset cache
	get_tree().node_added.connect(_on_node_added)

func _process(delta: float) -> void:
	if not _effects_cached:
		return

	# Update Temporal Pressure (game speed increase over time)
	if _cached_effects.get("time_scale_increase", 0.0) > 0:
		_game_time += delta
		var per_minute = _cached_effects.get("time_scale_increase", 0.05)
		var max_bonus = _cached_effects.get("time_scale_max", 0.25)
		_temporal_pressure_bonus = min((_game_time / 60.0) * per_minute, max_bonus)
		Engine.time_scale = 1.0 + _temporal_pressure_bonus

	# Update Marked for Death (enemy damage scaling)
	if _cached_effects.get("enemy_damage_scaling", false):
		var interval = _cached_effects.get("enemy_damage_interval", 30.0)
		_marked_timer += delta
		if _marked_timer >= interval:
			_marked_timer = 0.0
			_marked_stacks += 1

func _on_node_added(node: Node) -> void:
	# Reset when entering main game scene
	if node.name == "Main" or node.name == "Player":
		refresh_cache()

# ============================================
# CACHE MANAGEMENT
# ============================================

func refresh_cache() -> void:
	"""Refresh cached effects at start of run."""
	_effects_cached = false
	_temporal_pressure_bonus = 0.0
	_game_time = 0.0
	_marked_stacks = 0
	_marked_timer = 0.0
	Engine.time_scale = 1.0

	if PrincessManager:
		_cached_effects = PrincessManager.get_active_curse_effects()
		_effects_cached = true

func get_effects() -> Dictionary:
	"""Get all active curse effects."""
	if not _effects_cached:
		refresh_cache()
	return _cached_effects

# ============================================
# PLAYER STAT MODIFIERS
# ============================================

func get_starting_hp_multiplier() -> float:
	"""Get starting HP multiplier (Weakened curse)."""
	return get_effects().get("starting_hp", 1.0)

func get_max_hp_reduction() -> float:
	"""Get max HP reduction (Glass Cannon curse)."""
	return get_effects().get("max_hp_reduction", 0.0)

func get_player_speed_multiplier() -> float:
	"""Get player speed multiplier (Exhaustion curse)."""
	return get_effects().get("player_speed_mult", 1.0)

func get_damage_taken_multiplier() -> float:
	"""Get damage taken multiplier (Fragile curse)."""
	return get_effects().get("damage_taken_mult", 1.0)

func get_healing_multiplier() -> float:
	"""Get healing multiplier (Famine curse)."""
	return get_effects().get("healing_mult", 1.0)

func get_damage_dealt_bonus() -> float:
	"""Get damage dealt bonus (Glass Cannon curse)."""
	return get_effects().get("damage_dealt_bonus", 0.0)

func get_luck_multiplier() -> float:
	"""Get luck multiplier (Jinxed curse)."""
	return get_effects().get("luck_mult", 1.0)

func get_visibility_multiplier() -> float:
	"""Get visibility multiplier (Shrouded curse)."""
	return get_effects().get("visibility_mult", 1.0)

# ============================================
# ENEMY/SPAWNING MODIFIERS
# ============================================

func get_spawn_rate_multiplier() -> float:
	"""Get enemy spawn rate multiplier (Horde Mode curse)."""
	return get_effects().get("spawn_rate_mult", 1.0)

func get_elite_spawn_multiplier() -> float:
	"""Get elite spawn frequency multiplier (Chaos Spawn curse)."""
	return get_effects().get("elite_spawn_mult", 1.0)

func get_champion_chance() -> float:
	"""Get champion enemy spawn chance (Champion's Gauntlet curse)."""
	return get_effects().get("champion_chance", 0.0)

func get_enemy_speed_multiplier() -> float:
	"""Get enemy speed multiplier (Berserk Enemies curse)."""
	return get_effects().get("enemy_speed_mult", 1.0)

func get_enemy_damage_multiplier() -> float:
	"""Get enemy damage multiplier including Marked for Death stacks."""
	var base = 1.0
	if _cached_effects.get("enemy_damage_scaling", false):
		var increment = _cached_effects.get("enemy_damage_increment", 0.15)
		base += _marked_stacks * increment
	return base

func get_boss_hp_multiplier() -> float:
	"""Get boss HP multiplier (Blood Moon curse)."""
	return get_effects().get("boss_hp_mult", 1.0)

func get_boss_enrage_threshold() -> float:
	"""Get boss enrage threshold (Blood Moon curse)."""
	return get_effects().get("boss_enrage_threshold", 0.2)

# ============================================
# ECONOMY/PROGRESSION MODIFIERS
# ============================================

func get_gold_drop_multiplier() -> float:
	"""Get gold drop multiplier (Cursed Gold curse)."""
	return get_effects().get("gold_drop_mult", 1.0)

func get_equipment_bonus_multiplier() -> float:
	"""Get equipment bonus multiplier (Brittle Armor curse)."""
	return get_effects().get("equipment_mult", 1.0)

func get_xp_requirement_multiplier() -> float:
	"""Get XP requirement multiplier (Corrupted XP curse)."""
	return get_effects().get("xp_requirement_mult", 1.0)

func get_ability_choices() -> int:
	"""Get number of ability choices when leveling (Sealed Fate curse)."""
	return get_effects().get("ability_choices", 3)

# ============================================
# SPECIAL EFFECTS
# ============================================

func has_bloodprice() -> bool:
	"""Check if Bloodprice curse is active (lose HP on coin pickup)."""
	return get_effects().get("bloodprice", false)

func get_bloodprice_damage() -> int:
	"""Get damage dealt by Bloodprice on coin pickup."""
	return 1  # Fixed 1 HP per coin

func has_hazard_zones() -> bool:
	"""Check if Unstable Ground curse is active."""
	return get_effects().get("hazard_zones", false)

func get_hazard_interval() -> float:
	"""Get hazard zone spawn interval."""
	return get_effects().get("hazard_interval", 10.0)

func get_hazard_damage() -> int:
	"""Get hazard zone damage."""
	return get_effects().get("hazard_damage", 5)

func get_temporal_pressure_bonus() -> float:
	"""Get current time scale bonus from Temporal Pressure."""
	return _temporal_pressure_bonus

# ============================================
# SCORING MULTIPLIER
# ============================================

func get_points_multiplier() -> float:
	"""Get total points/coins multiplier from all active curses."""
	if PrincessManager:
		return PrincessManager.get_total_multiplier()
	return 1.0

func get_bonus_percent() -> int:
	"""Get total bonus as percentage."""
	if PrincessManager:
		return PrincessManager.get_total_bonus_percent()
	return 0

# ============================================
# CONVENIENCE CHECKS
# ============================================

func has_any_curse_active() -> bool:
	"""Check if any curse is currently active."""
	if PrincessManager:
		return PrincessManager.get_enabled_curse_count() > 0
	return false

func get_active_curse_count() -> int:
	"""Get number of active curses."""
	if PrincessManager:
		return PrincessManager.get_enabled_curse_count()
	return 0

# ============================================
# APPLY FUNCTIONS (called by game systems)
# ============================================

func apply_to_player_stats(player: Node) -> void:
	"""Apply curse effects to player stats at start of run."""
	if not _effects_cached:
		refresh_cache()

	# Glass Cannon: Reduce max HP
	var hp_reduction = get_max_hp_reduction()
	if hp_reduction > 0 and player.has_method("get") and "max_health" in player:
		player.max_health = player.max_health * (1.0 - hp_reduction)
		if player.current_health > player.max_health:
			player.current_health = player.max_health

	# Weakened: Start at reduced HP
	var starting_hp = get_starting_hp_multiplier()
	if starting_hp < 1.0 and "current_health" in player and "max_health" in player:
		player.current_health = min(player.current_health, player.max_health * starting_hp)

	# Exhaustion: Reduce move speed
	var speed_mult = get_player_speed_multiplier()
	if speed_mult < 1.0 and "speed" in player:
		player.speed = player.speed * speed_mult
		if "base_speed" in player:
			player.base_speed = player.base_speed * speed_mult

func modify_damage_taken(base_damage: float) -> float:
	"""Modify incoming damage (Fragile curse)."""
	return base_damage * get_damage_taken_multiplier()

func modify_healing(base_healing: float) -> float:
	"""Modify healing amount (Famine curse)."""
	return base_healing * get_healing_multiplier()

func modify_damage_dealt(base_damage: float) -> float:
	"""Modify outgoing damage (Glass Cannon bonus)."""
	return base_damage * (1.0 + get_damage_dealt_bonus())

func modify_enemy_stats(enemy: Node) -> void:
	"""Apply curse effects to enemy stats when spawned."""
	# Berserk Enemies: Increase speed
	var speed_mult = get_enemy_speed_multiplier()
	if speed_mult > 1.0 and "speed" in enemy:
		enemy.speed = enemy.speed * speed_mult

	# Marked for Death: Increase damage
	var damage_mult = get_enemy_damage_multiplier()
	if damage_mult > 1.0 and "damage" in enemy:
		enemy.damage = enemy.damage * damage_mult

func modify_boss_stats(boss: Node) -> void:
	"""Apply curse effects to boss stats when spawned."""
	# Blood Moon: Increase HP
	var hp_mult = get_boss_hp_multiplier()
	if hp_mult > 1.0:
		if "max_health" in boss:
			boss.max_health = boss.max_health * hp_mult
		if "current_health" in boss:
			boss.current_health = boss.current_health * hp_mult
