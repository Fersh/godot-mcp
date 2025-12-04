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
@onready var shadow: Polygon2D = $Shadow
@onready var rarity_label: Label = $RarityLabel
@onready var collision_shape: CollisionShape2D = $CollisionShape

# Fire effect
var fire_effect: ColorRect = null
var rarity_particle_shader: Shader = null

func _ready() -> void:
	base_y = global_position.y
	bob_time = randf() * TAU  # Random start phase
	add_to_group("dropped_items")

	# Setup collision - check if not already connected to prevent errors on re-parenting
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

func setup(data: ItemData) -> void:
	item_data = data
	var rarity_color = data.get_rarity_color()

	# Hide all polygon shapes - we'll show the actual item icon instead
	if glow_outer:
		glow_outer.visible = false
	if glow_inner:
		glow_inner.visible = false
	if item_base:
		item_base.visible = false
	if item_inner:
		item_inner.visible = false
	if shine:
		shine.visible = false
	if shadow:
		shadow.visible = false
	# Always show item name label above the item with rarity color
	if rarity_label:
		rarity_label.visible = true
		rarity_label.text = data.get_full_name()
		rarity_label.add_theme_color_override("font_color", rarity_color)
		rarity_label.add_theme_font_size_override("font_size", 10)
		# Add white border/outline to text
		rarity_label.add_theme_color_override("font_outline_color", Color.WHITE)
		rarity_label.add_theme_constant_override("outline_size", 3)
		# Put label above fire effect
		rarity_label.z_index = 10
		# Load pixel font
		if ResourceLoader.exists("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf"):
			var pixel_font = load("res://assets/fonts/Press_Start_2P/PressStart2P-Regular.ttf")
			rarity_label.add_theme_font_override("font", pixel_font)

	# Create fire effect based on rarity
	_create_fire_effect(data.rarity, rarity_color)

	# Load icon if available
	if data.icon_path != "" and ResourceLoader.exists(data.icon_path):
		var texture = load(data.icon_path)
		if texture and sprite:
			sprite.texture = texture
			sprite.scale = Vector2(0.7, 0.7)  # 35% of original size
			sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
			sprite.visible = true
	else:
		# Fallback to polygon shapes if no icon
		if sprite:
			sprite.visible = false
		if shadow:
			shadow.visible = true
		if glow_outer:
			glow_outer.visible = true
			glow_outer.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.3)
		if glow_inner:
			glow_inner.visible = true
			glow_inner.color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.5)
		if item_base:
			item_base.visible = true
			item_base.color = Color(rarity_color.r * 0.5, rarity_color.g * 0.5, rarity_color.b * 0.5, 1.0)
		if item_inner:
			item_inner.visible = true
			item_inner.color = Color(rarity_color.r * 0.8, rarity_color.g * 0.8, rarity_color.b * 0.8, 1.0)
		if shine:
			shine.visible = true
			shine.color = Color(
				0.7 + rarity_color.r * 0.3,
				0.7 + rarity_color.g * 0.3,
				0.7 + rarity_color.b * 0.3,
				0.7
			)

func _process(delta: float) -> void:
	# No bobbing - items stay on the floor

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

func _create_fire_effect(rarity: ItemData.Rarity, rarity_color: Color) -> void:
	"""Create fire particle effect based on item rarity."""
	# Load shader if not already loaded
	if rarity_particle_shader == null:
		if ResourceLoader.exists("res://shaders/rarity_particles.gdshader"):
			rarity_particle_shader = load("res://shaders/rarity_particles.gdshader")

	if rarity_particle_shader == null:
		return

	# Determine fire color and intensity based on rarity
	var fire_color: Color
	var intensity: float
	var density: float

	match rarity:
		ItemData.Rarity.COMMON:
			fire_color = Color(1.0, 1.0, 1.0, 0.6)  # White fire
			intensity = 0.4
			density = 6.0
		ItemData.Rarity.RARE:
			fire_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.7)
			intensity = 0.7
			density = 10.0
		ItemData.Rarity.EPIC:
			fire_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.8)
			intensity = 1.0
			density = 14.0
		ItemData.Rarity.LEGENDARY:
			fire_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 0.9)
			intensity = 1.4
			density = 18.0
		ItemData.Rarity.MYTHIC:
			fire_color = Color(rarity_color.r, rarity_color.g, rarity_color.b, 1.0)
			intensity = 2.0
			density = 24.0
		_:
			fire_color = Color(1.0, 1.0, 1.0, 0.5)
			intensity = 0.3
			density = 5.0

	# Create fire effect ColorRect
	fire_effect = ColorRect.new()
	fire_effect.size = Vector2(50, 60)
	fire_effect.position = Vector2(-25, -50)  # Center below label, above item
	fire_effect.z_index = -1  # Behind everything but visible
	fire_effect.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Apply shader
	var mat = ShaderMaterial.new()
	mat.shader = rarity_particle_shader
	mat.set_shader_parameter("rarity_color", fire_color)
	mat.set_shader_parameter("intensity", intensity)
	mat.set_shader_parameter("speed", 1.2)
	mat.set_shader_parameter("particle_density", density)
	mat.set_shader_parameter("pixel_size", 0.08)
	fire_effect.material = mat

	add_child(fire_effect)
