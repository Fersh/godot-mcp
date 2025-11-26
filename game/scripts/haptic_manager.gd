extends Node

# Haptic feedback manager for iOS
# Uses Input.vibrate_handheld() which works on iOS and Android

func light() -> void:
	"""Light haptic feedback - subtle tap."""
	Input.vibrate_handheld(20)

func medium() -> void:
	"""Medium haptic feedback - noticeable tap."""
	Input.vibrate_handheld(40)

func heavy() -> void:
	"""Heavy haptic feedback - strong impact."""
	Input.vibrate_handheld(80)

func damage() -> void:
	"""Haptic feedback when player takes damage."""
	Input.vibrate_handheld(50)

func death() -> void:
	"""Strong haptic pattern when player dies."""
	# Multiple pulses for dramatic effect
	Input.vibrate_handheld(100)
	await get_tree().create_timer(0.15).timeout
	Input.vibrate_handheld(150)
	await get_tree().create_timer(0.2).timeout
	Input.vibrate_handheld(200)

func level_up() -> void:
	"""Celebratory haptic pattern for level up."""
	# Two quick pulses
	Input.vibrate_handheld(30)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(60)
