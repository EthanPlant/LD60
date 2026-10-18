class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 180.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -310.0
@export var gravity: float = 900.0

@onready var visual: Polygon2D = $Visual

var movement_enabled: bool = true
var recording_visual: bool = false
var visual_flash: float = 0.0

func _ready() -> void:
    add_to_group("plate_activator")

func _process(delta: float) -> void:
    visual_flash = move_toward(visual_flash, 0.0, delta * 4.0)
    var motion: float = clamp(absf(velocity.x) / move_speed, 0.0, 1.0)
    visual.set_instance_shader_parameter("movement", motion)
    visual.set_instance_shader_parameter("airborne", 0.0 if is_on_floor() else 1.0)
    visual.set_instance_shader_parameter("recording", 1.0 if recording_visual else 0.0)
    visual.set_instance_shader_parameter("reset_flash", visual_flash)

func _physics_process(delta: float) -> void:
    if not movement_enabled:
        return

    apply_gravity(delta)
    handle_jump()
    handle_horizontal_movement(delta)

    move_and_slide()
    global_position.x = clampf(global_position.x, 10, 950) # Clamp the player into the level

func apply_gravity(delta: float) -> void:
    if not is_on_floor():
        velocity.y += gravity * delta

func handle_jump() -> void:
    if Input.is_action_just_pressed("jump") and is_on_floor():
        velocity.y = jump_velocity

func handle_horizontal_movement(delta: float) -> void:
    var direction: float = Input.get_axis(
        "move_left",
        "move_right"
    )

    var target_velocity: float = direction * move_speed

    if is_zero_approx(direction):
        velocity.x = move_toward(velocity.x, 0.0, friction * delta)
    else:
        velocity.x = move_toward(velocity.x, target_velocity, acceleration * delta)

func set_movement_enabled(enabled: bool) -> void:
    movement_enabled = enabled

    if not enabled:
        velocity = Vector2.ZERO

func set_recording_visual(enabled: bool) -> void:
    recording_visual = enabled

func reset_to(target_transform: Transform2D) -> void:
    global_transform = target_transform
    velocity = Vector2.ZERO
    visual_flash = 1.0
    reset_physics_interpolation()