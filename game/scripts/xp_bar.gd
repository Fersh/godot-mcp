extends CanvasLayer

@onready var progress_bar: ProgressBar = $MarginContainer/ProgressBar
@onready var level_label: Label = $MarginContainer/ProgressBar/LevelLabel

var player: Node2D = null

func _ready() -> void:
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if player:
		player.connect("xp_changed", _on_xp_changed)
		player.connect("level_up", _on_level_up)
		_on_xp_changed(player.current_xp, player.xp_to_next_level, player.current_level)

func _on_xp_changed(current_xp: float, xp_needed: float, level: int) -> void:
	progress_bar.max_value = xp_needed
	progress_bar.value = current_xp
	level_label.text = "Lv " + str(level)

func _on_level_up(new_level: int) -> void:
	level_label.text = "Lv " + str(new_level)
