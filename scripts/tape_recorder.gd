class_name TapeRecorder
extends Node

signal reset_requested
signal ghost_removed(actor: Node2D)
signal tape_event(event_name: StringName)

enum State {
    READY,
    RECORDING,
    REWINDING,
    PLAYING
}

const MAX_SECONDS: float = 8.0
const REWIND_SECONDS: float = 0.3
const WEAR_PER_REPLAY: float = 0.75
const MAX_PLAYBACKS: int = 3

const GHOST_SCENE: PackedScene = preload("res://scenes/ghost.tscn")

@export var tape_wear_enabled: bool = true

@onready var player: PlayerController = $"../Player"
@onready var ghost_container: Node2D = $"../GhostContainer"

var state: State = State.READY

var tape: Array[Transform2D] = []
var ghost: GhostReplay = null

var playback_count: int = 0
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
            if can_play_again():
                start_rewind()
            else:
                tape_event.emit(&"broken")

        State.REWINDING:
            pass

func start_recording() -> void:
    remove_ghost()

    tape.clear()
    playback_count = 0
    state = State.RECORDING
    tape_event.emit(&"record")

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
    tape_event.emit(&"rewind")

func complete_rewind() -> void:
    reset_requested.emit()

    playback_count += 1

    var usable_frames: Array[Transform2D] = get_usable_frames()

    if usable_frames.is_empty():
        # A very short, heavily worn recording
        state = State.PLAYING
        player.set_movement_enabled(true)
        tape_event.emit(&"broken")
        return

    ghost = GHOST_SCENE.instantiate() as GhostReplay
    ghost_container.add_child(ghost)

    ghost.load_recording(tape)
    ghost.playback_finished.connect(_on_ghost_playback_finished)

    state = State.PLAYING
    player.set_movement_enabled(true)

    tape_event.emit(&"playback")

func erase_tape() -> void:
    if state == State.REWINDING:
        return

    remove_ghost()
    tape.clear()
    playback_count = 0

    reset_requested.emit()

    state = State.READY
    player.set_movement_enabled(true)

    tape_event.emit(&"erase")

func restart_attempt() -> void:
    if state == State.REWINDING:
        return

    if state == State.PLAYING and not tape.is_empty():
        if can_play_again():
            start_rewind()
        else:
            erase_tape()
            tape_event.emit(&"broken")
    else:
        erase_tape()

func remove_ghost() -> void:
    if is_instance_valid(ghost):

        ghost_removed.emit(ghost)
        ghost.queue_free()

    ghost = null

func get_usable_frames() -> Array[Transform2D]:
    var result: Array[Transform2D] = []

    var frames_lost: int = 0

    if tape_wear_enabled:
        frames_lost = roundi(float(playback_count - 1) * WEAR_PER_REPLAY * Engine.physics_ticks_per_second)

    var frame_limit: int = maxi(0, tape.size() - frames_lost)

    for i in range(frame_limit):
        result.append(tape[i])
    
    return result

func can_play_again():
    if not tape_wear_enabled:
        return true

    return playback_count < MAX_PLAYBACKS

func get_wear_ratio() -> float:
    if not tape_wear_enabled:
        return 0.0

    return clampf(float(maxi(0, playback_count - 1)) / 2.0, 0.0, 1.0)

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