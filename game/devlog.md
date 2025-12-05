# Devlog

---

## Date: 2025-12-05 - Complete Melee Ability Pixel Effect System

### Summary
Created procedural pixelated visual effects for all 17 melee ability trees across all 3 tiers (T1/T2/T3), totaling 84 new effect scripts. Each effect uses Godot's `_draw()` API for retro pixel art aesthetic matching the existing ground slam effects.

### Effect Overview

| Tier | Count | Style |
|------|-------|-------|
| T1 Base | 16 | Core ability visuals (stomp rings, slash arcs, charge trails) |
| T2 Branch | 34 | Enhanced versions (elemental additions, larger particles) |
| T3 Signature | 34 | Epic ultimate effects (screen shake, multi-layer particles, complex animations) |

### T1 Base Effects Created

| Tree | Effect | Description |
|------|--------|-------------|
| Stomp | stomp_pixel | Ground impact rings, dust clouds, debris |
| Cleave | cleave_pixel | Wide slash arc with blood particles |
| Charge | charge_pixel | Speed lines, impact burst, momentum trail |
| Whirlwind | whirlwind_pixel | Spinning wind particles, circular motion |
| Uppercut | uppercut_pixel | Upward arc, rising impact stars |
| Execute | execute_pixel | Deadly downward strike, death mark |
| Rampage | rampage_pixel | Fury aura, multiple rapid hits |
| Dash | dash_strike_pixel | Afterimage trail, speed blur |
| Combo | combo_strike_pixel | Multi-hit indicators, combo counter |
| Impale | impale_pixel | Piercing thrust, blood splatter |
| Parry | parry_pixel | Deflection spark, counter flash |
| Block | block_pixel | Shield raise, impact absorption |
| Throw | throw_weapon_pixel | Spinning projectile, return arc |
| Roar | roar_pixel | Sound wave rings, fear effect |
| Shout | battle_cry_pixel | Rally aura, buff indicators |
| Taunt | taunt_pixel | Aggro pull, enemy focus marks |

### T2 Branch Effects Created (34 total)

**Stomp:** quake_stomp (seismic), thunder_stomp (lightning)
**Cleave:** cleave_executioner (bloody), cleave_frost (icy)
**Charge:** trample (multi-hit), shield_charge (defensive)
**Whirlwind:** vacuum_spin (pull), flame_whirlwind (fire)
**Spin:** vortex (suction), deflect_spin (reflect)
**Uppercut:** juggle (air combo), grab_slam (grapple)
**Execute:** reaper_touch (soul), brutal_strike (overkill)
**Rampage:** frenzy (speed), fury (damage stack)
**Dash:** blade_rush (slashing), afterimage (clones)
**Combo:** chain_combo (linking), combo_finisher (finisher)
**Impale:** skewer (pierce), pinning_strike (immobilize)
**Parry:** counter_strike (riposte), deflection (redirect)
**Block:** reflect_shield (mirror), block_parry (counter)
**Throw:** ricochet_blade (bounce), grapple_throw (pull)
**Roar:** intimidate (weaken), enrage (buff)
**Shout:** rallying_cry (ally buff), berserker_rage (self buff)
**Taunt:** fortify_taunt (armor), counter_stance (reflect)

### T3 Signature Effects Created (34 total)

