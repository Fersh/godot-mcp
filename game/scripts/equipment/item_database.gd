extends Node
class_name ItemDatabase

# Quirky prefix/suffix definitions for procedural names
# Format: { "name": { "stat": value, ... } }

const PREFIXES: Dictionary = {
	# Damage prefixes
	"Stabby": {"damage": 0.05},
	"Pointy": {"damage": 0.08},
	"Ouchie": {"damage": 0.10},
	"Mega Bonk": {"damage": 0.15},
	"Yeet-worthy": {"damage": 0.12},

	# Health prefixes
	"Chonky": {"max_hp": 0.08},
	"Thicc": {"max_hp": 0.12},
	"Absolute Unit": {"max_hp": 0.18},
	"Big Boi": {"max_hp": 0.10},
	"Dummy Thicc": {"max_hp": 0.15},

	# Speed prefixes
	"Zoom Zoom": {"move_speed": 0.08},
	"Speedy": {"move_speed": 0.05},
	"Nyoom": {"move_speed": 0.10},
	"Gotta Go Fast": {"move_speed": 0.12},
	"Turbo": {"move_speed": 0.15},

	# Attack speed prefixes
	"Twitchy": {"attack_speed": 0.08},
	"Caffeinated": {"attack_speed": 0.10},
	"Hyperactive": {"attack_speed": 0.12},
	"Button Masher's": {"attack_speed": 0.15},

	# Crit prefixes
	"Lucky": {"crit_chance": 0.05},
	"Calculated": {"crit_chance": 0.08},
	"Big Brain": {"crit_chance": 0.10},
	"Galaxy Brain": {"crit_chance": 0.15},

	# Defense prefixes
	"Cozy": {"damage_reduction": 0.05},
	"Snug": {"damage_reduction": 0.08},
	"Like a Hug": {"damage_reduction": 0.10},
	"Plot Armor": {"damage_reduction": 0.15},
}

const SUFFIXES: Dictionary = {
	# Damage suffixes
	"of Bonking": {"damage": 0.05},
	"of Violence": {"damage": 0.10},
	"of Oof": {"damage": 0.08},
	"of Yikes": {"damage": 0.12},

	# Health suffixes
	"of the Couch Potato": {"max_hp": 0.08},
	"of Bulk": {"max_hp": 0.10},
	"of Not Dying": {"max_hp": 0.15},
	"of Meat Shield": {"max_hp": 0.12},

	# Speed suffixes
	"of Leg Day": {"move_speed": 0.08},
	"of Running Away": {"move_speed": 0.10},
	"of Cardio": {"move_speed": 0.12},
	"of the Wind": {"move_speed": 0.15},

	# Attack speed suffixes
	"of Clickity Clack": {"attack_speed": 0.08},
	"of Spam": {"attack_speed": 0.10},
	"of the Hummingbird": {"attack_speed": 0.12},

	# Utility suffixes
	"of Greed": {"xp_gain": 0.10},
	"of the Nerd": {"xp_gain": 0.15},
	"of Luck": {"luck": 0.08},
	"of RNG": {"luck": 0.12},

	# Defense suffixes
	"of Dodging Responsibility": {"dodge_chance": 0.05},
	"of Nope": {"dodge_chance": 0.08},
	"of the Matrix": {"dodge_chance": 0.10},
	"of Blocking Haters": {"block_chance": 0.08},
}

