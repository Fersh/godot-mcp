extends Node2D

# Simple hit spark particles that burst outward and fade quickly

var sparks: Array = []
const SPARK_COUNT := 6
const SPARK_SPEED_MIN := 150.0
const SPARK_SPEED_MAX := 300.0
const SPARK_LIFETIME := 0.15
const SPARK_SIZE := 3.0

class Spark:
	var pos: Vector2
	var vel: Vector2
	var lifetime: float
	var max_lifetime: float
	var color: Color

func _ready() -> void:
	z_index = 50  # Above enemies
	spawn_sparks()

func spawn_sparks() -> void:
	for i in range(SPARK_COUNT):
		var spark = Spark.new()
		spark.pos = Vector2.ZERO

		# Random direction burst
		var angle = randf() * TAU
		var speed = randf_range(SPARK_SPEED_MIN, SPARK_SPEED_MAX)
		spark.vel = Vector2(cos(angle), sin(angle)) * speed

		spark.lifetime = SPARK_LIFETIME
		spark.max_lifetime = SPARK_LIFETIME

		# White to yellow color
		spark.color = Color(1.0, randf_range(0.9, 1.0), randf_range(0.6, 0.9), 1.0)

		sparks.append(spark)

func _process(delta: float) -> void:
	var all_dead = true

	for spark in sparks:
		if spark.lifetime > 0:
			all_dead = false
			spark.lifetime -= delta
			spark.pos += spark.vel * delta
			# Slow down quickly
			spark.vel *= 0.9

	queue_redraw()

	if all_dead:
		queue_free()

func _draw() -> void:
	for spark in sparks:
		if spark.lifetime > 0:
			var alpha = spark.lifetime / spark.max_lifetime
			var color = spark.color
			color.a = alpha
			var size = SPARK_SIZE * alpha
			draw_circle(spark.pos, size, color)
