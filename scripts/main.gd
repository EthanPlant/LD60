extends Node2D

@onready var pressure_plate: PressurePlate = $PressurePlate
@onready var door: Door = $Door
@onready var recorder: TapeRecorder = $Recorder
@onready var status_label: Label = $HUD/StatusLabel

func _ready() -> void:
    pressure_plate.pressed_changed.connect(door.set_open)

    door.set_open(pressure_plate.is_pressed)

func _process(_delta: float) -> void:
    status_label.text = recorder.get_status_text()

func _unhandled_input(event: InputEvent) -> void:
    if event.is_action_pressed("record"):
        recorder.handle_record()
        get_viewport().set_input_as_handled()

    if event.is_action_pressed("erase"):
        recorder.erase_tape()
        get_viewport().set_input_as_handled()
