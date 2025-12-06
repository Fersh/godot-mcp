extends RefCounted
class_name DescriptionFormatter

## Utility class for formatting ability descriptions with BBCode
## Colors and bolds keywords, numbers, and status effects for better readability

# Color definitions (hex codes for BBCode)
const COLOR_WHITE = "#FFFFFF"        # Numbers, percentages, values
const COLOR_RED = "#FF4444"          # Damage keywords, negative values
const COLOR_FIRE = "#FF6A00"         # Fire/Burn effects
const COLOR_ICE = "#00BFFF"          # Ice/Frost/Slow effects
const COLOR_LIGHTNING = "#FFD700"    # Lightning/Shock/Stun effects
const COLOR_POISON = "#32CD32"       # Poison/Toxic effects
const COLOR_BLEED = "#DC143C"        # Bleed/Physical DOT
const COLOR_HEAL = "#00FF7F"         # Healing/HP/Life effects
const COLOR_DEFENSE = "#4682B4"      # Shield/Armor/Block effects
const COLOR_SPEED = "#00FFFF"        # Speed/Haste effects
const COLOR_CC = "#9370DB"           # Crowd control (non-elemental)
const COLOR_BUFF = "#FFD700"         # Buffs/Empowerment
const COLOR_SUMMON = "#B19CD9"       # Summons/Minions
const COLOR_LOOT = "#FFD700"         # Drops/Loot/Coins (gold color)

# Keyword categories - order matters for proper matching
# More specific phrases should come before shorter ones

static var FIRE_KEYWORDS: Array[String] = [
	"burning ground", "burning", "burns", "burn", "fire trail", "fire ring", "fire",
	"fireball", "flame wall", "flame orbit", "flame", "flames",
	"ignite", "ignites", "igniting", "blazing trail", "blazing", "magma", "lava",
	"meteor swarm", "meteor strike", "meteor", "meteors"
]

static var ICE_KEYWORDS: Array[String] = [
	"freezing", "freezes", "freeze", "frozen", "frost nova", "frost orbit", "frostbite", "frost",
	"chilling", "chills", "chill", "chilled", "ice barricade", "ice nova", "ice shard", "ice",
	"cold", "slowing", "slows", "slowed", "slow"
]

static var LIGHTNING_KEYWORDS: Array[String] = [
	"chain lightning", "lightning storm", "lightning strike", "lightning",
	"thunderstorm", "thundershock", "thunder", "shock", "shocked", "shocks",
	"static charge", "static", "electric", "arc", "arcs",
	"stunning", "stunned", "stuns", "stun"
]

static var POISON_KEYWORDS: Array[String] = [
	"poisoned", "poisons", "poisoning", "poison", "toxic cloud", "toxic tip", "toxic traits", "toxic",
	"venom", "venomous", "toxin"
]

static var BLEED_KEYWORDS: Array[String] = [
	"bleeding", "bleeds", "bleed", "crimson edge", "crimson", "physical"
]

static var HEAL_KEYWORDS: Array[String] = [
	"regenerate", "regeneration", "regenerating", "regen",
	"heal nova", "healing light", "healing", "heals", "heal",
	"health pickups", "health pickup", "health", "lifesteal",
	"restore", "restores", "revive", "revives",
	"max hp", "hp"
]

static var DEFENSE_KEYWORDS: Array[String] = [
	"invulnerable", "invulnerability", "divine shield",
	"damage reduction", "shield bubble", "shield",
	"armor breaker", "armor", "block", "blocked", "blocks",
	"parry", "deflect", "deflection", "reflect", "reflects",
	"invisibility", "invisible"
]

static var SPEED_KEYWORDS: Array[String] = [
	"attack speed", "move speed", "movement speed", "projectile speed",
	"fire rate", "cooldown", "cooldowns",
	"haste", "dash", "dashes", "dashing",
	"roll", "dodge", "dodging"
]

static var DAMAGE_KEYWORDS: Array[String] = [
	"critical hit", "crit chance", "crit", "critical",
	"execute", "executes", "executing", "execution",
	"knockback", "damaging", "damages", "damage",
	"exploding", "explodes", "explode", "explosion"
]

static var CC_KEYWORDS: Array[String] = [
	"rooted", "root", "roots", "rooting",
	"taunt", "taunts", "taunting",
	"confuse", "confused", "confusing", "confusion",
	"charmed", "charming", "charms", "charm",
	"fear", "fears", "fearing", "flee", "fleeing", "terrify", "terrifying", "terror",
	"weaken", "weakens", "weakening", "weakened",
	"immobilize", "immobilizes", "immobilized",
	"blind", "blinds", "blinded", "blinding"
]

static var BUFF_KEYWORDS: Array[String] = [
	"boost", "boosts", "boosting",
	"buff", "buffs",
	"empower", "empowers", "empowered",
	"amplify", "amplifies",
	"enhance", "enhances", "enhanced",
	"increase", "increases", "increased",
	"gain", "gains", "grant", "grants"
]

static var SUMMON_KEYWORDS: Array[String] = [
	"skeleton warriors", "skeleton", "skeletons",
	"summon golem", "golem", "golems",
	"drone support", "drone", "drones",
	"sentry turret", "sentry network", "turret", "turrets",
	"mirror clone", "clone", "clones",
	"minion", "minions",
	"companion", "companions",
	"spectral archers", "spectral sword", "spectral",
	"ghostly wolves", "wolves", "wolf",
	"chicken", "chickens",
	"decoy", "decoys"
]

