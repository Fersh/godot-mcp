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

### 7. Status Effect Visual Tinting

NEW FEATURE: Enemies now display color tints when affected by status effects.

| Status Effect | Color | RGB |
|---------------|-------|-----|
| Burn | Orange-red | `Color(1.3, 0.6, 0.3)` |
| Poison | Green | `Color(0.5, 1.2, 0.5)` |
| Slow/Frozen | Light blue | `Color(0.6, 0.85, 1.3)` |
| Stun | Yellow | `Color(1.3, 1.2, 0.5)` |

**Details:**
- Uses sprite modulate tinting (zero GPU overhead)
- Multiple status effects blend their colors together
- Tint strength: 40% blend with base color
- Champions retain golden base tint with status effects layered on top
- Only updates when status effects change (not every frame)

**Implementation:** Added `_update_status_modulate()` in `enemy_base.gd`, called when status effects are applied/removed.

---

### 8. Health Bar Drop Shadow

NEW FEATURE: All health bars now have a subtle drop shadow for better visual depth and readability.

**Details:**
- Shadow color: `Color(0, 0, 0, 0.5)` (50% black)
- Shadow size: 3px blur
- Shadow offset: `Vector2(1, 2)` (slightly down-right)
- Uses native StyleBoxFlat shadow properties (zero performance cost)
- Applies to player, enemy, elite, and boss health bars

**Implementation:** Added `shadow_color`, `shadow_size`, and `shadow_offset` to the background StyleBoxFlat in `health_bar.gd`.

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

### To disable status effect tinting:
Remove the `_update_status_modulate()` calls from `apply_stun()`, `apply_slow()`, `apply_burn()`, `apply_poison()`, `handle_stun()`, and `handle_status_effects()` in `enemy_base.gd`.

### To remove health bar drop shadow:
Remove the `shadow_color`, `shadow_size`, and `shadow_offset` lines from `health_bar.gd` `_ready()`.

---

## Files Modified

1. `game/scripts/difficulty_manager.gd` - New multipliers and getter functions
2. `game/scripts/player.gd` - XP requirement multiplier, %HP damage
3. `game/scripts/elite_base.gd` - Elite bonus application
4. `game/scripts/boss_base.gd` - Boss bonus application
5. `game/scripts/enemy_base.gd` - Health bar visibility logic, status effect color tinting
6. `game/scripts/health_bar.gd` - Drop shadow for all health bars

---

## Additional Updates (2025-12-04)

### 9. Status Effect Tinting Fix

**BUG FIX:** Status effect tints were not visible due to hit_flash shader ignoring sprite.modulate.

**Root Cause:** The hit_flash shader was reading raw texture color and outputting directly, bypassing the modulate property entirely.

**Fix:** Modified `game/shaders/hit_flash.gdshader` to multiply texture by COLOR (which contains modulate) before mixing with flash color.

**Updated Colors (more saturated for visibility):**
| Status Effect | Color | RGB |
|---------------|-------|-----|
| Burn | Deep orange-red | `(1.0, 0.35, 0.15)` |
| Poison | Vibrant green | `(0.3, 1.0, 0.3)` |
| Slow | Icy blue | `(0.4, 0.65, 1.0)` |
| Stun | Bright yellow | `(1.0, 0.85, 0.2)` |
| Freeze | Cyan/white ice | `(0.7, 0.95, 1.0)` |
| Bleed | Dark red | `(0.8, 0.15, 0.15)` |
| Shock | Electric purple | `(0.7, 0.5, 1.0)` |

**Tint strength increased from 60% to 80%** for better visibility.

---

### 10. New Status Effects: Freeze, Bleed, Shock

**NEW FEATURE:** Added three missing status effects that were being called but not implemented.

| Effect | Function | Behavior |
|--------|----------|----------|
| Freeze | `apply_freeze(duration)` | Complete immobilization (icy stun, no animation) |
| Bleed | `apply_bleed(total_damage, duration)` | DoT every 0.5s, dark red tint |
| Shock | `apply_shock(damage)` | +25% damage taken for 2s, optional instant damage |

**Implementation:** Added to `enemy_base.gd` with full timer handling, status text popups, and color tinting.

---

### 11. Floor is Lava Damage Fix

**BUG FIX:** "The Floor is Lava" ability was dealing essentially no damage.

**Root Cause:** Damage was divided by number of spawns (35), then again by ticks (10), resulting in ~0.07 damage per tick.

**Fix:** Each lava pool now deals 50% of ability damage over its lifetime (not divided by spawn count). Also added burn effect application to enemies standing in lava.

**Files Modified:** `game/scripts/active_abilities/ability_executor.gd`

---

### 12. Frost Totem Rename

**CHANGE:** Renamed "Totem of Frost" to "Frost Totem" for consistency.

**Files Modified:** `game/scripts/active_abilities/active_ability_database.gd`

---

### 13. Common Item Border Color