| Tree | Effect A | Effect B |
|------|----------|----------|
| Stomp | tectonic_shift (earth pillars, massive cracks) | thunderous_impact (lightning storm, chain zaps) |
| Cleave | guillotine (execution blade, death sentence) | shockwave_cleave (expanding force wave) |
| Charge | stampede (army charge, dust storm) | unstoppable_charge (immunity aura, battering ram) |
| Whirlwind | singularity (black hole pull, void energy) | inferno_tornado (fire vortex, ember storm) |
| Spin | bladestorm (orbiting blades, razor wind) | mirror_dance (clone army, synchronized strikes) |
| Uppercut | air_combo (aerial juggle, rising strikes) | piledriver (grab and slam, crater impact) |
| Execute | soul_harvest (spirit extraction, dark energy) | decapitate (swift kill, blood fountain) |
| Rampage | bloodlust (life steal veins, heartbeat pulse) | unstoppable_force (power eruption, tremor cracks) |
| Dash | omnislash (rapid teleport slashes, afterimages) | shadow_legion (shadow clone army, coordinated attacks) |
| Combo | infinite_combo (endless hits, energy buildup) | ultimate_finisher (charged devastation, shatter) |
| Impale | shish_kebab (multi-target skewer, blood drips) | crucify (cross formation pins, doom aura) |
| Parry | perfect_riposte (time slow, flawless counter) | mirror_guard (full reflection, shattered glass) |
| Block | mirror_shield (projectile reflect, shimmer) | riposte (block-counter sequence, energy transfer) |
| Throw | orbital_blades (circling storm, vortex) | impaler (giant spear, pinning impact) |
| Roar | crushing_presence (domination aura, crown) | blood_rage (berserker veins, burning eyes) |
| Shout | warlords_command (war banner, soldier spirits) | rage_incarnate (demon transform, fire form) |
| Taunt | unstoppable_taunt (immunity barrier, deflections) | vengeance (damage absorb, explosive release) |

### Technical Implementation

**Effect Pattern:**
```gdscript
extends Node2D

var pixel_size := 4
var duration := 0.8
var elapsed := 0.0

func _ready() -> void:
    # Initialize particles/effects
    await get_tree().create_timer(duration).timeout
    queue_free()

func _process(delta: float) -> void:
    elapsed += delta
    # Update animations
    queue_redraw()

func _draw() -> void:
    # Pixelated rendering using draw_rect()
```

**Common Features:**
- 4px pixel grid for retro aesthetic
- Alpha fading for smooth transitions
- Screen shake via `camera.shake()` for T3 impacts
- Layered particle systems (trails, auras, debris)
- Color-coded by ability type (red=damage, blue=ice, gold=buff)

### Files Created

**Scripts (84 files):**
`game/scripts/active_abilities/effects/`
- 16 T1 base effects (*_pixel_effect.gd)
- 34 T2 branch effects (*_pixel_effect.gd)
- 34 T3 signature effects (*_pixel_effect.gd)

**Scenes (84 files):**
`game/scenes/effects/ability_effects/`
- 16 T1 scenes (*_pixel.tscn)
- 34 T2 scenes (*_pixel.tscn)
- 34 T3 scenes (*_pixel.tscn)

### Files Modified

- `ability_executor.gd` - Added effect ID mappings for all 84 effects in `_get_mapped_effect()`
- `block_tree.gd` - Fixed cooldowns (block_parry 4.0→6.0, block_riposte 5.0→8.0)
- `shout_tree.gd` - Fixed cooldown (shout_berserk 10.0→12.0)

### Cooldown Balance Fixes

T2/T3 upgrades should maintain or increase cooldown from T1 (not decrease):

| Ability | Before | After |
|---------|--------|-------|
| block_parry (Block T2) | 4.0s | 6.0s |
| block_riposte (Block T3) | 5.0s | 8.0s |
| shout_berserk (Shout T2) | 10.0s | 12.0s |

---

## Date: 2025-12-05 - UI Polish, Visual Effects & Ability Improvements

### Summary
Fixed white border artifacts on ability icons, enhanced visual effects for Savage Leap tree, added skillshot aiming system, improved ground slam visibility, and various UI/ability tweaks.

### 1. Ability Icon White Border Fix

**Problem:** Frost orbit and other circular ability icons had white border artifacts from texture edge sampling.

**Solution:** Added UV inset (0.92) to avoid sampling edge pixels during circular texture clipping.

**Files Modified:**
- `active_ability_selection_ui.gd` - Fixed UV mapping in `_draw()` icon rendering
- `active_ability_button.gd` - Fixed UV mapping in `_draw()` icon rendering

### 2. T3 Upgrade Green Flames Enhancement

Increased green flame particle intensity for Tier 3 (Signature) upgrades vs Tier 2 (Branch) upgrades.

