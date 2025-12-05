# Devlog

---

## Date: 2025-12-04 - Ranged Standalone Ability Cleanup

### Summary
Removed 9 standalone ranged/global abilities that duplicate functionality now available through ability tree upgrades.

### Abilities Removed (Commented Out)

| Ability | Rarity | Tree Equivalent | Tree Position |
|---------|--------|-----------------|---------------|
| **cluster_bomb** | RARE | Cluster Bomb | Explosive Arrow T2 |
| **fan_of_knives** | RARE | Fan of Knives | Multi Shot T2 |
| **arrow_storm** | EPIC | Arrow Storm | Rain of Arrows T2 |
| **sentry_network** | EPIC | Gatling Network | Turret Tree T3 |
| **rain_of_vengeance** | EPIC | Arrow Apocalypse | Rain of Arrows T3 |
| **explosive_decoy** | EPIC | Explosive Decoy | Decoy Tree T2 |
| **bear_trap** | RARE | Bear Trap | Trap Tree T2 |
| **smoke_bomb** | RARE | Smoke Bomb | Smoke Tree BASE |
| **orbital_strike** | EPIC | Orbital Strike | Rain Tree T3 Branch B |

### Abilities Kept
- **ballista_strike** (EPIC) - Unique high single-target pierce damage, distinct from Snipe/Power Shot trees

### Files Modified
- `active_ability_database.gd` - Commented out 9 duplicate ability registrations

---

## Date: 2025-12-04 - Flame Wall Orientation Fix

### Summary
Updated Flame Wall to cast perpendicular to enemy direction, creating a barrier enemies walk through.

### Change
- Wall now finds nearest enemy and places itself between player and enemy
- Wall orientation is 90 degrees perpendicular to enemy direction
- Enemies walking toward player now walk through the wall (maximizing damage/burn)

### Files Modified
- `ability_executor.gd` - Updated `_execute_flame_wall()` positioning logic

---

## Date: 2025-12-04 - Property Name & Parser Fixes

### Summary
Fixed two critical bugs preventing tier 3 abilities from working properly.

### Bug Fixes