**CHANGE:** Common rarity items now display with a black text outline instead of white when dropped on the floor, improving readability against light backgrounds.

**Files Modified:** `game/scripts/equipment/dropped_item.gd`

---

### 14. Permanent Upgrade Cost Increase (Rank 4 & 5)

**BALANCE CHANGE:** Increased costs for high-rank permanent upgrades to slow late-game progression.

| Rank | Old Multiplier | New Multiplier | Change |
|------|----------------|----------------|--------|
| Rank 4 | +40% (1.40x) | +68% (1.68x) | +20% increase |
| Rank 5+ | +35% (1.35x) | +94% (1.94x) | +20% + additional 20% |

**Files Modified:** `game/scripts/permanent_upgrades.gd`

---

## Additional Files Modified

7. `game/shaders/hit_flash.gdshader` - Fixed modulate support for status tints
8. `game/scripts/enemy_shardsoul_slayer.gd` - Fixed frenzy mode to use base_modulate
9. `game/scripts/active_abilities/ability_executor.gd` - Floor is Lava damage fix
10. `game/scripts/active_abilities/active_ability_database.gd` - Frost Totem rename
11. `game/scripts/equipment/dropped_item.gd` - Common item black border
12. `game/scripts/permanent_upgrades.gd` - Rank 4/5 cost increases

---

## Endless Mode Overhaul (2025-12-04)

### 15. Endless Mode Now End-Game Difficulty

**MAJOR CHANGE:** Endless mode has been completely rebalanced to function as end-game content, starting at 120% of Thanksgiving difficulty with infinite scaling.

#### Before (Old Endless Mode)
- Static 2x multiplier for health, damage, speed
- No modifiers, no champions, no %HP damage
- Essentially "Easy" difficulty that never changed

#### After (New Endless Mode)

**Starting Values (120% of Thanksgiving):**
| Stat | Value |
|------|-------|
| Health | 82.1x |
| Damage | 29.86x |
| Speed | 8.82x |
| Points | 12x |
| Starting HP | 25% |
| Healing | 25% |
| Champion Chance | 35% |
| %HP Damage/Hit | 3% |
| XP Requirement | 4.58x |
| Elite Health Bonus | +720% |
| Elite Damage Bonus | +360% |
| Boss Health Bonus | +1080% |
| Boss Damage Bonus | +720% |

**Active Modifiers:**
- Chilling Touch (enemy slow on hit)
- Elite Affixes
- Faster Boss Enrage (35% HP threshold)

**Spawn Rate:** Unchanged at 1.0x (performance concern)

---

### 16. Infinite Time-Based Scaling

**NEW FEATURE:** Endless mode difficulty increases by 5% per minute, compounding with no cap.

| Time Survived | Scaling Multiplier | Effective Health | Effective Damage |
|---------------|-------------------|------------------|------------------|
| 0 min | 1.0x | 82.1x | 29.86x |
| 5 min | 1.28x | 105x | 38x |
| 10 min | 1.63x | 134x | 49x |
| 15 min | 2.08x | 171x | 62x |
| 20 min | 2.65x | 218x | 79x |
| 30 min | 4.32x | 355x | 129x |
| 45 min | 8.99x | 738x | 268x |
| 60 min | 18.68x | 1534x | 558x |

**Safety Caps to Prevent Unplayability:**
- Speed: Capped at 2x scaling (max ~17.6x total) to allow dodging
- %HP Damage: Capped at 10% per hit to prevent instant kills
- Champion Chance: Capped at 50%

---

### 17. Implementation Details

**DifficultyManager Changes:**
- Added `ENDLESS_BASE` constant with 120% Thanksgiving values
- Added `ENDLESS_SCALING_PER_MINUTE` constant (0.05 = 5%)
- Added `endless_game_time` tracking variable
- Added `update_endless_time()` and `reset_endless_time()` functions
- Added `get_endless_scaling_multiplier()` using compound interest formula: `pow(1.05, minutes)`
- Updated all getter functions to use base * scaling for Endless mode

**Main.gd Changes:**
- Calls `DifficultyManager.reset_endless_time()` on run start
- Calls `DifficultyManager.update_endless_time(game_time)` every frame in Endless mode

---

### Rollback Instructions

**To revert to old Endless mode (static 2x):**
Replace all Endless mode checks in `difficulty_manager.gd` getter functions with:
```gdscript
if current_mode == GameMode.ENDLESS:
    return 2.0  # Or appropriate static value
```

**To disable time scaling:**
Change `get_endless_scaling_multiplier()` to always return 1.0.

**To adjust scaling rate:**
Modify `ENDLESS_SCALING_PER_MINUTE` constant (0.05 = 5%, 0.03 = 3%, etc.)

---

### Files Modified

13. `game/scripts/difficulty_manager.gd` - Endless base values, time scaling, updated getters
14. `game/scripts/main.gd` - Time feed to DifficultyManager for Endless scaling