| Tier | Flame Intensity | Flame Density |
|------|-----------------|---------------|
| T2 (Branch) | 1.5 | 14.0 |
| T3 (Signature) | 2.2 | 22.0 |

**Files Modified:**
- `active_ability_selection_ui.gd` - `_create_particle_container_for_ability()` and `_create_upgrade_particle_container()`

### 3. Savage Leap Pixelated Visual Effects

Created complete pixelated effect system for the Savage Leap ability tree with fantasy RPG aesthetic.

| Ability | Tier | Effect Description |
|---------|------|-------------------|
| Savage Leap | BASE | Dust cloud, ground cracks, debris |
| Tremor Leap | T2-A | Seismic shockwave rings, ground ruptures |
| Predator Leap | T2-B | Beast claw marks, speed trails, feral energy |
| Extinction Event | T3-A | Massive meteor crater with fire rings |
| Apex Strike | T3-B | Deadly slash marks with blood spray |

**Key Feature:** T2 effects now spawn alongside base effects (instead of replacing them), creating layered visual feedback.

**Files Created:**
- `savage_leap_pixel_effect.gd` + `.tscn`
- `tremor_leap_effect.gd` + `.tscn`
- `predator_leap_effect.gd` + `.tscn`
- `extinction_event_effect.gd` + `.tscn`
- `apex_strike_effect.gd` + `.tscn`

**Files Modified:**
- `ability_executor.gd` - Effect ID mappings
- `melee_executor.gd` - Multi-effect spawning for T2/T3

### 4. Flame Wall Skillshot Aiming

Made Flame Wall use skillshot aiming system - wall orientation follows aim direction while maintaining perpendicular placement.

**Behavior:**
- If using aimed shot: Wall placed in aim direction, perpendicular to that direction
- If not aiming: Falls back to nearest enemy targeting

**Files Modified:**
- `ability_executor.gd` - `_execute_flame_wall()` checks `ActiveAbilityManager.is_using_aimed_shot()`

### 5. Skillshot Visual Indicator on Ability Icons

Added crosshair/target indicator to ability icons that support skillshot aiming.

**Visual Design:**
- White crosshair lines (4 directions) drawn inward from icon edge
- Dark outline for contrast against any background
- 45-degree corner brackets for additional visual interest
- Only appears on abilities where `ability.supports_skillshot()` returns true

**Files Modified:**
- `active_ability_button.gd` - Added `_draw_skillshot_indicator()` function

### 6. Ground Slam Effect Enhancement

Made ground slam visual effect more noticeable and persistent.

| Property | Before | After |
|----------|--------|-------|
| Duration | 0.4s | 0.65s |
| Ring Color | Brown | Golden/Orange |
| Shockwave Rings | 1 | 3 (staggered) |
| Impact Flash | None | Bright white flash |
| Debris Count | 12-18 | 18-28 |
| Dust Count | 20-30 | 30-45 |
| Fade Speed | Fast | Slower (0.7x multiplier) |

**Files Modified:**
- `ground_slam_pixel_effect.gd` - Complete visual overhaul

### 7. Ability Button Position Adjustments

Fine-tuned ability bar button positions for better ergonomics.

| Button | Change |
|--------|--------|
| Ability 2 | Moved up 20px more (40px total offset) |
| Dodge | Moved 20px left |
| Ability 1 | Unchanged |
| Ability 3 | Unchanged |

**Files Modified:**
- `active_ability_bar.gd` - Button positioning calculations

### 8. Ability Cleanup & Balance

| Change | Details |
|--------|---------|
| Now You See Me | Commented out (needs rework) |
| Cooldown Killer | Rarity changed from EPIC to LEGENDARY |
| Tooltip Hide | Tooltips now hide when player releases ability button |

**Files Modified:**
- `active_ability_database.gd` - Commented out Now You See Me
- `combat_passives.gd` - Cooldown Killer rarity change
- `active_ability_button.gd` - Added `_hide_tooltip()` on input release

---

## Date: 2025-12-05 - Spawn Rate Curve & Options Updates

