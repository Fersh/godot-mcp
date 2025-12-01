extends Node2D

# Blood splatter particles with gravity - gorier version

var particles: Array = []
var blood_pools: Array = []  # Blood that stays on ground
var is_crit_kill: bool = false  # Extra gore for crit kills
var is_ability_kill: bool = false  # From active abilities
var flying_head: Node2D = null  # The flying head sprite
var head_velocity: Vector2 = Vector2.ZERO
var head_rotation_speed: float = 0.0
var enemy_sprite_texture: Texture2D = null  # Store the enemy's texture for head clipping
var enemy_sprite_frame: int = 0
var enemy_frame_size: Vector2 = Vector2(96, 96)  # Default frame size

class BloodParticle:
	var pos: Vector2
	var vel: Vector2
	var size: float
	var color: Color
	var lifetime: float
	var max_lifetime: float
	var on_ground: bool = false
	var ground_y: float

class BloodPool:
	var pos: Vector2
	var size: float
	var color: Color
	var lifetime: float

func set_crit_kill(is_crit: bool) -> void:
	is_crit_kill = is_crit
	if is_crit:
		# Add extra particles for crit kill
		spawn_crit_particles()

func set_ability_kill(enemy_texture: Texture2D, frame: int, frame_size: Vector2) -> void:
	"""Called when enemy is killed by an active ability - chance for flying head."""
	is_ability_kill = true
	enemy_sprite_texture = enemy_texture
	enemy_sprite_frame = frame
	enemy_frame_size = frame_size

	# 35% chance for flying head on ability kills
	if randf() < 0.35 and enemy_sprite_texture != null:
		spawn_flying_head()
		spawn_ability_kill_blood()
		# Trigger slowmo for dramatic effect
		if JuiceManager:
			JuiceManager.hitstop_medium()
			Engine.time_scale = 0.4
			get_tree().create_timer(0.15).timeout.connect(func():
				Engine.time_scale = 1.0
			)

func spawn_flying_head() -> void:
	"""Spawn a clipped head region that flies off with rotation."""
	if enemy_sprite_texture == null:
		return

	flying_head = Node2D.new()
	flying_head.name = "FlyingHead"
	add_child(flying_head)

	# Create sprite for the head (top 30% of the frame)
	var head_sprite = Sprite2D.new()
	head_sprite.texture = enemy_sprite_texture
	head_sprite.centered = true

	# Calculate which part of the spritesheet to show (just the head)
	var cols = int(enemy_sprite_texture.get_width() / enemy_frame_size.x)
	var frame_x = (enemy_sprite_frame % cols) * int(enemy_frame_size.x)
	var frame_y = (enemy_sprite_frame / cols) * int(enemy_frame_size.y)

	# Clip to top 35% of frame (the head area)
	var head_height = enemy_frame_size.y * 0.35
	head_sprite.region_enabled = true
	head_sprite.region_rect = Rect2(frame_x, frame_y, enemy_frame_size.x, head_height)
	head_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST

	flying_head.add_child(head_sprite)

	# Position slightly above death position
	flying_head.position = Vector2(0, -enemy_frame_size.y * 0.3)

	# Random trajectory - mostly upward and sideways
	head_velocity = Vector2(randf_range(-300, 300), randf_range(-450, -250))
	head_rotation_speed = randf_range(-15, 15)  # Radians per second

	# Add blood trail particles attached to head
	spawn_head_blood_trail()

func spawn_head_blood_trail() -> void:
	"""Spawn extra blood particles that follow the flying head trajectory."""
	for i in randi_range(15, 25):
		var p = BloodParticle.new()
		p.pos = flying_head.position
		# Blood sprays from neck area
		p.vel = Vector2(randf_range(-150, 150), randf_range(-200, 50))
		p.size = float(randi_range(3, 7))
		var blood_base = Color(0.9, 0.1, 0.1, 1.0)
		var blood_dark = Color(0.6, 0.03, 0.03, 1.0)
		p.color = blood_base.lerp(blood_dark, randf())
		p.max_lifetime = randf_range(10.0, 18.0)
		p.lifetime = p.max_lifetime
		p.ground_y = float(randi_range(20, 60))
		particles.append(p)

