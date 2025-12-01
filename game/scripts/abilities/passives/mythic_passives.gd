extends Node
class_name MythicPassives

# Mythic passive abilities
# Extremely rare, game-defining effects

static func get_abilities() -> Array[AbilityData]:
	return [
		# Immortal Oath - DISABLED: Too powerful
		#AbilityData.new(
		#	"immortal_oath",
		#	"Immortal Oath",
		#	"On fatal damage: 3s immunity to save yourself",
		#	AbilityData.Rarity.LEGENDARY,
		#	AbilityData.Type.PASSIVE,
		#	[{effect_type = AbilityData.EffectType.IMMORTAL_OATH, value = 3.0}]
		#),

		# All-For-One - DISABLED: Not fully implemented
		#AbilityData.new(
		#	"all_for_one",
		#	"All-For-One",
		#	"Equip all active abilities, double cooldowns",
		#	AbilityData.Rarity.LEGENDARY,
		#	AbilityData.Type.PASSIVE,
		#	[{effect_type = AbilityData.EffectType.ALL_FOR_ONE, value = 2.0}]
		#),

		# Transcendence
		AbilityData.new(
			"transcendence",
			"Transcendence",
			"Convert HP to regenerating shields",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.TRANSCENDENCE, value = 1.0}]
		),

		# Symbiosis - DISABLED: Not fully implemented
		#AbilityData.new(
		#	"symbiosis",
		#	"Symbiosis",
		#	"Choose 2 passives per level-up",
		#	AbilityData.Rarity.LEGENDARY,
		#	AbilityData.Type.PASSIVE,
		#	[{effect_type = AbilityData.EffectType.SYMBIOSIS, value = 2.0}]
		#),

		# Pandemonium
		AbilityData.new(
			"pandemonium",
			"Pandemonium",
			"Double enemies and double damage",
			AbilityData.Rarity.LEGENDARY,
			AbilityData.Type.PASSIVE,
			[{effect_type = AbilityData.EffectType.PANDEMONIUM, value = 2.0}]
		),
	]
