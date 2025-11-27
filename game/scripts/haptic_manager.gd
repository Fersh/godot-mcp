extends Node

# Haptic feedback manager for iOS
# Uses Input.vibrate_handheld() which works on iOS and Android

func _is_enabled() -> bool:
	return not GameSettings or GameSettings.haptics_enabled

func light() -> void:
	"""Light haptic feedback - subtle tap."""
	if not _is_enabled():
		return
	Input.vibrate_handheld(20)

func medium() -> void:
	"""Medium haptic feedback - noticeable tap."""
	if not _is_enabled():
		return
	Input.vibrate_handheld(40)

func heavy() -> void:
	"""Heavy haptic feedback - strong impact."""
	if not _is_enabled():
		return
	Input.vibrate_handheld(80)

func damage() -> void:
	"""Haptic feedback when player takes damage."""
	if not _is_enabled():
		return
	Input.vibrate_handheld(50)

func death() -> void:
	"""Strong haptic pattern when player dies."""
	if not _is_enabled():
		return
	# Multiple pulses for dramatic effect
	Input.vibrate_handheld(100)
	await get_tree().create_timer(0.15).timeout
	Input.vibrate_handheld(150)
	await get_tree().create_timer(0.2).timeout
	Input.vibrate_handheld(200)

func level_up() -> void:
	"""Celebratory haptic pattern for level up."""
	if not _is_enabled():
		return
	# Two quick pulses
	Input.vibrate_handheld(30)
	await get_tree().create_timer(0.1).timeout
	Input.vibrate_handheld(60)

func ultimate() -> void:
	"""Epic haptic pattern for ultimate ability activation."""
	if not _is_enabled():
		return
	# Building anticipation pattern
	Input.vibrate_handheld(30)
	await get_tree().create_timer(0.08).timeout
	Input.vibrate_handheld(50)
	await get_tree().create_timer(0.08).timeout
	Input.vibrate_handheld(80)

func ultimate_release() -> void:
	"""Massive haptic for ultimate release moment."""
	if not _is_enabled():
		return
	# Single powerful pulse
	Input.vibrate_handheld(250)
