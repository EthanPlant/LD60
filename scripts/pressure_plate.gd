class_name PressurePlate
extends Area2D

signal pressed_changed(pressed: bool)

@onready var visual: Polygon2D = $Visual

var is_pressed: bool = false
var activators: Array[Node2D] = []
var flash: float = 0.0

func _ready() -> void:
	add_to_group("puzzle_plates")
	
	body_entered.connect(_on_activator_entered)
	body_exited.connect(_on_activator_exited)

	area_entered.connect(_on_activator_entered)
	area_exited.connect(_on_activator_exited)

	update_visual()

func _process(delta: float) -> void:
	if flash <= 0.0:
		return

	flash = move_toward(flash, 0.0, delta * 4.0)
	visual.set_instance_shader_parameter("press_flash", flash)

func _on_activator_entered(actor: Node2D) -> void:
	if not actor.is_in_group("plate_activator"):
		return
	
	if not activators.has(actor):
		activators.append(actor)

	update_pressed_state()

func _on_activator_exited(actor: Node2D) -> void:
	if not actor.is_in_group("plate_activator"):
		return

	activators.erase(actor)
	update_pressed_state()

func update_pressed_state() -> void:
	var new_state: bool = not activators.is_empty()

	if new_state == is_pressed:
		return

	is_pressed = new_state
	flash = 1.0
	update_visual()
	pressed_changed.emit(is_pressed)

func update_visual() -> void:
	visual.set_instance_shader_parameter("activated", 1.0 if is_pressed else 0.0)
	visual.set_instance_shader_parameter("press_flash", flash)

func forget_activator(actor: Node2D) -> void:
	activators.erase(actor)
	update_pressed_state()

func reset_state() -> void:
	activators.clear()
	update_pressed_state() 