**1. FireballTree Parser Error**
- **Issue:** Line continuation `\` with comments after it caused parser error in GDScript
- **Fix:** Moved comments above the method chain and removed backslash line continuations

**2. Invalid Property Access (`range_value`)**
- **Issue:** All executors were using `ability.range_value` but the correct property name is `ability.range_distance` (defined in `ActiveAbilityData`)
- **Fix:** Replaced all 27 occurrences across 3 executor files

### Files Modified
- `fireball_tree.gd` - Fixed parser error (removed comments after `\`)
- `global_executor.gd` - Fixed 5 occurrences of `range_value` → `range_distance`
- `ranged_executor.gd` - Fixed 10 occurrences of `range_value` → `range_distance`
- `melee_executor.gd` - Fixed 12 occurrences of `range_value` → `range_distance`

---

## Date: 2025-12-04 - Fireball Fix & Buff

### Summary
Fixed Fireball ability not spawning projectiles and significantly buffed its stats.

### Bug Fix
**Issue:** Fireball and Phoenix Flame weren't working because `global_executor.gd` was using `base_executor._spawn_projectile()` which only works with arrow scenes (for ranged characters).

**Fix:** Updated to use `_main_executor._spawn_projectile()` which properly creates ability projectiles with the correct fireball sprite and explosion behavior.

### Stat Buffs

| Stat | Before | After | Change |
|------|--------|-------|--------|
| Base Damage | 45 | 60 | +33% |
| Damage Multiplier | 1.3x | 1.5x | +15% |
| Effective Damage | 58.5 | 90 | +54% |
| AoE Radius | 80 | 100 | +25% |
| Projectile Speed | 450 | 500 | +11% |
| Cooldown | 5s | 4s | -20% |
| AoE Damage | 50% | 75% | +50% |

### Additional Improvements
- Fireball explosion now applies **3 second burn** to enemies in AoE
- Phoenix Flame now properly deals AoE damage with burn and heals 15% of damage dealt

### Files Modified
- `game/scripts/active_abilities/executors/global_executor.gd` - Fixed projectile spawning
- `game/scripts/active_abilities/trees/global/fireball_tree.gd` - Buffed stats
- `game/scripts/projectiles/ability_projectile.gd` - Increased AoE damage and added burn

---

## Date: 2025-12-04 - Standalone Active Ability Cleanup

### Summary
Removed standalone active abilities that duplicate functionality now available through the tiered ability tree upgrade system. Players should experience these abilities by upgrading base abilities rather than finding them as separate drops.

### Abilities Removed (Commented Out)

| Ability | Rarity | Now Available As | Tree Path |
|---------|--------|------------------|-----------|
| **Seismic Slam** | RARE | Seismic Ground Slam | Slam Tree T2 |
| **Blade Rush** | RARE | Rushing Dash Strike | Dash Tree T2 |
| **Terrifying Shout** | RARE | Terrifying Roar | Roar Tree BASE |
| **Demoralizing Shout** | RARE | Intimidating Roar | Roar Tree T2 |
| **Earthquake** | EPIC | Seismic Ground Slam of Cataclysm | Slam Tree T3 |
| **Divine Shield** | EPIC | Reflecting Block of Retribution | Block Tree T3 |
| **Omnislash** | EPIC | Rushing Dash Strike of Oblivion | Dash Tree T3 |
| **Avatar of War** | EPIC | *(needs Transform tree base)* | Pending |

### Rationale
These abilities were available as standalone drops at their rarity tier, bypassing the upgrade progression. Now players must:
1. Acquire the base ability (e.g., Ground Slam, Dash Strike, Roar, Block)
2. Upgrade through T2 to unlock enhanced versions
3. Reach T3 for the signature variants

This creates a more satisfying progression where powerful abilities feel earned through investment.

### Files Modified
- `game/scripts/active_abilities/active_ability_database.gd` - Commented out 8 ability registrations
- `game/scripts/active_abilities/executors/melee_executor.gd` - Added Roar Tree executor implementations

### Roar Tree Implementations Added

| Ability | Tier | Effect |
|---------|------|--------|
| **Terrifying Roar** | BASE | Fear enemies in radius, causing them to flee |
| **Intimidating Roar** | T2 | Fear + enemies deal 30% less damage |
| **Crushing Presence** | T3 | Aura: -40% enemy damage, -30% speed, fear on contact |
| **Enraging Roar** | T2 | Fear + self +40% damage buff |
| **Blood Rage** | T3 | Fear + stacking damage per hit (+10%, max +100%), lifesteal, attack speed |

### Note
**Avatar of War** commented out pending creation of a "Transform" or "War Form" base ability tree.

---

## Date: 2025-12-04 - Spinning Attack → Whirlwind Tree Rename

### Summary
Renamed "Spinning Attack" to "Whirlwind" as the base ability, merged the old Whirlwind Tree into it, and updated visuals to use whirlwind effect.

### Changes

**Spin Tree → Whirlwind Tree:**
- Base renamed from "Spinning Attack" (COMMON) to "Whirlwind" (COMMON)
- Base now uses sustained spinning with `whirlwind` effect instead of instant `spin` effect
- Base now has 1.5s duration (sustained spinning)
- All branch abilities renamed:
  - "Vortex Spinning Attack" → "Vortex Whirlwind"
  - "Vortex Spinning Attack of Storms" → "Vortex Whirlwind of Storms"
  - "Deflecting Spinning Attack" → "Deflecting Whirlwind"
  - "Deflecting Spinning Attack of Mirrors" → "Deflecting Whirlwind of Mirrors"

**Old Whirlwind Tree (RARE base) - Deprecated:**
- Tree registration commented out in AbilityTreeRegistry
- Old variants (vacuum, singularity, flame, inferno) kept for backwards compatibility
- Players should now use the new Whirlwind Tree (formerly Spin Tree)

### Files Modified
- `game/scripts/active_abilities/trees/melee/spin_tree.gd` - Renamed to Whirlwind, updated effect
- `game/scripts/active_abilities/executors/melee_executor.gd` - Updated match cases and implementations
- `game/scripts/active_abilities/active_ability_database.gd` - Commented out spinning_attack and whirlwind standalone registrations
- `game/scripts/active_abilities/trees/ability_tree_registry.gd` - Commented out old WhirlwindTree registration

---

## Date: 2025-12-04 - Ability Tree System Implementation

### Summary
Completed gameplay and UI integration for the tiered ability branching system. Players can now acquire base abilities and upgrade them through Tier 2 (BRANCH) and Tier 3 (SIGNATURE) versions with unique mechanics.

### Changes Overview

#### 1. Gameplay Integration (ActiveAbilityManager)
- Added `acquired_tree_abilities` dictionary to track ability progression per tree
- Implemented `UPGRADE_CHANCE = 0.40` (40% chance for upgrades to appear in selection)
- Modified `acquire_ability()` to handle tier upgrades (replaces ability in slot)
- Added `_try_upgrade_existing_ability()` for slot replacement logic
- Added `_track_tree_ability()` for progression tracking
- Modified `get_random_abilities_for_level()` to include available upgrades in the pool
- Added `_get_available_upgrades()` to find all possible upgrades for current abilities

#### 2. UI Integration (active_ability_selection_ui.gd)
- Updated `_style_button()` to accept ability parameter for tier-based styling
- **Tier 2 (BRANCH)**: Green border (#33E64D), subtle green background tint, 4px border
- **Tier 3 (SIGNATURE)**: Gold border (#FFD94D), subtle gold background tint, 4px border
- Added `_create_tier_banner()` - displays "UPGRADE" or "SIGNATURE" banner at card bottom
- Added `_create_prerequisite_indicator()` - shows "↑ [Parent Ability Name]" at card top
- Added `_update_tier_banner()` and `_update_prerequisite_indicator()` for slot machine animation support
- Modified `_update_card_content()` to handle tier banners and prerequisite indicators during animation

#### 3. Database (ActiveAbilityDatabase)
- Added `get_ability_by_id()` alias for consistent API naming

#### 4. Status Document
- Updated `docs/ability_tree_status.md` with current implementation status
- 20/55 ability trees have executor implementations complete

### Files Modified
- `scripts/active_abilities/active_ability_manager.gd` - upgrade tracking & mixed selection
- `scripts/active_abilities/ui/active_ability_selection_ui.gd` - tier styling & banners
- `scripts/active_abilities/active_ability_database.gd` - added get_ability_by_id alias
- `docs/ability_tree_status.md` - updated implementation status

### Implementation Status
- **Phase 1 (Infrastructure)**: ✅ Complete
- **Phase 2 (Gameplay Integration)**: ✅ Complete
- **Phase 3 (UI Integration)**: ✅ Complete
- **Phase 4 (Executor Implementation)**: 🔨 In Progress (20/55 trees)

### Trees with Full Executor Support
**Melee (9/20)**: Cleave, Bash, Charge, Spin, Slam, Dash, Whirlwind, Leap, Shout
**Ranged (7/20)**: Power Shot, Multi Shot, Trap, Rain, Turret, Volley, Evasion
**Global (4/15)**: Fireball, Frost Nova, Lightning, Heal

---

## Date: 2025-12-04 - Difficulty Rebalance

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

---

## Ability System Revamp - Infrastructure (2025-12-04)

### 18. Tiered Branching Active Ability System (Data Layer Only)

**NEW INFRASTRUCTURE:** Created complete data structure for tiered branching active abilities inspired by Hades (boon tiers), Diablo 4 (skill branching), and Path of Exile (support gems).

**NOTE:** This is infrastructure only - the selection UI and passive-to-active unlock connections are NOT yet implemented. The trees exist but aren't accessible in-game yet.

#### Tier Structure
| Tier | Name | Rarity | Description |
|------|------|--------|-------------|
| Tier 1 | Base | Common/Rare | Starting ability |
| Tier 2 | Branch | Rare | Two mutually exclusive upgrade paths |
| Tier 3 | Signature | Epic | Powerful culmination with unique mechanics |

#### 55 Ability Trees Created

**20 Melee Trees:**
- cleave, bash, charge, spin, slam, dash, whirlwind, leap, shout, throw
- taunt, execute, block, impale, uppercut, combo, roar, stomp, parry, rampage

**20 Ranged Trees:**
- power_shot, multi_shot, trap, rain, turret, volley, evasion, explosive, poison, frost_arrow
- mark, snipe, decoy, grapple, boomerang, smoke, net, ricochet, barrage, quickdraw

**15 Global Trees:**
- fireball, frost_nova, lightning, heal, teleport, time, summon, aura, shield, gravity
- bomb, drain, curse, blink, thorns

Each tree has:
- 1 Base ability (Tier 1)
- 2 Branch paths (Tier 2) - mutually exclusive
- 2 Signature abilities (Tier 3) - one per branch

**Total abilities defined:** 275 (55 trees × 5 abilities each)

---

### 19. Ability Tree Node System

**NEW FILE:** `game/scripts/active_abilities/trees/ability_tree_node.gd`

Class for managing individual ability tree progression:
- Tracks current tier and acquired branch
- Manages prerequisite validation
- Provides upgrade availability queries
- Handles tree reset for new runs

---

### 20. Ability Tree Registry

**NEW FILE:** `game/scripts/active_abilities/trees/ability_tree_registry.gd`

Central registry managing all 55 ability trees:
- Lazy initialization on first access
- Lookup by base ID or any ability ID in tree
- Class-type filtering (melee/ranged/global)
- Upgrade availability queries
- Debug printing of all registered trees

---

### 21. Active Ability Data Extensions

**MODIFIED:** `game/scripts/active_abilities/active_ability_data.gd`

Added tier/prerequisite support:
```gdscript
enum AbilityTier { BASE, BRANCH, SIGNATURE }

