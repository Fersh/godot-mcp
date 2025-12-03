extends RefCounted
class_name UltimateAbilityDatabase

# All ultimate abilities organized by class
static var _all_ultimates: Array[UltimateAbilityData] = []
static var _ultimates_by_class: Dictionary = {}
static var _initialized: bool = false

static func initialize() -> void:
	if _initialized:
		return

	_all_ultimates.clear()
	_ultimates_by_class.clear()

	# Initialize class arrays
	for i in range(5):
		_ultimates_by_class[i] = []

	# Register all ultimates
	_register_archer_ultimates()
	_register_knight_ultimates()
	_register_beast_ultimates()
	_register_mage_ultimates()
	_register_monk_ultimates()

	_initialized = true

static func get_ultimates_for_class(character_class: UltimateAbilityData.CharacterClass) -> Array:
	if not _initialized:
		initialize()

	var all_ultimates = _ultimates_by_class.get(character_class, [])
	return _filter_unlocked_ultimates(all_ultimates)

static func get_random_ultimates_for_class(character_class: UltimateAbilityData.CharacterClass, count: int = 3) -> Array:
	if not _initialized:
		initialize()

	var class_ultimates = _filter_unlocked_ultimates(_ultimates_by_class.get(character_class, []))
	class_ultimates.shuffle()

	var result: Array = []
	for i in range(min(count, class_ultimates.size())):
		result.append(class_ultimates[i])
	return result

static func _filter_unlocked_ultimates(ultimates: Array) -> Array:
	"""Filter out locked ultimate abilities."""
	# Get UnlocksManager singleton
	var unlocks_manager = null
	var tree = Engine.get_main_loop()
	if tree and tree.root:
		unlocks_manager = tree.root.get_node_or_null("UnlocksManager")

	if unlocks_manager == null:
		return ultimates.duplicate()

	var filtered: Array = []
	for ultimate in ultimates:
		if unlocks_manager.is_ultimate_unlocked(ultimate.id):
			filtered.append(ultimate)
	return filtered

static func get_ultimate_by_id(id: String) -> UltimateAbilityData:
	if not _initialized:
		initialize()

	for ultimate in _all_ultimates:
		if ultimate.id == id:
			return ultimate
	return null

static func _register_ultimate(ultimate: UltimateAbilityData) -> void:
	_all_ultimates.append(ultimate)
	_ultimates_by_class[ultimate.character_class].append(ultimate)

# =============================================================================
# ARCHER ULTIMATES (5)
# =============================================================================
static func _register_archer_ultimates() -> void:
	# 1. Arrow of Judgment (90s) - Massive single-target nuke
	var arrow_judgment = UltimateAbilityData.new(
		"arrow_of_judgment",
		"Arrow of Judgment",
		"Channel divine energy into a single arrow that deals 5000% damage and executes enemies below 25% HP.",
		UltimateAbilityData.CharacterClass.ARCHER,
		UltimateAbilityData.TargetType.NEAREST_ENEMY,
		90.0
	).with_damage(50.0, 100.0).with_range(800.0).with_activation_pause(0.8)
	_register_ultimate(arrow_judgment)

	# 2. Phantom Volley (120s) - Multi-target burst
	var phantom_volley = UltimateAbilityData.new(
		"phantom_volley",
		"Phantom Volley",
		"Summon 5 spectral archers who fire alongside you for 8 seconds, each dealing 100% of your damage.",
		UltimateAbilityData.CharacterClass.ARCHER,
		UltimateAbilityData.TargetType.SELF,
		120.0
	).with_duration(8.0).with_damage(1.0, 1.0).with_activation_pause(0.75)
	_register_ultimate(phantom_volley)

	# 3. Hunt the Prey (100s) - Mobility + damage
	var hunt_prey = UltimateAbilityData.new(
		"hunt_the_prey",
		"Hunt the Prey",
		"Mark the strongest enemy. Gain 50% move speed and deal 200% damage to them for 10 seconds. Kill resets cooldown by 50%.",
		UltimateAbilityData.CharacterClass.ARCHER,
		UltimateAbilityData.TargetType.NEAREST_ENEMY,
		100.0
	).with_duration(10.0).with_damage(2.0, 2.0).with_activation_pause(0.6)
	_register_ultimate(hunt_prey)

	# 4. Time Dilation Field (150s) - Defensive/utility
	var time_dilation = UltimateAbilityData.new(
		"time_dilation_field",
		"Time Dilation Field",
		"Create a zone where time slows 80% for enemies. Your projectiles inside deal 150% damage. Lasts 6 seconds.",
		UltimateAbilityData.CharacterClass.ARCHER,
		UltimateAbilityData.TargetType.AREA_AROUND_SELF,
		150.0
	).with_duration(6.0).with_aoe(300.0).with_slow(0.8, 6.0).with_damage(1.5, 1.5).with_activation_pause(0.75)
	_register_ultimate(time_dilation)

	# 5. Rain of a Thousand Arrows (180s) - Screen clear
	var rain_arrows = UltimateAbilityData.new(
		"rain_of_thousand_arrows",
		"Rain of a Thousand Arrows",
		"Arrows rain from the sky for 5 seconds, dealing 50% damage per hit to all enemies. Hits 10 times per second.",
		UltimateAbilityData.CharacterClass.ARCHER,
		UltimateAbilityData.TargetType.ALL_ENEMIES,
		180.0
	).with_duration(5.0).with_damage(0.5, 50.0).with_activation_pause(1.0)
	_register_ultimate(rain_arrows)

