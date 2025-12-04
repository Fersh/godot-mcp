# Ability System Revamp - Ideas & Design Document

## Design Decisions (User Confirmed)

### Active Abilities - Tiered Branching System
- **Mixed Pool**: Upgrades appear alongside passives in the same 3-choice level-up screen
- **Branch Display**: Each branch appears as a separate card in main pool (not guaranteed, passives can appear too)
- **Migration**: Convert existing 40+ abilities into the new tiered system
- **Ability Count Target**:
  - 20 Melee base abilities
  - 20 Ranged base abilities
  - 10-15 Global abilities (class agnostic, available to all)
  - Each base has 2+ Tier 2 branches
  - Each Tier 2 has 1+ Tier 3 branches

### Passive Abilities - Branch System for Key Passives
- Key passives (orbitals, summons, major effects) get branch upgrades like actives
- Simple stat passives remain flat one-time pickups

### Selection Pool Weighting
- Boost upgrades: ~40% of choices are upgrades if available
- Remaining slots filled with passives/new abilities

### Tier 3 Philosophy: "Signature Move"
- Tier 3 adds a unique mechanic/visual that defines the ability
- Not just number scaling - should feel distinctive and memorable

---

## Research Insights from Other Games

### Hades Boon System
- **Tiered Prerequisites**: Need Tier 1 + Tier 2 boons to unlock Legendary
- **Duo Boons**: Combine powers of two gods for unique effects
- **Rarity Upgrades**: Can exchange lower rarity for higher
- Source: [Hades Wiki - Boons](https://hades.fandom.com/wiki/Boons)

### Path of Exile Skill Gems
- **Modular Support System**: Support gems modify active skills
- **Stacking Effects**: Multiple supports create emergent combos
- **PoE 2**: Up to 5 support sockets per skill gem
- Source: [PoE Wiki](https://www.poewiki.net/wiki/Skill_gem)

### Vampire Survivors Evolution
- **Base + Catalyst = Evolution**: Weapon + specific passive item = evolved form
- **Union System**: Two weapons merge into one powerful version
- Source: [VS Evolution Guide](https://vampire-survivors.fandom.com/wiki/Evolution)

### Diablo 4 Skill Tree
- **2 Branch Upgrades per Skill**: Choose only 1 of 2 paths
- **Spaced Choices**: Don't overwhelm with all options at once
- **30-40% Node Cap**: Can't unlock everything
- Source: [D4 Skill Tree Guide](https://mythicdrop.com/guide/diablo-4-skill-tree)

### Risk of Rain 2 Item Design
- **Everything Stacks**: Items synergize, rarely conflict
- **Emergent Builds**: Unexpected combinations = engagement
- Source: [RoR2 Stacking Guide](https://riskofrain2.fandom.com/wiki/Item_Stacking)

---

## Current Ability Inventory (To Convert)

### Melee Common (Tier 1 Candidates)
1. **Cleave** - Wide arc attack
2. **Shield Bash** - Stun + knockback
3. **Ground Slam** - AoE around self
4. **Spinning Attack** - 360 damage
5. **Dash Strike** - Movement + damage

### Melee Rare (Could become Tier 1 or Tier 2)
6. **Whirlwind** - Sustained spinning
7. **Seismic Slam** - Ground shockwave
8. **Savage Leap** - Jump attack
9. **Blade Rush** - Multi-dash attack
10. **Battle Cry** - Buff/debuff AoE

### Melee Legendary (Tier 2/3 Candidates)
11. **Earthquake** - Massive ground AoE
12. **Bladestorm** - Ultimate spinning
13. **Omnislash** - Multi-target dash
14. **Avatar of War** - Transformation
15. **Divine Shield** - Invulnerability + damage

### Ranged Common (Tier 1 Candidates)
16. **Power Shot** - High damage single
17. **Explosive Arrow** - AoE on impact
18. **Multi Shot** - Multiple projectiles
19. **Quick Roll** - Evasive + attack

### Ranged Rare (Could become Tier 1 or Tier 2)
20. **Rain of Arrows** - AoE barrage
21. **Piercing Volley** - Line damage
22. **Cluster Bomb** - Scatter explosion
23. **Fan of Knives** - Cone attack
24. **Sentry Turret** - Deployable

### Ranged Legendary (Tier 2/3 Candidates)
25. **Arrow Storm** - Screen-wide
26. **Ballista Strike** - Massive single hit
27. **Sentry Network** - Multi-turret
28. **Rain of Vengeance** - Ultimate barrage
29. **Explosive Decoy** - Clone + explosion

### Global Common
30. **Fireball** - Projectile + burn
31. **Healing Light** - Self heal
32. **Throwing Bomb** - AoE explosion

### Global Rare
33. **Frost Nova** - AoE freeze
34. **Chain Lightning** - Bouncing damage
35. **Meteor Strike** - Delayed AoE
36. **Totem of Frost** - Deployable slow
37. **Shadowstep** - Teleport
38. **Time Slow** - Area slow field

### Global Legendary
39. **Black Hole** - Pull + damage
40. **Time Stop** - Freeze all
41. **Thunderstorm** - Lightning rain
42. **Summon Golem** - Tank minion
43. **Army of the Dead** - Mass summon

### Zone/Wall Abilities
44. **Flame Wall** - Line of fire
45. **Ice Barricade** - Blocking wall
46. **Floor is Lava** - Ground hazard

### Trap Abilities
47. **Bear Trap** - Root enemy
48. **Glue Bomb** - AoE slow
49. **Pressure Mine** - Triggered explosion

### Stealth Abilities
50. **Smoke Bomb** - Invisibility
51. **Now You See Me** - Decoy + invis

---

## Proposed Base Abilities & Branch Ideas

### MELEE BASE ABILITIES (20 Target)

#### 1. BASH (Base)
**Core**: Single target melee hit with short stun

**Tier 2 Branches:**
- **Shockwave Bash**: AoE cone stun, shorter duration
- **Lockdown Bash**: Single target, 3x stun duration
- **Vengeful Bash**: Reflects 50% damage taken during animation

**Tier 3 Branches:**
- Shockwave → **Earthquake Slam**: Massive AoE, enemies knocked airborne
- Lockdown → **Petrifying Strike**: Stunned enemies take 2x damage, can chain stun
- Vengeful → **Retribution**: Immune during cast, explodes for all damage taken recently

---

#### 2. CLEAVE (Base)
**Core**: Wide arc attack hitting multiple enemies

**Tier 2 Branches:**
- **Sweeping Cleave**: 360 degree swing, lower damage
- **Executioner's Cleave**: Narrow arc, +100% damage to wounded enemies
- **Bleeding Cleave**: Applies heavy bleed to all hit

**Tier 3 Branches:**
- Sweeping → **Whirlwind**: Continuous spinning, move while attacking
- Executioner → **Guillotine**: Instant kill enemies under 20% HP
- Bleeding → **Hemorrhage**: Bleed spreads to nearby enemies

---

#### 3. CHARGE (Base)
**Core**: Rush forward, damage first enemy hit

**Tier 2 Branches:**
- **Trampling Charge**: Damage ALL enemies in path
- **Shield Charge**: Immune during charge, knockback at end
- **Reckless Charge**: 2x damage, take 50% more damage for 2s

**Tier 3 Branches:**
- Trampling → **Stampede**: Leaves fire trail, 3x distance
- Shield → **Unstoppable Force**: Stun all in path, destroy projectiles
- Reckless → **Berserker Rush**: Chain to next enemy if killed

---

#### 4. SLAM (Base)
**Core**: Ground pound AoE around self

**Tier 2 Branches:**
- **Seismic Slam**: Shockwave travels outward in ring
- **Crater Slam**: Creates damaging zone that persists
- **Leaping Slam**: Jump to location, AoE on landing

**Tier 3 Branches:**
- Seismic → **Tectonic Shift**: Multiple rings, screen shake
- Crater → **Volcanic Eruption**: Crater explodes after delay, lava pool
- Leaping → **Meteor Drop**: Massive AoE, immune while airborne

---

#### 5. SPIN (Base)
**Core**: Quick 360 attack around self

**Tier 2 Branches:**
- **Blade Vortex**: Sustained spinning, drains stamina
- **Deflecting Spin**: Reflects projectiles while spinning
- **Razor Tornado**: Creates projectiles that orbit outward

**Tier 3 Branches:**
- Blade Vortex → **Bladestorm**: Moves freely, pulls enemies in
- Deflecting → **Mirror Dance**: Reflected projectiles seek enemies
- Razor → **Storm of Steel**: Tornado persists, wanders the arena

---

#### 6. THROW WEAPON (Base)
**Core**: Throw melee weapon, returns like boomerang

**Tier 2 Branches:**
- **Ricochet Throw**: Bounces between enemies
- **Explosive Throw**: Explodes on first hit
- **Grappling Throw**: Pulls enemy to you

**Tier 3 Branches:**
- Ricochet → **Pinball**: Infinite bounces for 3 seconds
- Explosive → **Cluster Bomb**: Splits into smaller explosives
- Grappling → **Executioner's Pull**: Pulled enemy takes massive damage

---

#### 7. SHOUT (Base)
**Core**: AoE buff to self, minor enemy pushback

**Tier 2 Branches:**
- **Battle Cry**: Attack speed buff to self
- **Intimidating Roar**: Fear enemies, they flee
- **War Horn**: Buff extends to summoned allies

**Tier 3 Branches:**
- Battle Cry → **Avatar of War**: Transform, massive stat boost, timed
- Intimidating → **Demoralizing Presence**: Feared enemies take 2x damage
- War Horn → **Call to Arms**: Summon warrior spirits temporarily

---

#### 8. BLOCK (Base)
**Core**: Raise shield, immune from front for 1s

**Tier 2 Branches:**
- **Shield Bash Block**: Counter-attack after block
- **Absorbing Block**: Blocked damage heals you
- **Reflecting Block**: Blocked projectiles return to sender

**Tier 3 Branches:**
- Shield Bash → **Riposte Master**: Perfect block = massive counter
- Absorbing → **Vampiric Guard**: Overheal becomes shield
- Reflecting → **Mirror Wall**: Create persistent reflective barrier

---

#### 9. GRAPPLE (Base)
**Core**: Pull yourself to an enemy, small damage

**Tier 2 Branches:**
- **Chain Grapple**: Hit multiple enemies in line
- **Suplex Grapple**: Grab and slam enemy for big damage
- **Hookshot**: Pull to walls/terrain for mobility

**Tier 3 Branches:**
- Chain → **Reaper's Harvest**: Pull ALL nearby enemies to you
- Suplex → **Piledriver**: AoE shockwave on slam
- Hookshot → **Spider's Web**: Leave web trail, slows enemies

---

#### 10. TAUNT (Base)
**Core**: Force nearby enemies to attack you, gain armor

**Tier 2 Branches:**
- **Mocking Taunt**: Taunted enemies deal less damage
- **Explosive Taunt**: When taunt ends, AoE explosion
- **Sacrificial Taunt**: Take damage for allies (if co-op)

**Tier 3 Branches:**
- Mocking → **Humiliation**: Taunted enemies attack each other
- Explosive → **Martyr's End**: Bigger explosion if you took damage
- Sacrificial → **Last Stand**: Immune at 1 HP while taunt active

---

#### 11. UPPERCUT (Base)
**Core**: Launch single enemy airborne

**Tier 2 Branches:**
- **Juggle Combo**: Can attack airborne enemies
- **Meteor Fist**: Enemy crashes down with AoE
- **Geyser Strike**: Water/earth erupts from ground

**Tier 3 Branches:**
- Juggle → **Infinite Combo**: Keep enemy airborne indefinitely
- Meteor → **Orbital Strike**: Enemy launched into space, crashes with massive AoE
- Geyser → **Eruption**: Continuous geyser zone

---

#### 12. ENRAGE (Base)
**Core**: Self-buff, +damage, -defense

**Tier 2 Branches:**
- **Blood Rage**: More damage as HP drops
- **Frenzy**: Attack speed instead of damage
- **Pain Conversion**: Damage taken adds to next attack

**Tier 3 Branches:**
- Blood Rage → **Death Wish**: At 1HP, invincible for 5s, insane damage
- Frenzy → **Flurry**: Attack 5x per swing
- Pain Conversion → **Vengeance Incarnate**: Store unlimited damage, release all at once

---

#### 13. IMPALE (Base)
**Core**: Thrust attack, high single target damage

**Tier 2 Branches:**
- **Skewer**: Pierce through multiple enemies
- **Pinning Strike**: Root enemy in place
- **Vital Strike**: Crit chance +50%

**Tier 3 Branches:**
- Skewer → **Shish Kebab**: Carry enemies on weapon, slam them
- Pinning → **Crucify**: Pinned enemies explode when killed
- Vital → **Heart Seeker**: Guaranteed crit, bonus damage = enemy max HP %

---

#### 14. PARRY (Base)
**Core**: Timed block, if successful = counter

**Tier 2 Branches:**
- **Riposte**: Counter does 3x damage
- **Disarm**: Counter removes enemy attack for 3s
- **Counter Spell**: Can parry projectiles/magic

**Tier 3 Branches:**
- Riposte → **Lethal Precision**: Perfect parry = instant kill
- Disarm → **Weapon Steal**: Use enemy's attack against them
- Counter Spell → **Spell Mirror**: Return any spell at 2x power

---

#### 15. OVERPOWER (Base)
**Core**: Slow heavy attack, breaks enemy guard

**Tier 2 Branches:**
- **Crushing Blow**: Bonus damage to armored enemies
- **Stagger Strike**: Slows enemy attack speed
- **Concussive Hit**: Confuses enemy (attacks allies)

**Tier 3 Branches:**
- Crushing → **Armor Shatter**: Permanently remove enemy armor
- Stagger → **Time Fracture**: Enemy moves in slow motion permanently
- Concussive → **Mind Break**: Enemy becomes your ally

---

#### 16. BERSERK STANCE (Base)
**Core**: Toggle - more damage, can't use other abilities

**Tier 2 Branches:**
- **Primal Rage**: Attacks cleave, life steal
- **Rampage Mode**: Kills extend duration
- **Unstable Power**: Random bonus effects per hit

**Tier 3 Branches:**
- Primal → **Beast Form**: Transform into monster
- Rampage → **Endless Slaughter**: Each kill = stronger, no cap
- Unstable → **Chaos Incarnate**: Every attack is different random ability

---

#### 17. EXECUTE (Base)
**Core**: Finisher move, bonus damage to low HP enemies

**Tier 2 Branches:**
- **Clean Kill**: Instant kill below 15% HP
- **Brutal Execution**: Overkill damage splashes
- **Soul Reap**: Gain buffs from executed enemies

**Tier 3 Branches:**
- Clean Kill → **Death Sentence**: Mark enemy, auto-execute when low
- Brutal → **Massacre**: Executed enemy explodes in gore
- Soul Reap → **Soul Collection**: Build up souls for mega-attack

---

#### 18. FORTIFY (Base)
**Core**: Temporary armor boost, rooted in place

**Tier 2 Branches:**
- **Iron Skin**: Immune to status effects while fortified
- **Thorns Stance**: Return damage to attackers
- **Regenerating Fort**: Heal while fortified

**Tier 3 Branches:**
- Iron Skin → **Living Statue**: Full immunity, can't move
- Thorns → **Pain Reflection**: Return 200% damage
- Regenerating → **Phoenix Guard**: If killed while fortified, revive

---

#### 19. COMBO STRIKE (Base)
**Core**: Basic attack, if used consecutively = stacking bonus

**Tier 2 Branches:**
- **Rising Dragon**: 3rd hit launches + fire
- **Thunder Combo**: 3rd hit = lightning AoE
- **Infinite Combo**: No cap on combo counter

**Tier 3 Branches:**
- Rising Dragon → **Heaven's Fist**: Final hit calls down divine strike
- Thunder → **Storm Lord**: Combo summons persistent lightning
- Infinite → **One Million Hits**: Combo counter becomes damage multiplier

---

#### 20. SUMMON WEAPON (Base)
**Core**: Conjure spectral blade that attacks nearby

**Tier 2 Branches:**
- **Blade Orbit**: Sword orbits you continuously
- **Dancing Blade**: Sword seeks enemies independently
- **Blade Barrage**: Multiple swords spawn

**Tier 3 Branches:**
- Blade Orbit → **Orbital Array**: 8 blades in formation
- Dancing → **Possessed Arsenal**: Sword clones your attacks
- Barrage → **Sword Rain**: Blades fall from sky constantly

---

### RANGED BASE ABILITIES (20 Target)

#### 1. POWER SHOT (Base)
**Core**: Charged single arrow, high damage

**Tier 2 Branches:**
- **Piercing Shot**: Goes through enemies
- **Explosive Shot**: AoE on impact
- **Homing Shot**: Seeks nearest enemy

**Tier 3 Branches:**
- Piercing → **Rail Gun**: Infinite pierce, screen-wide line
- Explosive → **Nuke Arrow**: Massive explosion radius
- Homing → **Nemesis Arrow**: Follows target through walls until hit

---

#### 2. MULTI SHOT (Base)
**Core**: Fire 3 arrows in a spread

**Tier 2 Branches:**
- **Fan of Knives**: 5 projectiles, wider spread
- **Focused Volley**: 3 arrows, all hit same target
- **Scatter Shot**: Random directions, more projectiles

**Tier 3 Branches:**
- Fan → **Blade Tornado**: 12 projectiles, 360 degrees
- Focused → **Triple Threat**: Each arrow spawns 3 more on hit
- Scatter → **Bullet Hell**: Constant random projectile spray

---

#### 3. RAIN OF ARROWS (Base)
**Core**: AoE arrow barrage at target location

**Tier 2 Branches:**
- **Meteor Arrows**: Slower, bigger impact damage
- **Persistent Rain**: Longer duration, less damage per hit
- **Seeking Rain**: Arrows curve toward enemies

**Tier 3 Branches:**
- Meteor → **Arrow Apocalypse**: Screen-wide destruction
- Persistent → **Endless Storm**: Permanent zone while channeled
- Seeking → **Smart Munitions**: Arrows seek weakest enemy

---

#### 4. TRAP (Base)
**Core**: Place floor trap, triggers when enemy steps on

**Tier 2 Branches:**
- **Bear Trap**: Root + damage
- **Explosive Trap**: AoE damage
- **Poison Trap**: DoT cloud

**Tier 3 Branches:**
- Bear → **Chain Trap**: Trapped enemy's allies get pulled in
- Explosive → **Cluster Mine**: Spawns more traps on detonation
- Poison → **Plague Zone**: Poison spreads between enemies

---

#### 5. TURRET (Base)
**Core**: Deploy stationary turret that auto-attacks

**Tier 2 Branches:**
- **Rapid Fire Turret**: Faster attacks, less damage
- **Cannon Turret**: Slow, explosive shots
- **Healing Turret**: Heals player instead of attacking

**Tier 3 Branches:**
- Rapid Fire → **Minigun Nest**: Ludicrous fire rate
- Cannon → **Artillery Platform**: Screen-range, huge AoE
- Healing → **Resurrection Beacon**: Revives player once if killed

---

#### 6. RICOCHET (Base)
**Core**: Bouncing projectile, hits 3 enemies

**Tier 2 Branches:**
- **Infinite Bounce**: No bounce limit, duration-based
- **Splitting Ricochet**: Creates more projectiles per bounce
- **Seeking Ricochet**: Bounces prioritize uninjured enemies

**Tier 3 Branches:**
- Infinite → **Pinball Wizard**: Bounces gain damage each hit
- Splitting → **Fractal Arrow**: Exponential projectile growth
- Seeking → **Hunter's Mark**: Hit enemies take +damage from all sources

---

#### 7. EVASIVE SHOT (Base)
**Core**: Dodge roll + fire arrow backward

**Tier 2 Branches:**
- **Shadow Step**: Teleport instead of roll
- **Counter Shot**: If dodged an attack, +300% damage
- **Smoke Roll**: Leave smoke cloud, blind enemies

**Tier 3 Branches:**
- Shadow Step → **Blink Strike**: Teleport behind enemy, backstab
- Counter Shot → **Bullet Time**: Slow motion during dodge window
- Smoke → **Ninja Vanish**: Become invisible for 3s after roll

---

#### 8. POISON ARROW (Base)
**Core**: Arrow applies poison DoT

**Tier 2 Branches:**
- **Venomous Shot**: Stronger poison, shorter duration
- **Plague Arrow**: Poison spreads to nearby enemies
- **Toxic Explosion**: Poisoned enemies explode on death

**Tier 3 Branches:**
- Venomous → **One Shot Poison**: Lethal poison, kills any non-boss
- Plague → **Pandemic**: Poison spreads infinitely
- Toxic → **Bio Bomb**: Massive poison cloud on enemy death

---

#### 9. FROST ARROW (Base)
**Core**: Arrow slows enemy

**Tier 2 Branches:**
- **Freezing Shot**: Slow → full freeze
- **Ice Trail**: Arrow leaves slowing path
- **Shatter**: Frozen enemies take +crit damage

**Tier 3 Branches:**
- Freezing → **Absolute Zero**: Freeze entire screen
- Ice Trail → **Glacier Path**: Trail becomes ice wall
- Shatter → **Ice Explosion**: Frozen enemies shatter, damage nearby

---

#### 10. FIRE ARROW (Base)
**Core**: Arrow ignites enemy, burn DoT

**Tier 2 Branches:**
- **Napalm Shot**: Leaves fire pool on ground
- **Fire Spread**: Burns jump between enemies
- **Immolation**: Burns get stronger over time

**Tier 3 Branches:**
- Napalm → **Scorched Earth**: Permanent fire zones
- Fire Spread → **Wildfire**: Uncontrollable fire spread
- Immolation → **Phoenix Fire**: Burns heal you instead of damaging

---

#### 11. CHAIN LIGHTNING ARROW (Base)
**Core**: Arrow zaps to nearby enemies

**Tier 2 Branches:**
- **Overload**: More chains but self-damage
- **Static Field**: Chained enemies linked, share damage
- **Thunder Strike**: Chains call lightning from sky

**Tier 3 Branches:**
- Overload → **Unlimited Power**: Risk/reward, insane chain damage
- Static Field → **Capacitor**: Build charge, release mega-blast
- Thunder → **Storm Caller**: Permanent lightning storm follows you

---

#### 12. SNIPE (Base)
**Core**: Long charge, massive single target damage

**Tier 2 Branches:**
- **Head Shot**: Bonus crit damage
- **Penetrating Round**: Ignores armor
- **Marked for Death**: Missed shots mark enemy, next shot auto-hits

**Tier 3 Branches:**
- Head Shot → **Assassination**: One-shot any non-boss
- Penetrating → **Anti-Material**: Damages everything in line including terrain
- Marked → **Death Mark**: Marked enemies take damage when you damage others

---

#### 13. BARRAGE (Base)
**Core**: Rapid fire stream of arrows

**Tier 2 Branches:**
- **Suppressing Fire**: Enemies hit are slowed
- **Focused Stream**: Accuracy increases over time
- **Reload Burst**: Stop firing for big burst shot

**Tier 3 Branches:**
- Suppressing → **Bullet Storm**: Slow → stun → root progression
- Focused → **Laser Precision**: Become hitscan beam
- Reload → **Supercharged Shot**: Charged shot = mini-nuke

---

#### 14. DECOY (Base)
**Core**: Create decoy that draws enemy attention

**Tier 2 Branches:**
- **Exploding Decoy**: Explodes when destroyed
- **Mirror Image**: Decoy also attacks
- **Swap**: Teleport to decoy location

**Tier 3 Branches:**
- Exploding → **Suicide Squad**: Multiple decoys, chain explosions
- Mirror → **Army of Me**: Decoys persist, army of clones
- Swap → **Shadow Clone Jutsu**: Leave attacking clone at original spot

---

#### 15. GRAPPLING HOOK (Base)
**Core**: Fire hook, pull self to location

**Tier 2 Branches:**
- **Zipline**: Fast travel, can attack while moving
- **Hook Shot**: Pulls enemy to you instead
- **Swing**: Arc around point, gain momentum

**Tier 3 Branches:**
- Zipline → **Lightning Zip**: Damage all in path
- Hook → **Get Over Here**: Pulled enemy stunned, guaranteed crit
- Swing → **Wrecking Ball**: Momentum = massive impact damage

---

#### 16. MARK TARGET (Base)
**Core**: Mark enemy, take +damage, visible through walls

**Tier 2 Branches:**
- **Hunter's Prey**: Marked enemy drops better loot
- **Bounty Hunter**: Damage to marked enemy heals you
- **Execution Order**: Marked enemy = priority target for allies/summons

**Tier 3 Branches:**
- Hunter's → **Big Game Hunter**: Mark bosses for +drops
- Bounty → **Vampiric Hunt**: Full HP restore on marked kill
- Execution → **Extermination Protocol**: All your attacks/abilities hit marked

---

#### 17. SMOKE ARROW (Base)
**Core**: Creates smoke cloud, enemies inside can't see

**Tier 2 Branches:**
- **Toxic Cloud**: Smoke damages enemies
- **Invisibility Smoke**: You're invisible in smoke
- **Confusion Gas**: Enemies in smoke attack each other

**Tier 3 Branches:**
- Toxic → **Death Cloud**: Instant kill enemies that stay too long
- Invisibility → **Shadow Realm**: Create invisible zone, move undetected
- Confusion → **Mind Control Gas**: Enemies become allies temporarily

---

#### 18. NET ARROW (Base)
**Core**: Ensnare enemy, can't move

**Tier 2 Branches:**
- **Electric Net**: Netted enemies take shock damage
- **Barbed Net**: Netted enemies bleed
- **Constricting Net**: Net shrinks, crushing damage

**Tier 3 Branches:**
- Electric → **Tesla Cage**: Net zaps all nearby enemies
- Barbed → **Iron Maiden**: Movement = more damage
- Constricting → **Implosion**: Net crushes enemy to nothing

---

#### 19. BOOMERANG (Base)
**Core**: Thrown weapon returns, hits twice

**Tier 2 Branches:**
- **Seeking Boomerang**: Curves toward enemies
- **Multi-Boomerang**: Throw several at once
- **Glaive**: Bounces between enemies

**Tier 3 Branches:**
- Seeking → **Drone Boomerang**: Orbits you, auto-attacks
- Multi → **Boomerang Storm**: Constant stream of boomerangs
- Glaive → **Blade Dancer**: Each bounce spawns more blades

---

#### 20. VOLLEY (Base)
**Core**: Fire upward, arrows rain in target area

**Tier 2 Branches:**
- **Burning Volley**: Arrows are on fire
- **Icy Volley**: Arrows slow/freeze
- **Poison Volley**: Arrows create poison pools

**Tier 3 Branches:**
- Burning → **Meteor Shower**: Fireballs instead of arrows
- Icy → **Blizzard**: Sustained ice storm zone
- Poison → **Acid Rain**: Corrodes everything in zone

---

### GLOBAL ABILITIES (Class Agnostic) (15)

#### 1. FIREBALL
**Tier 2:** Bouncing Fireball, Exploding Fireball, Seeking Fireball
**Tier 3:** Meteor, Fire Stream, Phoenix Dive

#### 2. FROST NOVA
**Tier 2:** Ice Spikes, Frozen Ground, Chill Aura
**Tier 3:** Absolute Zero, Permafrost Zone, Ice Age

#### 3. CHAIN LIGHTNING
**Tier 2:** Ball Lightning, Lightning Field, Overcharge
**Tier 3:** Thunderstorm, Static Prison, Power Surge

#### 4. HEAL
**Tier 2:** Regen Aura, Emergency Heal, Lifesteal Burst
**Tier 3:** Full Restore, Resurrection, Vampiric Aura

#### 5. TELEPORT
**Tier 2:** Blink Strike, Phase Shift, Portal
**Tier 3:** Time Skip, Dimension Door, Omnipresence

#### 6. BLACK HOLE
**Tier 2:** Gravity Well, Void Rift, Singularity
**Tier 3:** Event Horizon, Dimensional Collapse, Void Consumption

#### 7. TIME MANIPULATION
**Tier 2:** Slow Field, Haste Self, Rewind
**Tier 3:** Time Stop, Temporal Clone, Age Regression

#### 8. SUMMON
**Tier 2:** Skeleton, Golem, Spirit
**Tier 3:** Army of Dead, Titan, Phantom Legion

#### 9. SHIELD
**Tier 2:** Energy Shield, Reflect Shield, Absorb Shield
**Tier 3:** Invulnerability, Mirror Barrier, Adaptive Armor

#### 10. CURSE
**Tier 2:** Weakness, Vulnerability, Doom
**Tier 3:** Death Mark, Soul Shatter, Eternal Torment

#### 11. AURA
**Tier 2:** Damage Aura, Speed Aura, Defense Aura
**Tier 3:** Overwhelming Presence, Champion's Call, Divine Domain

#### 12. EXPLOSION
**Tier 2:** Cluster Bomb, Sticky Bomb, Chain Explosion
**Tier 3:** Nuclear Option, Big Bang, Cascade Failure

#### 13. BEAM
**Tier 2:** Fire Beam, Ice Beam, Void Beam
**Tier 3:** Death Ray, Prismatic Laser, Annihilation

#### 14. THORNS
**Tier 2:** Spike Armor, Flame Retort, Shocking Touch
**Tier 3:** Pain Mirror, Vengeance Incarnate, Touch of Death

#### 15. BUFF TOTEM
**Tier 2:** Damage Totem, Healing Totem, Speed Totem
**Tier 3:** Totem of War, Totem of Life, Totem Forest

---

## PASSIVE ABILITIES - Branch System

### KEY PASSIVES WITH BRANCHES (like actives)

#### ORBITAL
**Base:** 1 orbital projectile
**Tier 2:** Blade Orbit (melee), Spell Orbit (fire/ice), Shield Orbit (blocks projectiles)
**Tier 3:** Orbital Array (8 orbitals), Orbital Nova (explode on command), Orbital Swarm (20 tiny orbitals)

#### VAMPIRISM
**Base:** 5% lifesteal
**Tier 2:** Blood Drain (AoE lifesteal), Feast (kill = full heal), Siphon (drain enemy max HP)
**Tier 3:** Vampiric Lord (lifesteal + spawn blood minions), Undying (revive with lifesteal buffer), Hemophilia (enemies bleed, you heal)

#### THORNS
**Base:** Return 20% damage
**Tier 2:** Flame Thorns (burn attackers), Ice Thorns (slow attackers), Lightning Thorns (chain to nearby)
**Tier 3:** Pain Mirror (200% return), Death Thorns (kill attacker chance), Thorn Aura (damages nearby passively)

#### SUMMONS
**Base:** 1 minion
**Tier 2:** Pack (3 minions), Elite (1 strong minion), Swarm (10 weak minions)
**Tier 3:** Legion (15 minions), Champion (1 boss-tier minion), Hive Mind (50 micro minions)

#### REGEN
**Base:** +1 HP/s
**Tier 2:** Combat Regen (more during combat), Emergency Regen (more when low HP), Regen Aura (share with allies)
**Tier 3:** Rapid Recovery (20 HP/s), Phoenix (revive from 0), Divine Blessing (can overheal to shield)

#### CRITICAL
**Base:** +10% crit chance
**Tier 2:** Critical Damage (2x → 3x), Critical Chain (crits chain), Critical Bleed (crits cause bleed)
**Tier 3:** Guaranteed Crit (100%), Devastating Blow (5x damage), Critical Cascade (crits trigger abilities)

### FLAT PASSIVES (No branches, stackable)
- +Damage %
- +Attack Speed %
- +Max HP
- +Movement Speed
- +Pickup Range
- +XP Gain
- +Luck
- +Projectile Count
- +Projectile Speed
- +Projectile Pierce
- +Armor
- +Cooldown Reduction

---

## Selection Pool Logic

### Upgrade Boost Algorithm
```
When generating 3 choices:
1. Roll for each slot (0-100)
2. If roll < 40 AND upgrades available:
   - Show random available upgrade
3. Else:
   - Show random passive/new ability
4. No duplicates in same selection
5. Weight by rarity (Common 40%, Rare 35%, Epic 17%, Legendary 8%)
```

### Upgrade Availability Rules
```
Tier 2 available when:
- Player has Tier 1 of that ability
- Player level >= 3

Tier 3 available when:
- Player has specific Tier 2 of that ability
- Player level >= 8
```

### Passive Branch Availability
```
Branch passives available when:
- Player has base passive
- Cooldown since base acquired (2 levels minimum)
```

---

## UI/UX Considerations

### Card Display
- Tier 1: Normal card border
- Tier 2: Silver border + "Upgrade" tag
- Tier 3: Gold border + "Signature" tag + special particle effect

### Branch Indicator
- Show which Tier 1 this upgrades from
- Arrow icon pointing from base ability icon

### Tooltip
- Show current ability stats
- Show new ability stats with green highlighting for improvements
- Show branch path: "Bash → Shockwave Bash → Earthquake Slam"

---

## Implementation Priority

### Phase 1: Core System
1. New ActiveAbilityData structure with tier/branch fields
2. Ability tree data structure
3. Updated selection pool logic

### Phase 2: Melee Abilities
1. Convert existing melee to Tier 1
2. Add Tier 2 branches
3. Add Tier 3 signatures

### Phase 3: Ranged Abilities
1. Convert existing ranged to Tier 1
2. Add Tier 2 branches
3. Add Tier 3 signatures

### Phase 4: Global & Passives
1. Convert globals
2. Add branching passives
3. Update passive selection

### Phase 5: Polish
1. UI/UX updates
2. Visual effects for tiers
3. Balance pass