# Base item templates by slot
const BASE_ITEMS: Dictionary = {
	# WEAPONS - Melee
	"sword_basic": {
		"display_name": "Sword",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.05},
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/swords/sword_1.png"
	},
	"axe_basic": {
		"display_name": "Axe",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.08},
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/axe/axe_1.png"
	},
	"mace_basic": {
		"display_name": "Mace",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.08, "knockback": 20.0},
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/halberds/halberd_1.png"
	},
	"dagger_basic": {
		"display_name": "Dagger",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"attack_speed": 0.10},
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/daggers/dagger_1.png"
	},
	"spear_basic": {
		"display_name": "Spear",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.04, "melee_range": 0.15},
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/spears/spear_1.png"
	},

	# WEAPONS - Ranged
	"bow_basic": {
		"display_name": "Bow",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.05},
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_1.png"
	},
	"crossbow_basic": {
		"display_name": "Crossbow",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.10, "crit_chance": 0.05},
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/crossbows/crossbow_1.png"
	},
	"shortbow_basic": {
		"display_name": "Short Bow",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"attack_speed": 0.08},
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_2.png"
	},
	"longbow_basic": {
		"display_name": "Long Bow",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.06, "projectile_speed": 0.15},
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_3.png"
	},

	# HELMETS - Using wands as helmet icons (magical headgear)
	"helm_basic": {
		"display_name": "Helm",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.05},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_1.png"
	},
	"cap_basic": {
		"display_name": "Cap",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.03},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_2.png"
	},
	"hood_basic": {
		"display_name": "Hood",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"dodge_chance": 0.03},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_3.png"
	},
	"crown_basic": {
		"display_name": "Crown",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"xp_gain": 0.05},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_4.png"
	},

	# CHEST - Common chest armor
	"armor_basic": {
		"display_name": "Armor",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.08},
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon1.png"
	},
	"robe_basic": {
		"display_name": "Robe",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.03, "move_speed": 0.03},
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon2.png"
	},
	"vest_basic": {
		"display_name": "Vest",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"dodge_chance": 0.04},
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon3.png"
	},
	"plate_basic": {
		"display_name": "Plate",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.12, "damage_reduction": 0.03},
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon4.png"
	},

	# BOOTS - Using staves as boot icons (magical footwear)
	"boots_basic": {
		"display_name": "Boots",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.05},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_1.png"
	},
	"sandals_basic": {
		"display_name": "Sandals",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.08, "dodge_chance": 0.02},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_2.png"
	},
	"greaves_basic": {
		"display_name": "Greaves",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.05, "move_speed": 0.02},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_3.png"
	},
	"slippers_basic": {
		"display_name": "Slippers",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"dodge_chance": 0.05},
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_4.png"
	},

	# RINGS
	"ring_basic": {
		"display_name": "Ring",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"damage": 0.03},
		"icon_path": "res://assets/sprites/items/rings/Icon37_01.png"
	},
	"band_basic": {
		"display_name": "Band",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.04},
		"icon_path": "res://assets/sprites/items/rings/Icon37_02.png"
	},
	"signet_basic": {
		"display_name": "Signet",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"crit_chance": 0.03},
		"icon_path": "res://assets/sprites/items/rings/Icon37_03.png"
	},
	"loop_basic": {
		"display_name": "Loop",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"attack_speed": 0.04},
		"icon_path": "res://assets/sprites/items/rings/Icon37_04.png"
	},
}