# =============================================================================
# KNIGHT ULTIMATES (5)
# =============================================================================
static func _register_knight_ultimates() -> void:
	# 1. Aegis of the Immortal (120s) - Invulnerability
	var aegis = UltimateAbilityData.new(
		"aegis_immortal",
		"Aegis of the Immortal",
		"Become completely invulnerable for 5 seconds. Reflect 200% of blocked damage to nearby enemies.",
		UltimateAbilityData.CharacterClass.KNIGHT,
		UltimateAbilityData.TargetType.SELF,
		120.0
	).with_invulnerability(5.0).with_duration(5.0).with_aoe(150.0).with_damage(2.0, 2.0).with_activation_pause(0.8)
	_register_ultimate(aegis)

	# 2. Judgment Day (100s) - AoE nuke
	var judgment = UltimateAbilityData.new(
		"judgment_day",
		"Judgment Day",
		"Leap into the air and crash down, dealing 1500% damage in a massive area and stunning all enemies for 3 seconds.",
		UltimateAbilityData.CharacterClass.KNIGHT,
		UltimateAbilityData.TargetType.AREA_AROUND_SELF,
		100.0
	).with_damage(15.0, 15.0).with_aoe(250.0).with_stun(3.0).with_activation_pause(0.9)
	_register_ultimate(judgment)

	# 3. Unbreakable Will (300s) - Emergency survival
	var unbreakable = UltimateAbilityData.new(
		"unbreakable_will",
		"Unbreakable Will",
		"Passive: When you would die, instead heal to 100% HP and gain 10 seconds of 50% damage reduction. Once per run.",
		UltimateAbilityData.CharacterClass.KNIGHT,
		UltimateAbilityData.TargetType.SELF,
		300.0
	).with_healing(1.0).with_duration(10.0).with_activation_pause(1.0)
	_register_ultimate(unbreakable)

	# 4. Warlord's Challenge (90s) - Tank/aggro
	var challenge = UltimateAbilityData.new(
		"warlords_challenge",
		"Warlord's Challenge",
		"Taunt all enemies to attack you. Gain 75% damage reduction and 100% increased damage for 8 seconds.",
		UltimateAbilityData.CharacterClass.KNIGHT,
		UltimateAbilityData.TargetType.ALL_ENEMIES,
		90.0
	).with_duration(8.0).with_damage(2.0, 2.0).with_activation_pause(0.7)
	_register_ultimate(challenge)

	# 5. Chains of Retribution (150s) - Crowd control
	var chains = UltimateAbilityData.new(
		"chains_retribution",
		"Chains of Retribution",
		"Golden chains erupt, binding all enemies within range for 4 seconds. Bound enemies take 50% more damage.",
		UltimateAbilityData.CharacterClass.KNIGHT,
		UltimateAbilityData.TargetType.AREA_AROUND_SELF,
		150.0
	).with_duration(4.0).with_aoe(350.0).with_stun(4.0).with_damage(1.5, 1.5).with_activation_pause(0.8)
	_register_ultimate(chains)

