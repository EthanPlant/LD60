class_name VHSOverlay
extends CanvasLayer

@onready var shader_material: ShaderMaterial = $VHS.material as ShaderMaterial

var rewind_flash: float = 0.0
var wear_level: float = 0.0

func _process(delta: float) -> void:
	rewind_flash = move_toward(rewind_flash, 0.0, delta * 3.0)

	var erased_rewind: float = rewind_flash * rewind_flash

	shader_material.set_shader_parameter("rewind_amount", erased_rewind)

	shader_material.set_shader_parameter("wear", wear_level)

func trigger_rewind() -> void:
	rewind_flash = 1.0

func set_wear(value: float) -> void:
	wear_level = clampf(value, 0.0, 1.0)

func reset_effect() -> void:
	rewind_flash = 0.0
	wear_level = 0.0
	
