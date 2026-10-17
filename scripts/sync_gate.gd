class_name SyncGate
extends Node

signal synchronized

@export var plate_a: PressurePlate
@export var plate_b: PressurePlate
@export var target_door: Door

@export_range(1.0, 10.0, 0.25, "suffix:s") var unlock_duration: float = 4.0

var activated: bool = false

func _ready() -> void:
    add_to_group("puzzle_sync_gates")

    assert(plate_a != null, "Missing plate A")
    assert(plate_b != null, "Missing plate B")
    assert(target_door != null, "Missing target door")

    plate_a.pressed_changed.connect(_on_plate_changed)
    plate_b.pressed_changed.connect(_on_plate_changed)

func activate() -> void:
    activated = true

    target_door.pulse_open(unlock_duration)
    synchronized.emit()

func reset_state() -> void:
    activated = false

func _on_plate_changed(_pressed: bool) -> void:
    if activated:
        return

    if plate_a.is_pressed and plate_b.is_pressed:
        activate()