# Unique items (purple) - fixed names and abilities
const UNIQUE_ITEMS: Dictionary = {
	# Weapons - Melee
	"bonk_stick": {
		"display_name": "The Bonk Stick",
		"description": "For when they need bonking.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.15, "knockback": 50.0},
		"grants_ability": "concussive_hit",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/halberds/halberd_2.png"
	},
	"vampire_fang": {
		"display_name": "Vampire's Toothpick",
		"description": "It's seen some necks.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.10, "attack_speed": 0.10},
		"grants_ability": "vampirism",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/daggers/dagger_2.png"
	},
	"cactus_sword": {
		"display_name": "Ow Ow Ow Blade",
		"description": "Hurts them AND you. Mostly them.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.20},
		"grants_ability": "thorns",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/swords/sword_2.png"
	},
	"rubber_mallet": {
		"display_name": "Squeaky Hammer",
		"description": "*squeak* *squeak* *SQUEAK*",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.08, "attack_speed": 0.20},
		"grants_equipment_ability": "bounce_attack",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/halberds/halberd_3.png"
	},
	"cheese_knife": {
		"display_name": "Le Fromage Slicer",
		"description": "Smells like victory. And cheese.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.12, "crit_chance": 0.10},
		"grants_ability": "bleeding",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/daggers/dagger_3.png"
	},

	# Weapons - Ranged
	"slingshot_deluxe": {
		"display_name": "Dennis's Slingshot",
		"description": "The menace approves.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.10, "projectile_speed": 0.25},
		"grants_ability": "rubber_walls",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_4.png"
	},
	"cupids_bow": {
		"display_name": "Cupid's Discount Bow",
		"description": "Love hurts. Literally.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.08, "attack_speed": 0.15},
		"grants_equipment_ability": "charm_shot",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_5.png"
	},
	"sniper_special": {
		"display_name": "360 No Scope",
		"description": "MLG certified.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.15, "crit_chance": 0.15},
		"grants_ability": "sniper_damage",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/crossbows/crossbow_5.png"
	},
	"shotgun_bow": {
		"display_name": "Bow-zooka",
		"description": "Why shoot one when many do trick?",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.05, "projectile_count": 2},
		"grants_equipment_ability": "spread_shot",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/crossbows/crossbow_4.png"
	},
	"boomerang_bow": {
		"display_name": "The Comeback Kid",
		"description": "It always comes back. ALWAYS.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.12},
		"grants_ability": "rear_shot",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_1.png"
	},

	# Helmets
	"thinking_cap": {
		"display_name": "Thinking Cap",
		"description": "It's not much but it's honest work.",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"xp_gain": 0.20, "crit_chance": 0.05},
		"grants_equipment_ability": "eureka",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_5.png"
	},
	"tin_foil_hat": {
		"display_name": "Tin Foil Hat",
		"description": "They can't read your thoughts now!",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"dodge_chance": 0.10, "max_hp": 0.05},
		"grants_equipment_ability": "paranoia",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_1.png"
	},
	"bucket_helm": {
		"display_name": "Bucket",
		"description": "It's a bucket. On your head.",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.15, "damage_reduction": 0.05},
		"grants_equipment_ability": "tunnel_vision",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_2.png"
	},

	# Chest - Rare
	"dad_bod_armor": {
		"display_name": "Dad Bod Plate",
		"description": "Peak performance. This is it.",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.20, "damage_reduction": 0.08},
		"grants_equipment_ability": "dad_reflexes",
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon20.png"
	},
	"hoodie_of_gaming": {
		"display_name": "Gamer Hoodie",
		"description": "RGB not included.",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"attack_speed": 0.10, "crit_chance": 0.08},
		"grants_equipment_ability": "gamer_mode",
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon25.png"
	},
	"plot_armor_vest": {
		"display_name": "Plot Armor",
		"description": "Main character energy.",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.10, "dodge_chance": 0.08},
		"grants_equipment_ability": "plot_convenience",
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon30.png"
	},

	# Boots
	"moon_shoes": {
		"display_name": "Moon Shoes",
		"description": "Boing boing boing!",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.15, "dodge_chance": 0.05},
		"grants_equipment_ability": "low_gravity",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_5.png"
	},
	"crocs_of_power": {
		"display_name": "Tactical Crocs",
		"description": "In sport mode, obviously.",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.12, "damage": 0.05},
		"grants_equipment_ability": "sport_mode",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_1.png"
	},
	"heelies": {
		"display_name": "Heely Wheelers",
		"description": "Rolling into the danger zone.",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.20},
		"grants_equipment_ability": "momentum",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_2.png"
	},

	# Rings
	"ring_of_procrastination": {
		"display_name": "Ring of Tomorrow",
		"description": "I'll do damage later.",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"damage": 0.08, "attack_speed": 0.08},
		"grants_equipment_ability": "delayed_damage",
		"icon_path": "res://assets/sprites/items/rings/Icon37_05.png"
	},
	"mood_ring": {
		"display_name": "Mood Ring",
		"description": "Currently: Violent",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"crit_chance": 0.08, "damage": 0.05},
		"grants_equipment_ability": "mood_swings",
		"icon_path": "res://assets/sprites/items/rings/Icon37_06.png"
	},
	"one_ring": {
		"display_name": "The One Ring",
		"description": "...to rule the arena.",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"damage": 0.10, "max_hp": 0.10},
		"grants_equipment_ability": "precious",
		"icon_path": "res://assets/sprites/items/rings/Icon37_07.png"
	},
}