func spawn_ability_kill_blood() -> void:
	"""Extra blood for ability kills - more than regular, less than crit."""
	var extra_count = randi_range(25, 40)
	for i in extra_count:
		var p = BloodParticle.new()
		p.pos = Vector2(randf_range(-10, 10), randf_range(-20, 0))
		# Explosive upward spray
		p.vel = Vector2(randf_range(-400, 400), randf_range(-500, -150))
		p.size = float(randi_range(3, 9))
		# Bright arterial red
		var blood_base = Color(0.95, 0.12, 0.12, 1.0)
		var blood_dark = Color(0.55, 0.04, 0.04, 1.0)
		p.color = blood_base.lerp(blood_dark, randf())
		p.max_lifetime = randf_range(10.0, 20.0)
		p.lifetime = p.max_lifetime
		p.ground_y = float(randi_range(15, 55))
		particles.append(p)

	# Extra blood pools
	for i in randi_range(8, 15):
		var pool = BloodPool.new()
		pool.pos = Vector2(randf_range(-40, 40), randf_range(-15, 35))
		pool.size = float(randi_range(8, 18))
		pool.color = Color(0.6, 0.04, 0.04, 0.95)
		pool.lifetime = randf_range(18.0, 28.0)
		blood_pools.append(pool)

func _ready() -> void:
	z_index = -5  # Render above background (-10) but below characters (0)
	spawn_particles()

func spawn_crit_particles() -> void:
	# Extra explosive particles for crit kills
	var extra_count = randi_range(20, 35)
	for i in extra_count:
		var p = BloodParticle.new()
		p.pos = Vector2.ZERO
		# Much more explosive spread for crits
		p.vel = Vector2(randf_range(-350, 350), randf_range(-400, -100))
		# Bigger chunks
		p.size = float(randi_range(3, 8))
		# Brighter red for fresh blood
		var blood_base = Color(0.85, 0.08, 0.08, 1.0)
		var blood_dark = Color(0.5, 0.03, 0.03, 1.0)
		p.color = blood_base.lerp(blood_dark, randf())
		p.max_lifetime = randf_range(8.0, 16.0)
		p.lifetime = p.max_lifetime
		p.ground_y = float(randi_range(10, 45))
		particles.append(p)

	# Extra blood pools for crit
	for i in randi_range(5, 10):
		var pool = BloodPool.new()
		pool.pos = Vector2(randf_range(-30, 30), randf_range(-10, 25))
		pool.size = float(randi_range(6, 14))
		pool.color = Color(0.55, 0.03, 0.03, 0.95)
		pool.lifetime = randf_range(16.0, 24.0)
		blood_pools.append(pool)

func spawn_particles() -> void:
	# More particles for gorier effect
	var count = randi_range(15, 25)
	for i in count:
		var p = BloodParticle.new()
		p.pos = Vector2.ZERO
		# More explosive spread
		p.vel = Vector2(randf_range(-200, 200), randf_range(-250, -60))
		# Varied sizes - some bigger chunks
		p.size = float(randi_range(2, 6))
		# Darker, more saturated blood colors
		var blood_base = Color(0.7, 0.05, 0.05, 1.0)
		var blood_dark = Color(0.4, 0.02, 0.02, 1.0)
		p.color = blood_base.lerp(blood_dark, randf())
		p.max_lifetime = randf_range(6.0, 12.0)  # Longer lifetime
		p.lifetime = p.max_lifetime
		p.ground_y = float(randi_range(6, 30))
		particles.append(p)

	# Add some initial blood splatter at origin
	for i in randi_range(3, 6):
		var pool = BloodPool.new()
		pool.pos = Vector2(randf_range(-15, 15), randf_range(-5, 15))
		pool.size = float(randi_range(4, 10))
		pool.color = Color(0.5, 0.02, 0.02, 0.9)
		pool.lifetime = randf_range(12.0, 20.0)  # Stays for a few seconds
		blood_pools.append(pool)

