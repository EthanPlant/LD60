class_name ExitZone
extends Area2D

signal reached

var armed: bool = true

func _ready() -> void:
    body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node2D) -> void:
    if not armed:
        return

    if body is PlayerController:
        reached.emit()

func lock() -> void:
    armed = false

func reset_state() -> void:
    armed = true