# Legendary items (gold) - the best of the best
const LEGENDARY_ITEMS: Dictionary = {
	# Weapons - Melee
	"excalibur_knockoff": {
		"display_name": "Excalibur-ish",
		"description": "Close enough to the real thing.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.30, "crit_chance": 0.15, "attack_speed": 0.10},
		"grants_ability": "cull_weak",
		"grants_equipment_ability": "holy_smite",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/swords/sword_3.png"
	},
	"ban_hammer": {
		"display_name": "The Ban Hammer",
		"description": "You have been banned from life.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.25, "knockback": 100.0},
		"grants_ability": "death_explosion",
		"grants_equipment_ability": "permaban",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/halberds/halberd_4.png"
	},
	"infinity_blade": {
		"display_name": "Infinity Blade +1",
		"description": "One more than infinity.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.20, "attack_speed": 0.20, "crit_chance": 0.10},
		"grants_ability": "whirlwind",
		"grants_equipment_ability": "scaling_damage",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/swords/sword_4.png"
	},
	"spaghetti_sword": {
		"display_name": "Mom's Spaghetti Sword",
		"description": "Palms are sweaty.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.18, "max_hp": 0.15},
		"grants_ability": "vampirism",
		"grants_equipment_ability": "comfort_food",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/swords/sword_5.png"
	},
	"nerf_sword": {
		"display_name": "Nerf Sword (Pre-Nerf)",
		"description": "Before the devs got to it.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.MELEE,
		"base_stats": {"damage": 0.35, "attack_speed": 0.15},
		"grants_equipment_ability": "overtuned",
		"icon_path": "res://assets/sprites/items/Melee/TRANSPARENT/swords/sword_6.png"
	},

	# Weapons - Ranged
	"aimbot_bow": {
		"display_name": "Definitely Not Aimbot",
		"description": "Just good gaming chair.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.20, "crit_chance": 0.25, "projectile_speed": 0.20},
		"grants_ability": "pierce",
		"grants_equipment_ability": "auto_aim",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_2.png"
	},
	"lag_switch_bow": {
		"display_name": "The Lag Switch",
		"description": "Connection issues intensify.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.15, "attack_speed": 0.25},
		"grants_equipment_ability": "rubber_banding",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/crossbows/crossbow_2.png"
	},
	"pay_to_win_bow": {
		"display_name": "P2W Premium Bow",
		"description": "$99.99 well spent.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.25, "projectile_count": 2, "crit_chance": 0.15},
		"grants_ability": "ring_of_fire",
		"grants_equipment_ability": "whale_power",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_4.png"
	},
	"chaos_crossbow": {
		"display_name": "Chaotic Crossbow",
		"description": "Even you don't know what it'll do.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.20, "attack_speed": 0.15},
		"grants_ability": "lightning_strike",
		"grants_equipment_ability": "random_effects",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/crossbows/crossbow_4.png"
	},
	"machine_gun_bow": {
		"display_name": "Bow Go BRRRR",
		"description": "Geneva Convention? Never heard of it.",
		"slot": ItemData.Slot.WEAPON,
		"weapon_type": ItemData.WeaponType.RANGED,
		"base_stats": {"damage": 0.05, "attack_speed": 0.40, "projectile_count": 1},
		"grants_equipment_ability": "bullet_hell",
		"icon_path": "res://assets/sprites/items/Range/TRANSPARENT/bows/bow_1.png"
	},

	# Helmets
	"galaxy_brain_helm": {
		"display_name": "Galaxy Brain Helm",
		"description": "IQ: Yes",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"xp_gain": 0.30, "crit_chance": 0.15, "damage": 0.10},
		"grants_equipment_ability": "big_brain_plays",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_3.png"
	},
	"anime_protagonist_hair": {
		"display_name": "Protagonist Hair",
		"description": "Power level: Over 9000",
		"slot": ItemData.Slot.HELMET,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"damage": 0.20, "max_hp": 0.15, "crit_chance": 0.10},
		"grants_ability": "frenzy",
		"grants_equipment_ability": "power_of_friendship",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Wands/wand_4.png"
	},

	# Chest - Epic
	"gamer_chair": {
		"display_name": "Gaming Chair Armor",
		"description": "100% skill, trust me.",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.25, "damage": 0.15, "attack_speed": 0.10},
		"grants_equipment_ability": "gaming_posture",
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon45.png"
	},
	"mithril_hoodie": {
		"display_name": "Mithril Hoodie",
		"description": "Light as a feather, cozy as heck.",
		"slot": ItemData.Slot.CHEST,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.20, "dodge_chance": 0.15, "move_speed": 0.10},
		"grants_ability": "deflect",
		"grants_equipment_ability": "ethereal",
		"icon_path": "res://assets/sprites/items/chest/png/transperent/Icon48.png"
	},

	# Boots
	"sonic_shoes": {
		"display_name": "Red Running Shoes",
		"description": "Gotta go fast!",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.30, "attack_speed": 0.15},
		"grants_ability": "adrenaline",
		"grants_equipment_ability": "spin_dash",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_3.png"
	},
	"rocket_boots": {
		"display_name": "Rocket Boots",
		"description": "OSHA violation in 3... 2...",
		"slot": ItemData.Slot.BOOTS,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"move_speed": 0.25, "damage": 0.10},
		"grants_equipment_ability": "rocket_jump",
		"icon_path": "res://assets/sprites/items/Magic/TRANSPARENT/Staves/staff_4.png"
	},

	# Rings
	"infinity_gauntlet_ring": {
		"display_name": "Infinity Ring",
		"description": "Perfectly balanced, as all things should be.",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"damage": 0.15, "max_hp": 0.15, "crit_chance": 0.15},
		"grants_equipment_ability": "snap",
		"icon_path": "res://assets/sprites/items/rings/Icon37_08.png"
	},
	"wedding_ring": {
		"display_name": "Ring of Commitment",
		"description": "Till death do us part. So... soon.",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.25, "damage_reduction": 0.10},
		"grants_equipment_ability": "til_death",
		"icon_path": "res://assets/sprites/items/rings/Icon37_09.png"
	},
	"ring_pop": {
		"display_name": "Ancient Ring Pop",
		"description": "Still tastes good after 1000 years.",
		"slot": ItemData.Slot.RING_1,
		"weapon_type": ItemData.WeaponType.NONE,
		"base_stats": {"max_hp": 0.20, "attack_speed": 0.15},
		"grants_ability": "regeneration",
		"grants_equipment_ability": "sugar_rush",
		"icon_path": "res://assets/sprites/items/rings/Icon37_10.png"
	},
}