func _process(delta: float) -> void:
	# Update flying particles
	for p in particles:
		p.lifetime -= delta

		if not p.on_ground:
			# Apply gravity
			p.vel.y += 700 * delta
			# Apply friction
			p.vel.x *= 0.97
			# Move
			p.pos += p.vel * delta

			# Check if hit ground
			if p.pos.y >= p.ground_y:
				p.pos.y = p.ground_y
				p.on_ground = true
				p.vel = Vector2.ZERO

				# Create blood pool where particle lands
				if randf() < 0.6:  # 60% chance to leave a mark
					var pool = BloodPool.new()
					pool.pos = p.pos
					pool.size = p.size * randf_range(1.2, 2.0)
					pool.color = Color(0.45, 0.02, 0.02, 0.85)
					pool.lifetime = randf_range(10.0, 18.0)
					blood_pools.append(pool)
		else:
			# Fade out on ground faster
			if p.lifetime < 0.5:
				p.color.a = p.lifetime / 0.5

	# Update blood pools (slower fade)
	for pool in blood_pools:
		pool.lifetime -= delta
		if pool.lifetime < 1.0:
			pool.color.a = pool.lifetime * 0.85

	# Remove faded pools
	blood_pools = blood_pools.filter(func(pool): return pool.lifetime > 0)

	# Update flying head physics
	if flying_head != null and is_instance_valid(flying_head):
		# Apply gravity
		head_velocity.y += 600 * delta
		# Apply friction
		head_velocity.x *= 0.98
		# Move
		flying_head.position += head_velocity * delta
		# Rotate
		flying_head.rotation += head_rotation_speed * delta

		# Spawn blood trail while flying upward
		if head_velocity.y < 100 and randf() < 0.4:
			var p = BloodParticle.new()
			p.pos = flying_head.position
			p.vel = Vector2(randf_range(-80, 80), randf_range(-50, 100))
			p.size = float(randi_range(2, 5))
			p.color = Color(0.85, 0.08, 0.08, 1.0)
			p.max_lifetime = randf_range(5.0, 10.0)
			p.lifetime = p.max_lifetime
			p.ground_y = flying_head.position.y + randf_range(40, 100)
			particles.append(p)

		# Remove head when it falls below screen
		if flying_head.position.y > 200:
			flying_head.queue_free()
			flying_head = null

	queue_redraw()

	# Remove when all particles faded AND all pools gone AND head is gone
	var all_particles_done = particles.is_empty() or particles.all(func(p): return p.lifetime <= 0)
	var head_done = flying_head == null or not is_instance_valid(flying_head)
	if all_particles_done and blood_pools.is_empty() and head_done:
		queue_free()

func _draw() -> void:
	# Draw blood pools first (underneath)
	for pool in blood_pools:
		if pool.lifetime > 0:
			var pixel_pos = Vector2(round(pool.pos.x), round(pool.pos.y))
			# Draw as slightly irregular shape (multiple overlapping rects)
			var base_size = pool.size
			draw_rect(Rect2(pixel_pos - Vector2(base_size / 2, base_size / 3), Vector2(base_size, base_size * 0.6)), pool.color)
			draw_rect(Rect2(pixel_pos - Vector2(base_size / 3, base_size / 2), Vector2(base_size * 0.7, base_size * 0.8)), pool.color)

	# Draw flying/landed particles on top
	for p in particles:
		if p.lifetime > 0:
			var pixel_pos = Vector2(round(p.pos.x), round(p.pos.y))
			var rect = Rect2(pixel_pos - Vector2(p.size / 2, p.size / 2), Vector2(p.size, p.size))
			draw_rect(rect, p.color)