var tier: AbilityTier = AbilityTier.BASE
var prerequisite_id: String = ""
var branch_index: int = 0
var unique_mechanic: String = ""  # Signature move description

# Builder methods
func with_prerequisite(prereq_id: String, branch: int) -> ActiveAbilityData
func with_signature(mechanic: String) -> ActiveAbilityData
```

---

### 22. Modular Executor System

**NEW FILES:**
- `game/scripts/active_abilities/executors/base_executor.gd` - Base class
- `game/scripts/active_abilities/executors/melee_executor.gd` - Melee ability execution
- `game/scripts/active_abilities/executors/ranged_executor.gd` - Ranged ability execution
- `game/scripts/active_abilities/executors/global_executor.gd` - Global ability execution

**MODIFIED:** `game/scripts/active_abilities/ability_executor.gd`

Added routing to modular executors:
```gdscript
func _try_modular_executors(ability: ActiveAbilityData, player: Node2D) -> bool:
    if not AbilityTreeRegistry.is_ability_in_tree(ability.id):
        return false  # Fall back to legacy executor
    match ability.class_type:
        ClassType.MELEE: return _melee_executor.execute(ability, player)
        ClassType.RANGED: return _ranged_executor.execute(ability, player)
        ClassType.GLOBAL: return _global_executor.execute(ability, player)
