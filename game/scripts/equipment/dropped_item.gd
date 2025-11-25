extends Area2D
class_name DroppedItem

signal player_near(item: DroppedItem)
signal player_left(item: DroppedItem)

@export var pickup_range: float = 80.0
@export var bob_speed: float = 2.0
@export var bob_height: float = 8.0
@export var glow_pulse_speed: float = 3.0

var item_data: ItemData = null
var player: Node2D = null
var is_player_near: bool = false
var base_y: float = 0.0
var bob_time: float = 0.0
var glow_time: float = 0.0

@onready var sprite: Sprite2D = $Sprite
@onready var glow_outer: Polygon2D = $GlowOuter
@onready var glow_inner: Polygon2D = $GlowInner
@onready var item_base: Polygon2D = $ItemBase
@onready var item_inner: Polygon2D = $ItemInner
@onready var shine: Polygon2D = $Shine
@onready var rarity_label: Label = $RarityLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape

func _ready() -> void:
	base_y = global_position.y
	bob_time = randf() * TAU  # Random start phase
	add_to_group("dropped_items")

	# Setup collision
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func setup(data: ItemData) -> void:
	item_data = data
	var rarity_color = data.get_rarity_color()

	# Load icon if available
	if data.icon_path != "" and ResourceLoader.exists(data.icon_path):
		var texture = load(data.icon_path)
		if texture and sprite:
			sprite.texture = texture
			sprite.scale = Vector2(1.5, 1.5)
	else:
		# Hide sprite if no icon
		if sprite:
			sprite.visible = false

	# Color the item based on rarity
	if glow_outer:
		glow_outer.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)
	if glow_inner:
		glow_inner.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.5)
	if item_base:
		# Darker version of rarity color
		item_base.color = Color(rarity_color.r * 0.5, rarity_color.g * 0.5, rarity_color.b * 0.5, 1.0)
	if item_inner:
		# Lighter version of rarity color
		item_inner.color = Color(rarity_color.r * 0.8, rarity_color.g * 0.8, rarity_color.b * 0.8, 1.0)
	if shine:
		# White shine with slight rarity tint
		shine.color = Color(
			0.7 + rarity_color.r * 0.3,
			0.7 + rarity_color.g * 0.3,
			0.7 + rarity_color.b * 0.3,
			0.7
		)

	# Set rarity label
	if rarity_label:
		rarity_label.text = data.get_rarity_name()
		rarity_label.add_theme_color_override("font_color", rarity_color)
		rarity_label.add_theme_font_size_override("font_size", 12)

func _process(delta: float) -> void:
	# Bobbing animation
	bob_time += delta * bob_speed
	global_position.y = base_y + sin(bob_time) * bob_height

	# Glow pulsing
	glow_time += delta * glow_pulse_speed
	var pulse = (sin(glow_time) + 1.0) / 2.0  # 0 to 1
	if glow_outer:
		glow_outer.color.a = 0.2 + pulse * 0.3
	if glow_inner:
		glow_inner.color.a = 0.3 + pulse * 0.4

	# Check distance to player
	if player == null:
		player = get_tree().get_first_node_in_group("player")

	if player and is_instance_valid(player):
		var distance = global_position.distance_to(player.global_position)
		var was_near = is_player_near
		is_player_near = distance <= pickup_range

		if is_player_near and not was_near:
			emit_signal("player_near", self)
		elif not is_player_near and was_near:
			emit_signal("player_left", self)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player = body

func _on_body_exited(body: Node2D) -> void:
	pass

func get_item_data() -> ItemData:
	return item_data

func pickup() -> void:
	if item_data:
		EquipmentManager.add_pending_item(item_data)
	queue_free()

func get_display_info() -> Dictionary:
	if item_data == null:
		return {}

	return {
		"name": item_data.get_full_name(),
		"rarity": item_data.get_rarity_name(),
		"rarity_color": item_data.get_rarity_color(),
		"slot": item_data.get_slot_name(),
		"stats": item_data.get_stat_description(),
		"description": item_data.description,
		"icon_path": item_data.icon_path
	}
