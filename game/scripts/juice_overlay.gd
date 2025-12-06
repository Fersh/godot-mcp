extends CanvasLayer

@onready var vignette: ColorRect = $Vignette
@onready var chromatic: ColorRect = $ChromaticAberration
@onready var damage_flash: ColorRect = $DamageFlash
@onready var low_hp_vignette: ColorRect = $LowHPVignette
@onready var desaturate: ColorRect = $Desaturate

func _ready() -> void:
	# Register with JuiceManager
	if JuiceManager:
		JuiceManager.register_vignette(vignette)
		JuiceManager.register_chromatic(chromatic)
		JuiceManager.register_damage_flash(damage_flash)
		JuiceManager.register_low_hp_vignette(low_hp_vignette)
		JuiceManager.register_desaturate(desaturate)
