class_name BossBase
extends EliteBase

# Boss Base - Extends EliteBase for boss enemies
# Features: Enrage mechanic, taunt on spawn, health bar signal, red aura

signal boss_spawned(boss: Node)
signal boss_health_changed(current: float, max_hp: float)
signal boss_died(boss: Node)
signal boss_enraged(boss: Node)

@export var boss_name: String = "BOSS"
@export var display_name: String = "BULLSH*T"  # Name shown on health bar

# Enrage settings
@export var enrage_threshold: float = 0.20  # 20% HP
@export var enrage_damage_bonus: float = 0.25  # +25% damage
@export var enrage_size_bonus: float = 0.10  # +10% size

# Taunt settings
@export var taunt_on_spawn: bool = true
@export var taunt_count: int = 2  # Play taunt twice
@export var taunt_speed_multiplier: float = 1.5  # Faster taunt

# Boss state
var is_enraged: bool = false
var is_taunting: bool = false
var taunt_plays_remaining: int = 0
var base_scale: Vector2 = Vector2.ONE
var base_damage: float = 0.0

# Aura effect
var aura_particles: GPUParticles2D = null
var aura_timer: float = 0.0

# Animation rows (override in subclass)
var ROW_TAUNT: int = 2
var FRAMES_TAUNT: int = 5

func _on_ready() -> void:
	enemy_rarity = "boss"
	base_scale = scale
	base_damage = attack_damage
	_setup_boss()
	_setup_aura()
	_init_attack_cooldowns()

	# Start with taunt if enabled
	if taunt_on_spawn:
		_start_spawn_taunt()

	# Emit spawn signal for health bar
	emit_signal("boss_spawned", self)

	# Start boss music
	if SoundManager:
		SoundManager.play_boss_music(self)

# Override in subclasses
func _setup_boss() -> void:
	pass

func _setup_aura() -> void:
	# Create red pulsing aura using a simple visual approach
	# We'll use modulate pulsing + outline shader if available
	pass

func _start_spawn_taunt() -> void:
	is_taunting = true
	taunt_plays_remaining = taunt_count
	animation_frame = 0.0
	current_row = ROW_TAUNT
	can_attack = false
	velocity = Vector2.ZERO

func _physics_process(delta: float) -> void:
	# Update aura pulse
	_update_aura(delta)

	# Handle taunt animation
	if is_taunting:
		_process_taunt(delta)
		return

	# Check for enrage (use difficulty modifier threshold if available)
	var actual_enrage_threshold = DifficultyManager.get_enrage_threshold() if DifficultyManager else enrage_threshold
	if not is_enraged and current_health <= max_health * actual_enrage_threshold:
		_trigger_enrage()

	super._physics_process(delta)

func _process_taunt(delta: float) -> void:
	animation_frame += animation_speed * taunt_speed_multiplier * delta
	var max_frames = FRAMES_TAUNT

	if animation_frame >= max_frames:
		animation_frame = 0.0
		taunt_plays_remaining -= 1

		if taunt_plays_remaining <= 0:
			is_taunting = false
			can_attack = true
			return

	sprite.frame = ROW_TAUNT * COLS_PER_ROW + int(animation_frame)

func _update_aura(delta: float) -> void:
	aura_timer += delta

	# Pulsing red modulate effect
	var pulse = 0.15 + sin(aura_timer * 4.0) * 0.1
	var base_color = Color(1.0, 1.0, 1.0, 1.0)

	if sprite == null or not is_instance_valid(sprite):
		return

	if is_enraged:
		# More intense red when enraged
		pulse = 0.25 + sin(aura_timer * 6.0) * 0.15
		sprite.modulate = base_color.lerp(Color(1.5, 0.5, 0.5, 1.0), pulse)
	else:
		sprite.modulate = base_color.lerp(Color(1.3, 0.7, 0.7, 1.0), pulse)

func _trigger_enrage() -> void:
	is_enraged = true

	# Quick taunt animation
	is_taunting = true
	taunt_plays_remaining = 1
	animation_frame = 0.0
	current_row = ROW_TAUNT

	# Apply enrage bonuses
	attack_damage = base_damage * (1.0 + enrage_damage_bonus)
	scale = base_scale * (1.0 + enrage_size_bonus)

	# Screen shake
	if JuiceManager:
		JuiceManager.shake_large()

	emit_signal("boss_enraged", self)

func take_damage(amount: float, is_crit: bool = false) -> void:
	super.take_damage(amount, is_crit)
	emit_signal("boss_health_changed", current_health, max_health)

func die() -> void:
	emit_signal("boss_died", self)
	emit_signal("boss_health_changed", 0, max_health)

	# End boss music
	if SoundManager:
		SoundManager.on_boss_died()

	super.die()

# Override for boss-specific rewards
func spawn_gold_coin() -> void:
	if gold_coin_scene == null:
		return

	# Apply Cursed Gold curse (reduced gold drops)
	var drop_mult = 1.0
	if CurseEffects:
		drop_mult = CurseEffects.get_gold_drop_multiplier()

	# Bosses drop lots of coins (scaled by curse)
	var coin_count = int(coin_multiplier * 2 * drop_mult)
	for i in range(max(3, coin_count)):  # At least 3 coins from bosses
		var coin = gold_coin_scene.instantiate()
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		coin.global_position = global_position + offset
		get_parent().add_child(coin)

	# Guaranteed high-quality item drop
	if guaranteed_drop:
		_drop_boss_item()

func _drop_boss_item() -> void:
	if dropped_item_scene == null:
		return

	if EquipmentManager == null:
		return

	# Generate item with boss rarity bonus
	var item = EquipmentManager.generate_item("boss")
	var dropped = dropped_item_scene.instantiate()
	dropped.global_position = global_position
	dropped.setup(item)
	get_parent().add_child(dropped)
