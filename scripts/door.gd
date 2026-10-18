class_name Door
extends StaticBody2D

enum Mode {
    HOLD,
    TIMED
}

@export var mode: Mode = Mode.HOLD
@export var activation_plate: PressurePlate
@export_range(0.25, 10.0, 0.05, "suffix:s") var open_duration: float = 1.25

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual


var is_open: bool = false
var time_remaining = 0.0
var wipe_progress: float = 0.0
var wipe_tween: Tween

func _ready() -> void:
    add_to_group("puzzle_doors")

    if activation_plate != null:
        activation_plate.pressed_changed.connect(_on_plate_changed)

    set_physics_process(mode == Mode.TIMED)
    update_visual()

func _physics_process(delta: float) -> void:
    if mode != Mode.TIMED or not is_open:
        return

    time_remaining -= delta

    if time_remaining <= 0.0:
        time_remaining = 0.0
        set_open(false)

func set_open(should_open: bool) -> void:
    if is_open == should_open:
        return

    is_open = should_open

    collision_shape.set_deferred("disabled", is_open)

    update_visual()

func pulse_open(duration_override: float = -1.0) -> void:
    if mode != Mode.TIMED:
        push_warning("Cannot pulse a HOLD door.")
        return

    if duration_override > 0.0:
        time_remaining = duration_override
    else:
        time_remaining = open_duration
    
    set_open(true)

func reset_state() -> void:
    time_remaining = 0.0

    if wipe_tween != null:
        if wipe_tween.is_valid():
            wipe_tween.kill()
    
    set_wipe_progress(0.0)
    set_open(false)

func update_visual() -> void:
    if wipe_tween != null:
        if wipe_tween.is_valid():
            wipe_tween.kill()
    
    var target: float = 1.0 if is_open else 0.0

    wipe_tween = create_tween()
    wipe_tween.set_trans(Tween.TRANS_SINE)
    wipe_tween.set_ease(Tween.EASE_OUT)

    wipe_tween.tween_method(set_wipe_progress, wipe_progress, target, 0.2)

func set_wipe_progress(value: float) ->  void:
    wipe_progress = value

    visual.set_instance_shader_parameter("open_progress", wipe_progress)

func _on_plate_changed(pressed: bool) -> void:
    match mode:
        Mode.HOLD:
            set_open(pressed)
        
        Mode.TIMED:
            if pressed:
                pulse_open()