# Equipment-exclusive abilities (not in main ability pool)
const EQUIPMENT_ABILITIES: Dictionary = {
	"bounce_attack": {
		"name": "Bouncy",
		"description": "Attacks bounce to nearby enemies"
	},
	"charm_shot": {
		"name": "Charm Shot",
		"description": "Small chance to make enemies fight each other"
	},
	"spread_shot": {
		"name": "Spread Shot",
		"description": "Projectiles fire in a cone"
	},
	"eureka": {
		"name": "Eureka!",
		"description": "Chance for double XP on pickup"
	},
	"paranoia": {
		"name": "Paranoia",
		"description": "Enemies near you take damage over time"
	},
	"tunnel_vision": {
		"name": "Tunnel Vision",
		"description": "More damage to enemies directly in front"
	},
	"dad_reflexes": {
		"name": "Dad Reflexes",
		"description": "Chance to auto-dodge lethal hits"
	},
	"gamer_mode": {
		"name": "Gamer Mode",
		"description": "Damage increases the longer you don't get hit"
	},
	"plot_convenience": {
		"name": "Plot Armor",
		"description": "Survive lethal hit once per run"
	},
	"low_gravity": {
		"name": "Low Gravity",
		"description": "Increased knockback on enemies"
	},
	"sport_mode": {
		"name": "Sport Mode",
		"description": "Move faster when moving toward enemies"
	},
	"momentum": {
		"name": "Momentum",
		"description": "Speed builds up over time, resets when hit"
	},
	"delayed_damage": {
		"name": "Procrastination",
		"description": "Damage dealt after a short delay, but increased"
	},
	"mood_swings": {
		"name": "Mood Swings",
		"description": "Random stat bonuses that change periodically"
	},
	"precious": {
		"name": "My Precious",
		"description": "Gain power when low on health"
	},
	"holy_smite": {
		"name": "Holy Smite",
		"description": "Critical hits trigger lightning"
	},
	"permaban": {
		"name": "Permaban",
		"description": "Killed enemies can't respawn (reduces spawn rate)"
	},
	"scaling_damage": {
		"name": "Infinite Scaling",
		"description": "Damage increases with each kill"
	},
	"comfort_food": {
		"name": "Comfort Food",
		"description": "Heal when you kill enemies"
	},
	"overtuned": {
		"name": "Pre-Nerf",
		"description": "All stats slightly increased"
	},
	"auto_aim": {
		"name": "Aim Assist",
		"description": "Projectiles home toward enemies slightly"
	},
	"rubber_banding": {
		"name": "Rubber Banding",
		"description": "Teleport short distance when taking damage"
	},
	"whale_power": {
		"name": "Whale Power",
		"description": "More coins drop from enemies"
	},
	"random_effects": {
		"name": "Chaos",
		"description": "Random ability effect on each hit"
	},
	"bullet_hell": {
		"name": "Bullet Hell",
		"description": "Fire rate increases dramatically at low health"
	},
	"big_brain_plays": {
		"name": "Big Brain",
		"description": "Enemies drop more XP"
	},
	"power_of_friendship": {
		"name": "Friendship",
		"description": "Get stronger when near death"
	},
	"gaming_posture": {
		"name": "Gaming Posture",
		"description": "All incoming damage reduced"
	},
	"ethereal": {
		"name": "Ethereal",
		"description": "Phase through enemies briefly after taking damage"
	},
	"spin_dash": {
		"name": "Spin Dash",
		"description": "Build speed while not attacking, release for damage"
	},
	"rocket_jump": {
		"name": "Rocket Jump",
		"description": "Taking damage boosts movement speed"
	},
	"snap": {
		"name": "Snap",
		"description": "Chance to instantly kill enemies below 50% HP"
	},
	"til_death": {
		"name": "Till Death",
		"description": "Gain damage reduction when below 30% HP"
	},
	"sugar_rush": {
		"name": "Sugar Rush",
		"description": "Healing also increases attack speed briefly"
	},
}

