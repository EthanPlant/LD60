class_name ElectricalBarrier
extends Area2D

signal player_hit

const ACTIVE_COLOUR := Color("#79DFFF")
const INACTIVE_COLOUR := Color("#526A75", 0.25)

@export var disabling_plate: PressurePlate

@onready var visual: Polygon2D = $Visual

var energized: bool = true
var hit_latched: bool = false

func _ready() -> void:
    add_to_group("puzzle_barriers")

    process_physics_priority = 20

    if disabling_plate != null:
        disabling_plate.pressed_changed.connect(_on_plate_changed)

        _on_plate_changed(disabling_plate.is_pressed)

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
    visual.color = ACTIVE_COLOUR if energized else INACTIVE_COLOUR

func reset_state() -> void:
    hit_latched = false
    energized = true
    update_visual()

func _on_plate_changed(pressed: bool) -> void:
    energized = not pressed
    update_visual()