### Summary
Implemented time-based spawn rate curve to shift difficulty intensity toward late game. Added Damage Numbers toggle to options. Added summon prerequisite to Survivor's Guilt. Updated Rain of Arrows with falling arrow visuals.

### 1. Time-Based Spawn Rate Curve

**Problem:** On higher difficulties (Easy+), early game (~2.5 min) felt overwhelming while late game didn't scale further.

**Solution:** Quadratic spawn curve that starts at 50% spawn rate and ramps to 100% at 7.5 minutes, then continues to 150% in late game.

| Time | Spawn Rate Multiplier |
|------|----------------------|
| 0 min | 50% |
| 2.5 min | ~60% |
| 5 min | ~80% |
| 7.5 min | 100% |
| 10 min | ~125% |
| 15 min | 150% (capped) |

**Implementation:** Added `get_time_spawn_multiplier()` in `enemy_spawner.gd` using quadratic curve:
```gdscript
const SPAWN_CURVE_BASE: float = 0.5        # Start at 50%
const SPAWN_CURVE_FULL_TIME: float = 450.0 # 7.5 min to reach 100%
const SPAWN_CURVE_EXPONENT: float = 2.0    # Quadratic curve
const SPAWN_CURVE_MAX: float = 1.5         # Cap at 150%
```

### 2. Damage Numbers Toggle

Added new option to disable damage number popups for performance/preference.

**Files Modified:**
- `game_settings.gd` - Added `damage_numbers_enabled` setting
- `pause_menu.gd` - Added toggle UI
- `main_menu.gd` - Added toggle UI
- `enemy_base.gd` - Check setting in `spawn_damage_number()`
- `player.gd` - Check setting in `spawn_damage_number()` and `spawn_blocked_damage_number()`
- `arrow.gd` - Check `status_text_enabled` for elemental status text (BURN, ZAP, etc.)

### 3. Survivor's Guilt Prerequisite

Added summon ability prerequisite to Survivor's Guilt passive. Now requires one of:
- chicken_companion, summoner_aid, drone_support, blade_orbit, flame_orbit, frost_orbit

**File Modified:** `chaos_passives.gd`

### 4. Rain of Arrows Falling Arrow Visuals

Applied satisfying falling arrow visual effect to all Rain of Arrows tree abilities:
- Added `_spawn_falling_arrow_visual()` and `_spawn_arrow_impact_visual()` helpers
- Updated `_spawn_storm_arrow()`, `_execute_rain_apocalypse()`, `_execute_rain_focused()`
- Arrows fall from sky with rotation, golden tint, TRANS_QUAD acceleration, dust particle impacts

**File Modified:** `ranged_executor.gd`

---

## Date: 2025-12-05 - Passive Ability Prerequisite System

### Summary
Implemented a prerequisite system for passive upgrade abilities, guaranteeing upgrade opportunities every 4 passive levels, and added synergy-based weight boosting for better build cohesion.

### New Features

#### 1. Prerequisite System for Passive Abilities
Upgrade abilities now require owning at least one prerequisite ability before appearing in selection.

| Upgrade Ability | Requires (any of) |
|-----------------|-------------------|
| Orbital Amplifier | blade_orbit, flame_orbit, frost_orbit |
| Orbital Mastery | orbital_amplifier |
| Pack Leader | chicken_companion, summoner_aid, any orbital |
| Momentum Master | rampage, killing_frenzy, massacre |
| Conductor | lightning_strike_proc, static_charge |
| Chain Reaction | ignite, frostbite, toxic_tip, lightning_strike_proc, static_charge, chaotic_strikes |
| Elemental Infusion | ignite, frostbite, toxic_tip, lightning_strike_proc, static_charge, chaotic_strikes |
| Empathic Bond | any orbital, ring_of_fire, toxic_cloud, tesla_coil |

#### 2. Guaranteed Upgrade Every 4 Passive Levels
- Tracks `passive_selections_since_upgrade` counter
- After 4 passive ability selections without an upgrade, guarantees one upgrade slot appears
- Counter resets when player selects any upgrade ability
- Counter resets on game restart

