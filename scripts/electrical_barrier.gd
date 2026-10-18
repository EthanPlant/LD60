class_name ElectricalBarrier
extends Area2D

signal player_hit

@export var disabling_plate: PressurePlate

@onready var visual: Polygon2D = $Visual
@onready var top_cap: Polygon2D = $TopCap
@onready var bottom_cap: Polygon2D = $BottomCap

var energized: bool = true
var hit_latched: bool = false

func _ready() -> void:
	add_to_group("puzzle_barriers")

	process_physics_priority = 20

	if disabling_plate != null:
		disabling_plate.pressed_changed.connect(_on_plate_changed)

		_on_plate_changed(disabling_plate.is_pressed)

	top_cap.set_instance_shader_parameter("flip_y", 0.0)
	bottom_cap.set_instance_shader_parameter("flip_y", 1.0)

	update_visual()

func _physics_process(_delta: float) -> void:
	if not energized or hit_latched:
		return

	for body in get_overlapping_bodies():
		if body is PlayerController:
			hit_latched = true
			player_hit.emit()
			return

func update_visual() -> void:
	visual.set_instance_shader_parameter("powered", 1.0 if energized else 0.0)
	top_cap.set_instance_shader_parameter("powered", 1.0 if energized else 0.0)
	bottom_cap.set_instance_shader_parameter("powered", 1.0 if energized else 0.0)

func reset_state() -> void:
	hit_latched = false
	energized = true
	update_visual()

func _on_plate_changed(pressed: bool) -> void:
	energized = not pressed
	update_visual()
