extends CanvasLayer

@onready var vignette: ColorRect = $Vignette
@onready var chromatic: ColorRect = $ChromaticAberration

func _ready() -> void:
	# Register with JuiceManager
	if JuiceManager:
		JuiceManager.register_vignette(vignette)
		JuiceManager.register_chromatic(chromatic)
