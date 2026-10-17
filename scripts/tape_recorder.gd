class_name TapeRecorder
extends Node

signal reset_requested
signal ghost_removed(actor: Node2D)

enum State {
    READY,
    RECORDING,
    REWINDING,
    PLAYING
}

const MAX_SECONDS: float = 8.0
const REWIND_SECONDS: float = 0.3

const GHOST_SCENE: PackedScene = preload("res://scenes/ghost.tscn")

@onready var player: PlayerController = $"../Player"
@onready var ghost_container: Node2D = $"../GhostContainer"

var state: State = State.READY

var tape: Array[Transform2D] = []
var ghost: GhostReplay = null

var rewind_remaining: float = 0.0

func _ready() -> void:
    process_physics_priority = 10 # Sample the player AFTER its physics movement

func _physics_process(delta: float) -> void:
    match state:
        State.RECORDING:
            capture_frame()
        
        State.REWINDING:
            rewind_remaining -= delta

            if rewind_remaining <= 0.0:
                complete_rewind()

func handle_record() -> void:
    match state:
        State.READY:
            start_recording()
        
        State.RECORDING:
            start_rewind()

        State.PLAYING:
            start_rewind()

        State.REWINDING:
            pass

func start_recording() -> void:
    remove_ghost()

    tape.clear()
    state = State.RECORDING

func capture_frame() -> void:
    tape.append(player.global_transform)

    var max_frames: int = int(MAX_SECONDS * Engine.physics_ticks_per_second)

    if tape.size() >= max_frames:
        start_rewind()

func start_rewind() -> void:
    if tape.is_empty():
        tape.append(player.global_transform)

    remove_ghost()

    state = State.REWINDING
    rewind_remaining = REWIND_SECONDS

    player.set_movement_enabled(false)

func complete_rewind() -> void:
    reset_requested.emit()

    ghost = GHOST_SCENE.instantiate() as GhostReplay
    ghost_container.add_child(ghost)

    ghost.load_recording(tape)
    ghost.playback_finished.connect(_on_ghost_playback_finished)

    state = State.PLAYING
    player.set_movement_enabled(true)

func erase_tape() -> void:
    if state == State.REWINDING:
        return

    remove_ghost()
    tape.clear()

    reset_requested.emit()

    state = State.READY
    player.set_movement_enabled(true)

func restart_attempt() -> void:
    if state == State.REWINDING:
        return

    if state == State.PLAYING and not tape.is_empty():
        start_rewind()
    else:
        erase_tape()

func remove_ghost() -> void:
    if is_instance_valid(ghost):

        ghost_removed.emit(ghost)
        ghost.queue_free()

    ghost = null

func get_status_text() -> String:
    match state:
        State.READY:
            return "READY | R: Record | Backspace: Reset"

        State.RECORDING:
            var seconds: float = (float(tape.size()) / float(Engine.physics_ticks_per_second))
            return "REC %.1f / %.1f s | R: Stop" % [ seconds, MAX_SECONDS ]

        State.REWINDING:
            return "REWINDING"

        State.PLAYING:
            return "PLAYBACK | R: Replay | Backspace: Erase"

    return ""

func _on_ghost_playback_finished() -> void:
    remove_ghost()