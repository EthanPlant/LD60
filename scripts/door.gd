class_name Door
extends StaticBody2D

const CLOSED_COLOUR := Color("#C35460")
const OPEN_COLOUR := Color("#85E08A", 0.3)

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var visual: Polygon2D = $Visual

var is_open: bool = false

func _ready() -> void:
    update_visual()

func set_open(should_open: bool) -> void:
    if is_open == should_open:
        return

    is_open = should_open

    collision_shape.set_deferred("disabled", is_open)

    update_visual()

func update_visual() -> void:
    visual.color = OPEN_COLOUR if is_open else CLOSED_COLOUR
