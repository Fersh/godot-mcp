extends Node2D

@onready var player: CharacterBody2D = $Player
@onready var ability_selection: CanvasLayer = $AbilitySelection

func _ready() -> void:
	# Connect player level up signal
	if player:
		player.level_up.connect(_on_player_level_up)

func _on_player_level_up(new_level: int) -> void:
	# Get random abilities and show selection
	var choices = AbilityManager.get_random_abilities(3)
	if choices.size() > 0:
		ability_selection.show_choices(choices)
