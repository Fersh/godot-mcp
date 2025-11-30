extends CanvasLayer

@onready var progress_bar: ProgressBar = $MarginContainer/ProgressBar
@onready var level_label: Label = $MarginContainer/ProgressBar/LevelLabel

var player: Node2D = null
var current_tween: Tween = null
var displayed_xp: float = 0.0

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_changed)
		player.connect("level_up", _on_level_up)
		displayed_xp = player.current_xp
		progress_bar.max_value = player.xp_to_next_level
		progress_bar.value = displayed_xp
		level_label.text = "Lv " + str(player.current_level)

func _on_xp_changed(current_xp: float, xp_needed: float, level: int) -> void:
	# Update max value immediately
	progress_bar.max_value = xp_needed
	level_label.text = "Lv " + str(level)

	# Cancel existing tween if any
	if current_tween and current_tween.is_valid():
		current_tween.kill()

	# If XP decreased (level up reset), snap to new value
	if current_xp < displayed_xp:
		displayed_xp = current_xp
		progress_bar.value = current_xp
		return

	# Smoothly animate to new XP value
	current_tween = create_tween()
	current_tween.tween_method(_update_bar_value, displayed_xp, current_xp, 0.3).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	displayed_xp = current_xp

func _update_bar_value(value: float) -> void:
	progress_bar.value = value

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv " + str(new_level)

	# Play level up sound and haptic
	if SoundManager:
		SoundManager.play_levelup()
	if HapticManager:
		HapticManager.medium()

	# Animate level label with a pulse effect
	var original_scale = level_label.scale
	level_label.pivot_offset = level_label.size / 2

	var tween = create_tween()
	tween.tween_property(level_label, "scale", Vector2(1.3, 1.3), 0.15).set_ease(Tween.EASE_OUT)
	tween.tween_property(level_label, "scale", original_scale, 0.15).set_ease(Tween.EASE_IN)