```

Legacy abilities continue to work through fallback path.

---

### 23. Effect Module Extraction

Extracted logic from `ability_manager.gd` (3221 lines) into modular files:

**NEW FILES:**
- `game/scripts/abilities/effects/stat_effects.gd` - Stat calculations (damage, attack speed, crit, etc.)
- `game/scripts/abilities/effects/on_hit_effects.gd` - On-hit procs (ignite, frostbite, vampirism, etc.)

**EXISTING FILES (from previous work):**
- `game/scripts/abilities/effects/periodic_effects.gd` - Tick-based effects
- `game/scripts/abilities/effects/on_kill_effects.gd` - Kill streak effects
- `game/scripts/abilities/effects/combat_effects.gd` - Combat mechanics

**MODIFIED:** `game/scripts/abilities/ability_manager.gd`

Wired up all 5 effect modules:
```gdscript
var _stat_effects: StatEffects = null
var _on_hit_effects: OnHitEffects = null
var _on_kill_effects: OnKillEffects = null
var _combat_effects: CombatEffects = null
var _periodic_effects: PeriodicEffects = null

func _ready() -> void:
    _stat_effects = StatEffects.new(self)
    _on_hit_effects = OnHitEffects.new(self)
    # ... etc
```

---

### What's NOT Implemented Yet

The following features from the design doc are **NOT** implemented:

1. **Mixed Selection Pool** - Upgrades don't appear alongside passives during level-up
2. **Upgrade UI Styling** - No green borders for Tier 2, no gold borders for Tier 3
3. **Passive → Active Unlock** - Passive abilities don't trigger upgrade availability
4. **Prerequisite Enforcement** - Trees don't check if player has required abilities
5. **Branch Mutual Exclusivity** - No enforcement of "pick one branch" rule

The data layer is complete; the gameplay integration layer remains to be built.

---

### Files Created

```
game/scripts/active_abilities/trees/
├── ability_tree_node.gd
├── ability_tree_registry.gd
├── melee/
│   ├── cleave_tree.gd, bash_tree.gd, charge_tree.gd, spin_tree.gd
│   ├── slam_tree.gd, dash_tree.gd, whirlwind_tree.gd, leap_tree.gd
│   ├── shout_tree.gd, throw_tree.gd, taunt_tree.gd, execute_tree.gd
│   ├── block_tree.gd, impale_tree.gd, uppercut_tree.gd, combo_tree.gd
│   ├── roar_tree.gd, stomp_tree.gd, parry_tree.gd, rampage_tree.gd
├── ranged/
│   ├── power_shot_tree.gd, multi_shot_tree.gd, trap_tree.gd, rain_tree.gd
│   ├── turret_tree.gd, volley_tree.gd, evasion_tree.gd, explosive_tree.gd
│   ├── poison_tree.gd, frost_arrow_tree.gd, mark_tree.gd, snipe_tree.gd
│   ├── decoy_tree.gd, grapple_tree.gd, boomerang_tree.gd, smoke_tree.gd
│   ├── net_tree.gd, ricochet_tree.gd, barrage_tree.gd, quickdraw_tree.gd
├── global/
│   ├── fireball_tree.gd, frost_nova_tree.gd, lightning_tree.gd, heal_tree.gd
│   ├── teleport_tree.gd, time_tree.gd, summon_tree.gd, aura_tree.gd
│   ├── shield_tree.gd, gravity_tree.gd, bomb_tree.gd, drain_tree.gd
│   ├── curse_tree.gd, blink_tree.gd, thorns_tree.gd

game/scripts/active_abilities/executors/
├── base_executor.gd
├── melee_executor.gd
├── ranged_executor.gd
├── global_executor.gd

game/scripts/abilities/effects/
├── stat_effects.gd (new)
├── on_hit_effects.gd (new)
├── periodic_effects.gd (existing)
├── on_kill_effects.gd (existing)
├── combat_effects.gd (existing)
```

### Files Modified

15. `game/scripts/active_abilities/active_ability_data.gd` - Tier enum, prerequisite fields, builder methods
16. `game/scripts/active_abilities/ability_executor.gd` - Modular executor routing
17. `game/scripts/abilities/ability_manager.gd` - Effect module wiring
