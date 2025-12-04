# Difficulty Rebalance Devlog

## Date: 2025-12-04

### Summary
Major difficulty rebalance to make Challenge Mode progressively harder with consistent 20% scaling per tier, new XP requirements per difficulty, substantial boss/elite bonuses, and a new %HP damage mechanic.

---

## Changes Overview

### 1. Base Difficulty Scaling (+20% Compounding Per Tier)

Each tier after Easy gets current values multiplied by 1.2^n where n = tiers above Easy.

#### BEFORE (Old Values)
| Difficulty | Health | Damage | Speed | Spawn Rate |
|------------|--------|--------|-------|------------|
| Pitiful | 1.0 | 1.0 | 1.0 | 1.375 |
| Easy | 3.52 | 2.7 | 1.24 | 3.3 |
| Normal | 5.28 | 3.3 | 1.44 | 4.235 |
| Nightmare | 8.36 | 4.2 | 1.64 | 4.84 |
| Hell | 12.1 | 5.5 | 1.9 | 5.6 |
| Inferno | 18.15 | 7.5 | 2.4 | 6.655 |
| Thanksgiving | 27.5 | 10.0 | 3.0 | 8.47 |

#### AFTER (New Values)
| Difficulty | Health | Damage | Speed | Spawn Rate | Multiplier |
|------------|--------|--------|-------|------------|------------|
| Pitiful | 1.0 | 1.0 | 1.0 | 1.375 | 1.0x |
| Easy | 3.52 | 2.7 | 1.24 | 3.3 | 1.0x |
| Normal | 6.34 | 3.96 | 1.73 | 4.235 | 1.2x |
| Nightmare | 12.04 | 6.05 | 2.36 | 4.84 | 1.44x |
| Hell | 20.91 | 9.50 | 3.28 | 5.6 | 1.728x |
| Inferno | 37.64 | 15.56 | 4.98 | 6.655 | 2.074x |
| Thanksgiving | 68.42 | 24.88 | 7.35 | 8.47 | 2.488x |

**Spawn rates unchanged due to performance concerns.**

---

### 2. XP Requirements Per Difficulty (+25% Compounding)

NEW FEATURE: Each difficulty tier requires more XP to level up.

| Difficulty | XP Multiplier | With Corrupted XP Curse (+25%) |
|------------|---------------|--------------------------------|
| Pitiful | 1.0x | 1.25x |
| Easy | 1.25x | 1.5625x |
| Normal | 1.5625x | 1.953x |
| Nightmare | 1.953x | 2.441x |
| Hell | 2.441x | 3.052x |
| Inferno | 3.052x | 3.815x |
| Thanksgiving | 3.815x | 4.768x |

**Implementation:** Applied in `player.gd` via `DifficultyManager.get_xp_requirement_multiplier()`, compounds with curse effects.

---

### 3. Elite Bonus Multipliers (Starting at Easy)

NEW FEATURE: Elites get additional health/damage bonuses based on difficulty.

| Difficulty | Elite Health Bonus | Elite Damage Bonus |
|------------|-------------------|-------------------|
| Pitiful | +0% (1.0x) | +0% (1.0x) |
| Easy | +100% (2.0x) | +50% (1.5x) |
| Normal | +200% (3.0x) | +100% (2.0x) |
| Nightmare | +300% (4.0x) | +150% (2.5x) |
| Hell | +400% (5.0x) | +200% (3.0x) |
| Inferno | +500% (6.0x) | +250% (3.5x) |
| Thanksgiving | +600% (7.0x) | +300% (4.0x) |

**Implementation:** Applied in `elite_base.gd` via `DifficultyManager.get_elite_health_bonus()` and `get_elite_damage_bonus()`.

---

### 4. Boss Bonus Multipliers (Starting at Easy)

NEW FEATURE: Bosses get even larger health/damage bonuses based on difficulty.

| Difficulty | Boss Health Bonus | Boss Damage Bonus |
|------------|------------------|------------------|
| Pitiful | +0% (1.0x) | +0% (1.0x) |
| Easy | +150% (2.5x) | +100% (2.0x) |
| Normal | +300% (4.0x) | +200% (3.0x) |
| Nightmare | +450% (5.5x) | +300% (4.0x) |
| Hell | +600% (7.0x) | +400% (5.0x) |
| Inferno | +750% (8.5x) | +500% (6.0x) |
| Thanksgiving | +900% (10.0x) | +600% (7.0x) |

**Implementation:** Applied in `boss_base.gd` via `DifficultyManager.get_boss_health_bonus()` and `get_boss_damage_bonus()`.

#### Example - Thanksgiving Boss Total Stats:
- Base difficulty multiplier: 68.42x health, 24.88x damage
- Boss bonus: 10x health, 7x damage
- **Final: ~684x health, ~174x damage** vs Pitiful baseline

---

### 5. Percent HP Damage (Starting at Normal)

NEW FEATURE: Enemy attacks deal a percentage of the player's max HP as bonus damage, scaling with difficulty.

| Difficulty | % Max HP Per Hit |
|------------|------------------|
| Pitiful | 0% |
| Easy | 0% |
| Normal | 0.5% |
| Nightmare | 1.0% |
| Hell | 1.5% |
| Inferno | 2.0% |
| Thanksgiving | 2.5% |

**Implementation:** Applied in `player.gd` `take_damage()` via `DifficultyManager.get_percent_hp_damage()`. Added on top of flat damage.

---

### 6. Health Bar Visibility for Regular Mobs

CHANGE: Regular enemies (non-elites, non-bosses) only show health bars when damaged (not at 100% HP).

**Implementation:** Modified `enemy_base.gd` to hide health bar by default and show only when `current_health < max_health`.

---

## Rollback Instructions

### To revert base difficulty scaling:
Restore old values in `difficulty_manager.gd` DIFFICULTY_DATA:
```gdscript
# Old values
DifficultyTier.NORMAL: { "health_mult": 5.28, "damage_mult": 3.3, "speed_mult": 1.44 }
DifficultyTier.NIGHTMARE: { "health_mult": 8.36, "damage_mult": 4.2, "speed_mult": 1.64 }
DifficultyTier.HELL: { "health_mult": 12.1, "damage_mult": 5.5, "speed_mult": 1.9 }
DifficultyTier.INFERNO: { "health_mult": 18.15, "damage_mult": 7.5, "speed_mult": 2.4 }
DifficultyTier.THANKSGIVING_DINNER: { "health_mult": 27.5, "damage_mult": 10.0, "speed_mult": 3.0 }
```

### To disable XP requirements:
Set all `xp_requirement_mult` values to 1.0 in DIFFICULTY_DATA, or remove the multiplier call in `player.gd`.

### To disable elite/boss bonuses:
Set all bonus values to 0.0 in DIFFICULTY_DATA, or remove the bonus application in `elite_base.gd` and `boss_base.gd`.

### To disable %HP damage:
Set all `percent_hp_damage` values to 0.0 in DIFFICULTY_DATA, or remove the calculation in `player.gd` `take_damage()`.

### To revert health bar visibility:
Remove the visibility check in `enemy_base.gd` and always show health bars.

---

## Files Modified

1. `game/scripts/difficulty_manager.gd` - New multipliers and getter functions
2. `game/scripts/player.gd` - XP requirement multiplier, %HP damage
3. `game/scripts/elite_base.gd` - Elite bonus application
4. `game/scripts/boss_base.gd` - Boss bonus application
5. `game/scripts/enemy_base.gd` - Health bar visibility logic
