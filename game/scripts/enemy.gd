extends EnemyBase

# Orc Peon - The baseline melee enemy
# Stats: Balanced speed, health, and damage

func _on_ready() -> void:
	enemy_type = "orc"

	# Orc uses 8x8 spritesheet layout
	ROW_IDLE = 0
	ROW_MOVE = 2
	ROW_ATTACK = 5
	ROW_DAMAGE = 6
	ROW_DEATH = 7
	COLS_PER_ROW = 8

	FRAME_COUNTS = {
		0: 4,  # IDLE
		1: 8,  # SLEEP
		2: 8,  # MOVE
		3: 8,  # CARRY
		4: 8,  # CARRY2
		5: 8,  # ATTACK
		6: 3,  # DAMAGE
		7: 6,  # DEATH
	}
