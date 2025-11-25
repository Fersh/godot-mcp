extends Node2D

# Blood splatter particles with gravity

var particles: Array = []

class BloodParticle:
	var pos: Vector2
	var vel: Vector2
	var size: float
	var color: Color
	var lifetime: float
	var max_lifetime: float
	var on_ground: bool = false
	var ground_y: float

func _ready() -> void:
	spawn_particles()

func spawn_particles() -> void:
	var count = randi_range(8, 15)
	for i in count:
		var p = BloodParticle.new()
		p.pos = Vector2.ZERO
		p.vel = Vector2(randf_range(-150, 150), randf_range(-200, -50))
		p.size = randf_range(2, 5)
		p.color = Color(0.8, 0.1, 0.1, 1.0).lerp(Color(0.5, 0.05, 0.05, 1.0), randf())
		p.max_lifetime = randf_range(0.8, 1.5)
		p.lifetime = p.max_lifetime
		p.ground_y = randf_range(10, 30)  # Random ground level relative to spawn
		particles.append(p)

func _process(delta: float) -> void:
	var all_settled = true

	for p in particles:
		p.lifetime -= delta

		if not p.on_ground:
			all_settled = false
			# Apply gravity
			p.vel.y += 600 * delta
			# Apply friction
			p.vel.x *= 0.98
			# Move
			p.pos += p.vel * delta

			# Check if hit ground
			if p.pos.y >= p.ground_y:
				p.pos.y = p.ground_y
				p.on_ground = true
				p.vel = Vector2.ZERO
		else:
			# Fade out on ground
			if p.lifetime < 0.3:
				p.color.a = p.lifetime / 0.3

	queue_redraw()

	# Remove when all particles faded
	if particles.size() > 0 and particles[0].lifetime <= 0:
		queue_free()

func _draw() -> void:
	for p in particles:
		if p.lifetime > 0:
			draw_circle(p.pos, p.size, p.color)
