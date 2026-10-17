class_name  GhostReplay
extends Area2D

signal playback_finished

var frames: Array[Transform2D] = []
var frame_index: int = 0

func _ready() -> void:
    add_to_group("plate_activator")

func _physics_process(_delta: float) -> void:
    if frames.is_empty():
        return

    if frame_index >= frames.size():
        set_physics_process(false)
        playback_finished.emit()
        return

    global_transform = frames[frame_index]
    frame_index += 1

func load_recording(recorded_frames: Array[Transform2D]) -> void:
    frames = recorded_frames.duplicate()
    frame_index = 0

    if not frames.is_empty():
        global_transform = frames[0]