static func get_base_item_ids_for_slot(slot: ItemData.Slot) -> Array:
	var ids = []
	for id in BASE_ITEMS:
		var item = BASE_ITEMS[id]
		var item_slot = item.get("slot", ItemData.Slot.WEAPON)
		# Rings can go in either ring slot
		if slot == ItemData.Slot.RING_2 and item_slot == ItemData.Slot.RING_1:
			ids.append(id)
		elif item_slot == slot:
			ids.append(id)
	return ids

static func get_random_prefix() -> Dictionary:
	var keys = PREFIXES.keys()
	var key = keys[randi() % keys.size()]
	return {"name": key, "stats": PREFIXES[key]}

static func get_random_suffix() -> Dictionary:
	var keys = SUFFIXES.keys()
	var key = keys[randi() % keys.size()]
	return {"name": key, "stats": SUFFIXES[key]}

static func get_unique_items_for_slot(slot: ItemData.Slot) -> Array:
	var items = []
	for id in UNIQUE_ITEMS:
		var item = UNIQUE_ITEMS[id]
		var item_slot = item.get("slot", ItemData.Slot.WEAPON)
		if slot == ItemData.Slot.RING_2 and item_slot == ItemData.Slot.RING_1:
			items.append(id)
		elif item_slot == slot:
			items.append(id)
	return items

static func get_legendary_items_for_slot(slot: ItemData.Slot) -> Array:
	var items = []
	for id in LEGENDARY_ITEMS:
		var item = LEGENDARY_ITEMS[id]
		var item_slot = item.get("slot", ItemData.Slot.WEAPON)
		if slot == ItemData.Slot.RING_2 and item_slot == ItemData.Slot.RING_1:
			items.append(id)
		elif item_slot == slot:
			items.append(id)
	return items