# =============================================================================
# BEAST ULTIMATES (5)
# =============================================================================
static func _register_beast_ultimates() -> void:
	# 1. Primal Rage (90s) - Transformation
	var primal = UltimateAbilityData.new(
		"primal_rage",
		"Primal Rage",
		"Transform into a dire beast for 10 seconds. Double attack speed, 50% more damage, and heal 5% on each hit.",
		UltimateAbilityData.CharacterClass.BEAST,
		UltimateAbilityData.TargetType.SELF,
		90.0
	).with_transformation().with_duration(10.0).with_damage(1.5, 1.5).with_activation_pause(0.8)
	_register_ultimate(primal)

	# 2. Blood Tempest (100s) - AoE damage
	var tempest = UltimateAbilityData.new(
		"blood_tempest",
		"Blood Tempest",
		"Spin in a whirlwind of claws for 4 seconds, hitting all nearby enemies 5 times per second for 75% damage each.",
		UltimateAbilityData.CharacterClass.BEAST,
		UltimateAbilityData.TargetType.AREA_AROUND_SELF,
		100.0
	).with_duration(4.0).with_aoe(120.0).with_damage(0.75, 15.0).with_activation_pause(0.7)
	_register_ultimate(tempest)

	# 3. Feast of Carnage (120s) - Sustain + damage
	var feast = UltimateAbilityData.new(
		"feast_carnage",
		"Feast of Carnage",
		"For 12 seconds, every kill heals you 10% and increases your damage by 10% (stacks infinitely).",
		UltimateAbilityData.CharacterClass.BEAST,
		UltimateAbilityData.TargetType.SELF,
		120.0
	).with_duration(12.0).with_healing(0.1).with_activation_pause(0.75)
	_register_ultimate(feast)

	# 4. Savage Instinct (150s) - Execute mechanic
	var savage = UltimateAbilityData.new(
		"savage_instinct",
		"Savage Instinct",
		"For 15 seconds, enemies below 30% HP are automatically executed. Each execution extends duration by 1 second.",
		UltimateAbilityData.CharacterClass.BEAST,
		UltimateAbilityData.TargetType.SELF,
		150.0
	).with_duration(15.0).with_activation_pause(0.8)
	_register_ultimate(savage)

	# 5. Apex Predator (180s) - Ultimate hunter
	var apex = UltimateAbilityData.new(
		"apex_predator",
		"Apex Predator",
		"Mark all enemies. Dashing through a marked enemy deals 500% damage and resets your dash. Lasts 8 seconds.",
		UltimateAbilityData.CharacterClass.BEAST,
		UltimateAbilityData.TargetType.ALL_ENEMIES,
		180.0
	).with_duration(8.0).with_damage(5.0, 5.0).with_activation_pause(0.9)
	_register_ultimate(apex)

# =============================================================================
# MAGE ULTIMATES (5)
# =============================================================================
static func _register_mage_ultimates() -> void:
	# 1. Meteor Swarm (120s) - Screen nuke
	var meteor = UltimateAbilityData.new(
		"meteor_swarm",
		"Meteor Swarm",
		"Call down 12 meteors over 4 seconds, each dealing 300% damage in a medium area and leaving burning ground.",
		UltimateAbilityData.CharacterClass.MAGE,
		UltimateAbilityData.TargetType.ALL_ENEMIES,
		120.0
	).with_duration(4.0).with_projectiles(12, 600.0).with_aoe(100.0).with_damage(3.0, 36.0).with_activation_pause(0.9)
	_register_ultimate(meteor)

	# 2. Arcane Singularity (150s) - Black hole
	var singularity = UltimateAbilityData.new(
		"arcane_singularity",
		"Arcane Singularity",
		"Create a black hole that pulls all enemies to center for 3 seconds, then explodes for 2000% damage.",
		UltimateAbilityData.CharacterClass.MAGE,
		UltimateAbilityData.TargetType.AREA_AROUND_SELF,
		150.0
	).with_duration(3.0).with_aoe(400.0).with_damage(20.0, 20.0).with_activation_pause(1.0)
	_register_ultimate(singularity)

	# 3. Time Rewind (180s) - Second chance
	var rewind = UltimateAbilityData.new(
		"time_rewind",
		"Time Rewind",
		"Record your state. After 5 seconds (or on reactivation), return to that position with that HP. Enemies reset too.",
		UltimateAbilityData.CharacterClass.MAGE,
		UltimateAbilityData.TargetType.GLOBAL,
		180.0
	).with_duration(5.0).with_activation_pause(0.75)
	_register_ultimate(rewind)

	# 4. Elemental Mastery (100s) - Multi-element burst
	var elemental = UltimateAbilityData.new(
		"elemental_mastery",
		"Elemental Mastery",
		"Unleash all elements: Fire ring (burn), Ice nova (freeze 2s), Lightning storm (chain 5 enemies). Each deals 200% damage.",
		UltimateAbilityData.CharacterClass.MAGE,
		UltimateAbilityData.TargetType.AREA_AROUND_SELF,
		100.0
	).with_aoe(250.0).with_damage(2.0, 6.0).with_stun(2.0).with_activation_pause(0.85)
	_register_ultimate(elemental)

	# 5. Mirror Dimension (120s) - Clone army
	var mirror = UltimateAbilityData.new(
		"mirror_dimension",
		"Mirror Dimension",
		"Create 4 mirror images that cast your spells at 50% damage for 10 seconds. Images explode on death.",
		UltimateAbilityData.CharacterClass.MAGE,
		UltimateAbilityData.TargetType.SELF,
		120.0
	).with_duration(10.0).with_damage(0.5, 2.0).with_activation_pause(0.8)
	_register_ultimate(mirror)