#### 3. Synergy Weight Boosting (1.5x / 50%)
Abilities that synergize with current build get 50% higher selection weight:
- **Orbital effects** → boosted if player has any orbital
- **Summon damage** → boosted if player has summons (chicken, skeleton, drone)
- **Chain Reaction/Conductor** → boosted if player has elemental effects
- **Momentum Master** → boosted if player has kill streak abilities
- **Empathic Bond** → boosted if player has auras/orbitals

### Technical Implementation

**AbilityData class** (`ability_data.gd`):
- Added `prerequisite_ids: Array[String]` - must own at least one
- Added `synergy_ids: Array[String]` - for soft weight boosting
- Added `is_upgrade: bool` - marks abilities as upgrades
- Added fluent builder methods: `with_prerequisites()`, `with_synergies()`, `as_upgrade()`

**AbilityManager** (`ability_manager.gd`):
- Added `_meets_prerequisites()` check in `get_available_abilities()`
- Added `_has_synergy_with_current_build()` and `_check_implicit_synergies()`
- Modified `pick_weighted_random()` to apply synergy boost
- Modified `acquire_ability()` to track selections and reset counter
- Added passive selection tracking in `reset()`

### Files Modified
- `game/scripts/abilities/ability_data.gd` - Prerequisite/synergy fields and builder methods
- `game/scripts/abilities/ability_manager.gd` - Selection logic, tracking, synergy checks
- `game/scripts/abilities/passives/orbital_passives.gd` - Prerequisites for Orbital Amplifier, Mastery
- `game/scripts/abilities/passives/summon_passives.gd` - Prerequisites for Pack Leader
- `game/scripts/abilities/passives/synergy_passives.gd` - Prerequisites for Momentum Master, Conductor
- `game/scripts/abilities/passives/elemental_passives.gd` - Prerequisites for Chain Reaction
- `game/scripts/abilities/passives/legendary_passives.gd` - Prerequisites for Empathic Bond
- `game/scripts/abilities/ability_database.gd` - Prerequisites for Elemental Infusion

---

## Date: 2025-12-05 - Passive Balance & Mass Ability Implementations

### Summary
Adjusted passive abilities for balance. Implemented 140+ missing ability tree abilities across all three executors. Disabled Fireball.

### Passive Balance Changes

| Ability | Stat | Before | After |
|---------|------|--------|-------|
| Regeneration | Heal Rate | 1% HP every 5 seconds | 1% HP every 2.5 seconds |
| Time Dilation | Enemy Slow | 20% slower | 10% slower |

### Mass Ability Implementations

Added complete implementations for all missing tier 2 and tier 3 abilities:

| Executor | Trees Implemented | Abilities Added |
|----------|-------------------|-----------------|
| Melee | Throw, Taunt, Execute, Block, Impale, Uppercut, Combo, Stomp, Parry, Rampage | ~50 abilities |
| Ranged | Explosive, Poison, Frost Arrow, Mark, Snipe, Grapple, Boomerang, Net, Ricochet, Barrage, Quickdraw | ~55 abilities |
| Global | Aura, Shield, Bomb, Drain, Curse, Blink, Thorns | ~35 abilities |

Each ability includes:
- Damage mechanics with proper scaling
- Status effects (stun, slow, burn, poison, bleed, etc.)
- Procedural pixelated visual effects using Polygon2D
- Screen shake and impact pause for feel

### Fireball Disabled
- Commented out in `active_ability_database.gd` (standalone ability)
- Tree already disabled in `ability_tree_registry.gd`

### Files Modified
- `game/scripts/abilities/ability_database.gd` - Regeneration/Time Dilation values
- `game/scripts/active_abilities/active_ability_database.gd` - Disabled Fireball
- `game/scripts/active_abilities/executors/melee_executor.gd` - 10 tree implementations
- `game/scripts/active_abilities/executors/ranged_executor.gd` - 11 tree implementations
- `game/scripts/active_abilities/executors/global_executor.gd` - 7 tree implementations

---

## Date: 2025-12-05 - Global Tree Implementations & Ability Cleanup

