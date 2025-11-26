extends Node2D

var drone_index: int = 0
var target_offset: Vector2 = Vector2(-50, -50)
var follow_speed: float = 200.0
var fire_range: float = 300.0
var fire_cooldown: float = 1.2
var fire_timer: float = 0.0
var damage: float = 3.0

@onready var player: Node2D = null

func _ready() -> void:
	player = get_tree().get_first_node_in_group("player")

	# Offset based on index
	match drone_index % 4:
		0: target_offset = Vector2(-50, -50)
		1: target_offset = Vector2(50, -50)
		2: target_offset = Vector2(-50, 50)
		3: target_offset = Vector2(50, 50)

	if player:
		global_position = player.global_position + target_offset

func _process(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	# Follow player with offset
	var target_pos = player.global_position + target_offset
	global_position = global_position.move_toward(target_pos, follow_speed * delta)

	# Try to shoot
	fire_timer += delta
	if fire_timer >= fire_cooldown:
		try_fire()

	queue_redraw()

func try_fire() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var closest_dist: float = fire_range

	for enemy in enemies:
		if is_instance_valid(enemy):
			var dist = global_position.distance_to(enemy.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = enemy

	if closest:
		fire_timer = 0.0
		fire_at(closest)

func fire_at(target: Node2D) -> void:
	# Create a simple projectile line
	var line = Line2D.new()
	line.add_point(global_position)
	line.add_point(target.global_position)
	line.width = 2.0
	line.default_color = Color(1.0, 0.8, 0.3, 1.0)
	get_parent().add_child(line)

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage)

	# Fade out line
	var tween = create_tween()
	tween.tween_property(line, "modulate:a", 0.0, 0.15)
	tween.tween_callback(line.queue_free)

func _draw() -> void:
	# Draw drone as a small hovering square
	var rect = Rect2(-8, -8, 16, 16)
	draw_rect(rect, Color(0.5, 0.5, 0.6, 1.0))
	draw_rect(rect.grow(-2), Color(0.7, 0.7, 0.8, 1.0))

	# Propeller effect
	var time = Time.get_ticks_msec() / 50.0
	draw_line(Vector2(-10, -6), Vector2(-10 + sin(time) * 4, -10), Color(0.3, 0.3, 0.3, 0.5), 2.0)
	draw_line(Vector2(10, -6), Vector2(10 + sin(time + PI) * 4, -10), Color(0.3, 0.3, 0.3, 0.5), 2.0)
