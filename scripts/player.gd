class_name PlayerController
extends CharacterBody2D

@export var move_speed: float = 180.0
@export var acceleration: float = 1400.0
@export var friction: float = 1800.0
@export var jump_velocity: float = -310.0
@export var gravity: float = 900.0

var movement_enabled: bool = true

func _ready() -> void:
    add_to_group("plate_activator")

func _physics_process(delta: float) -> void:
    if not movement_enabled:
        return

    apply_gravity(delta)
    handle_jump()
    handle_horizontal_movement(delta)

    move_and_slide()

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

func reset_to(target_transform: Transform2D) -> void:
    global_transform = target_transform
    velocity = Vector2.ZERO
    reset_physics_interpolation()