static var LOOT_KEYWORDS: Array[String] = [
	"dropping", "drops", "drop",
	"loot", "looting",
	"coins", "coin",
	"gold", "treasure",
	"pickups", "pickup",
	"gems", "gem",
	"xp"
]

## Format a description string with BBCode colors and bold
static func format(text: String) -> String:
	if text.is_empty():
		return text

	var result = text

	# First, handle numbers and percentages (bold + white)
	result = _format_numbers(result)

	# Then handle keywords by category
	result = _format_keywords(result, FIRE_KEYWORDS, COLOR_FIRE)
	result = _format_keywords(result, ICE_KEYWORDS, COLOR_ICE)
	result = _format_keywords(result, LIGHTNING_KEYWORDS, COLOR_LIGHTNING)
	result = _format_keywords(result, POISON_KEYWORDS, COLOR_POISON)
	result = _format_keywords(result, BLEED_KEYWORDS, COLOR_BLEED)
	result = _format_keywords(result, HEAL_KEYWORDS, COLOR_HEAL)
	result = _format_keywords(result, DEFENSE_KEYWORDS, COLOR_DEFENSE)
	result = _format_keywords(result, SPEED_KEYWORDS, COLOR_SPEED)
	result = _format_keywords(result, DAMAGE_KEYWORDS, COLOR_RED)
	result = _format_keywords(result, CC_KEYWORDS, COLOR_CC)
	result = _format_keywords(result, BUFF_KEYWORDS, COLOR_BUFF)
	result = _format_keywords(result, SUMMON_KEYWORDS, COLOR_SUMMON)
	result = _format_keywords(result, LOOT_KEYWORDS, COLOR_LOOT)

	# Wrap in center tags for center alignment
	return "[center]" + result + "[/center]"

## Format numbers and percentages with bold white
static func _format_numbers(text: String) -> String:
	var result = text

	# Regex to match numbers with optional +/- prefix and % suffix
	# Matches: +20%, -30, 1500%, 2.5 seconds, 5s, etc.
	var regex = RegEx.new()

	# Match patterns like: +20%, -30%, 20%, +20, -30, 1500, 2.5, etc.
	# Also matches "X seconds", "Xs", "X damage", etc.
	regex.compile("([+-]?\\d+\\.?\\d*)(%|s\\b| seconds?| sec)?")

	var matches = regex.search_all(text)

	# Process matches in reverse order to preserve positions
	var sorted_matches = matches.duplicate()
	sorted_matches.sort_custom(func(a, b): return a.get_start() > b.get_start())

	for m in sorted_matches:
		var full_match = m.get_string()
		var start = m.get_start()
		var end = m.get_end()

		# Skip if already inside BBCode tags
		if _is_inside_bbcode(result, start):
			continue

		# Check if this is a negative value (for red coloring)
		var is_negative = full_match.begins_with("-")
		var color = COLOR_RED if is_negative else COLOR_WHITE

		var formatted = "[b][color=" + color + "]" + full_match + "[/color][/b]"
		result = result.substr(0, start) + formatted + result.substr(end)

	return result

## Format keywords with specified color
static func _format_keywords(text: String, keywords: Array[String], color: String) -> String:
	var result = text

	# Sort keywords by length (longest first) to match longer phrases first
	var sorted_keywords = keywords.duplicate()
	sorted_keywords.sort_custom(func(a, b): return a.length() > b.length())

	for keyword in sorted_keywords:
		var regex = RegEx.new()
		# Case-insensitive word boundary match
		regex.compile("(?i)\\b(" + _escape_regex(keyword) + ")\\b")

		var matches = regex.search_all(result)

		# Process in reverse order
		var sorted_matches = matches.duplicate()
		sorted_matches.sort_custom(func(a, b): return a.get_start() > b.get_start())

		for m in sorted_matches:
			var matched_text = m.get_string(1)  # Get the captured group
			var start = m.get_start()
			var end = m.get_end()

			# Skip if already inside BBCode tags
			if _is_inside_bbcode(result, start):
				continue

			var formatted = "[b][color=" + color + "]" + matched_text + "[/color][/b]"
			result = result.substr(0, start) + formatted + result.substr(end)

	return result

## Check if a position is inside BBCode tags (to avoid double-formatting)
static func _is_inside_bbcode(text: String, pos: int) -> bool:
	# Count open and close tags before this position
	var before = text.substr(0, pos)

	# Check if we're between [ and ]
	var last_open = before.rfind("[")
	var last_close = before.rfind("]")

	if last_open > last_close:
		return true  # We're inside a tag definition

	# Check if we're inside an open tag (between [color=...] and [/color])
	var color_opens = before.count("[color=")
	var color_closes = before.count("[/color]")

	if color_opens > color_closes:
		return true

	var bold_opens = before.count("[b]")
	var bold_closes = before.count("[/b]")

	if bold_opens > bold_closes:
		return true

	return false

## Escape special regex characters in a string
static func _escape_regex(text: String) -> String:
	var special_chars = ["\\", ".", "+", "*", "?", "^", "$", "(", ")", "[", "]", "{", "}", "|"]
	var result = text
	for char in special_chars:
		result = result.replace(char, "\\" + char)
	return result
