extends Node2D

@onready var pressure_plate: PressurePlate = $PressurePlate
@onready var door: Door = $Door

func _ready() -> void:
    pressure_plate.pressed_changed.connect(door.set_open)

    door.set_open(pressure_plate.is_pressed)