### Summary
Added complete implementations for Time, Teleport, Summon, and Gravity ability trees. Fixed ranged executor issues. Cleaned up duplicate global abilities. Upgraded Multi-Shot damage.

### New Global Tree Implementations (global_executor.gd)

**Time Tree (5 abilities):**
| Ability | Effect |
|---------|--------|
| time_slow | Slow enemies in radius (does NOT affect player), pixelated time bubble |
| time_stop | Freeze all enemies in radius completely |
| time_prison | Trap single enemy in time stasis, massive damage on release |
| time_rewind | Reset player position to 3 seconds ago, heal 30% of damage taken |
| chronoshift | Complete time freeze, player acts freely, massive damage on unfreeze |

**Teleport Tree (5 abilities):**
| Ability | Effect |
|---------|--------|
| teleport | Basic blink to target location |
| blink | Longer range blink with brief invulnerability |
| dimension_shift | Swap positions with nearest enemy |
| shadowstep | Teleport behind enemy, deal backstab damage |
| shadow_swap | Swap with enemy and deal massive damage to all enemies near both positions |

**Summon Tree (5 abilities):**
| Ability | Effect |
|---------|--------|
| summon_minion | Spawn basic minion that fights for you |
| summon_golem | Spawn tanky golem with high health |
| summon_titan | Spawn massive titan with ground slam attacks |
| summon_swarm | Spawn 5 small fast minions |
| army_of_the_dead | Spawn 8 skeleton warriors |

**Gravity Tree (5 abilities):**
| Ability | Effect |
|---------|--------|
| gravity_well | Pull enemies to center, deal damage over time |
| crushing_gravity | Intense gravity field, heavy damage + slow |
| singularity | Black hole that pulls and damages all enemies |
| repulse | Push all enemies away from player |
| supernova | Massive explosion after gravity collapse |

### Ranged Executor Fixes

| Fix | Details |
|-----|---------|
| multi_fan 360° | Fixed to use full TAU spread instead of 60° |
| trap_bear inline | Added full inline implementation with Polygon2D visuals |
| rain_storm/apocalypse | Added inline implementations with damage ticks |
| rain_orbital | Added orbital strike effect |
| turret fallbacks | Added _start_turret_shooting and _start_artillery_shooting |
| Smoke Tree | Added all 5 abilities (smoke_bomb through smoke_sanctuary) |
| Decoy Tree | Added all 5 abilities (decoy through decoy_horde) |

### Global Ability Duplicates Removed

8 standalone global abilities commented out (now available through trees):

| Ability | Tree Equivalent |
|---------|-----------------|
| meteor_strike | Fireball Tree T2 (fireball_meteor) |
| shadowstep | Teleport Tree T2 B (teleport_shadow) |
| black_hole | Gravity Tree T3 A (gravity_singularity) |
| time_stop | Time Tree T2 A (time_stop) |
| thunderstorm | Lightning Tree T2 A (chain_lightning_storm) |
| summon_golem | Summon Tree T2 A (summon_golem) |
| army_of_the_dead | Summon Tree T3 B (summon_army) |
| repulsive | Gravity Tree T2 B (gravity_repulse) |

### Multi-Shot Damage Upgrade

| Stat | Before | After | Change |
|------|--------|-------|--------|
| Base Damage | 30 | 45 | +50% |
| Damage Scaling | 1.0x | 1.2x | +20% |
| Effective Damage | 30 | 54 | +80% |

### Fireball Tree Disabled

Fireball tree registration commented out in `ability_tree_registry.gd` for temporary disabling.

### Files Modified
- `global_executor.gd` - Added Time, Teleport, Summon, Gravity tree implementations (~400 lines)
- `ranged_executor.gd` - Fixed multi_fan, added trap_bear, rain, turret, smoke, decoy implementations
- `active_ability_database.gd` - Commented out 8 duplicate global abilities
- `multi_shot_tree.gd` - Upgraded damage from 30/1.0x to 45/1.2x
- `ability_tree_registry.gd` - Commented out FireballTree registration

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