# =============================================================================
# MONK ULTIMATES (5)
# =============================================================================
static func _register_monk_ultimates() -> void:
	# 1. Thousand Fist Barrage (100s) - Rapid strikes
	var thousand_fist = UltimateAbilityData.new(
		"thousand_fist_barrage",
		"Thousand Fist Barrage",
		"Lock onto nearest enemy and unleash 30 strikes in 3 seconds, each dealing 50% damage. Final hit deals 500%.",
		UltimateAbilityData.CharacterClass.MONK,
		UltimateAbilityData.TargetType.NEAREST_ENEMY,
		100.0
	).with_duration(3.0).with_damage(0.5, 20.0).with_activation_pause(0.9)
	_register_ultimate(thousand_fist)

	# 2. Inner Peace (150s) - Full heal + buff
	var inner_peace = UltimateAbilityData.new(
		"inner_peace",
		"Inner Peace",
		"Enter meditation. Heal to full HP over 3 seconds. During this time, gain 90% damage reduction and cleanse all debuffs.",
		UltimateAbilityData.CharacterClass.MONK,
		UltimateAbilityData.TargetType.SELF,
		150.0
	).with_duration(3.0).with_healing(1.0).with_activation_pause(0.8)
	_register_ultimate(inner_peace)

	# 3. Dragon's Awakening (120s) - Transformation
	var dragon = UltimateAbilityData.new(
		"dragons_awakening",
		"Dragon's Awakening",
		"Channel the dragon spirit for 8 seconds. Attacks create shockwaves that hit all enemies in a line for 100% damage.",
		UltimateAbilityData.CharacterClass.MONK,
		UltimateAbilityData.TargetType.SELF,
		120.0
	).with_transformation().with_duration(8.0).with_damage(1.0, 8.0).with_range(400.0).with_activation_pause(0.9)
	_register_ultimate(dragon)

	# 4. Perfect Harmony (180s) - Ultimate stance
	var harmony = UltimateAbilityData.new(
		"perfect_harmony",
		"Perfect Harmony",
		"For 12 seconds, every 4th attack triggers all three attack animations simultaneously, each dealing full damage.",
		UltimateAbilityData.CharacterClass.MONK,
		UltimateAbilityData.TargetType.SELF,
		180.0
	).with_duration(12.0).with_damage(3.0, 3.0).with_activation_pause(0.85)
	_register_ultimate(harmony)

	# 5. Astral Projection (100s) - Clone + invuln
	var astral = UltimateAbilityData.new(
		"astral_projection",
		"Astral Projection",
		"Leave your body invulnerable while your spirit fights at 200% speed and damage for 6 seconds. Return heals 25%.",
		UltimateAbilityData.CharacterClass.MONK,
		UltimateAbilityData.TargetType.SELF,
		100.0
	).with_duration(6.0).with_invulnerability(6.0).with_damage(2.0, 2.0).with_healing(0.25).with_activation_pause(0.8)
	_register_ultimate(astral)
