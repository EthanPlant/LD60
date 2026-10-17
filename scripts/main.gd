extends Node2D

const LEVEL_SCENES = [
	preload("res://scenes/levels/level_01.tscn"),
	preload("res://scenes/levels/level_02.tscn")
]

@onready var level_container: Node2D = $LevelContainer
@onready var level_label: Label = $HUD/LevelLabel
@onready var status_label: Label = $HUD/StatusLabel
@onready var hint_label: Label = $HUD/HintLabel

var current_level: LevelController = null
var current_level_index = 0
var game_finished: bool = false

func _ready() -> void:
	load_level(0)

func _process(_delta: float) -> void:
	if game_finished:
		return

	if is_instance_valid(current_level):
		status_label.text = current_level.recorder.get_status_text()

func _unhandled_input(event: InputEvent) -> void:
	if game_finished:
		return

	if not is_instance_valid(current_level):
		return

	if current_level.finished:
		return

	if event.is_echo():
		return

	if event.is_action_pressed("record"):
		current_level.recorder.handle_record()
		get_viewport().set_input_as_handled()

	elif event.is_action_pressed("erase"):
		current_level.recorder.erase_tape()
		get_viewport().set_input_as_handled()

func load_level(index: int) -> void:
	if is_instance_valid(current_level):
		level_container.remove_child(current_level)
		current_level.queue_free()

	current_level_index = index

	current_level = LEVEL_SCENES[index].instantiate() as LevelController

	level_container.add_child(current_level)
	current_level.completed.connect(_on_level_completed)

	level_label.text = current_level.level_name
	hint_label.text = current_level.level_hint

func advance_level() -> void:
	var next_index: int = current_level_index + 1

	if next_index < LEVEL_SCENES.size():
		load_level(next_index)
	else:
		finish_game()

func finish_game() -> void:
	game_finished = true

	if is_instance_valid(current_level):
		level_container.remove_child(current_level)
		current_level.queue_free()

	current_level = null

	level_label.text = "SIGNAL RESTORED"
	status_label.text = "You escaped the facility."
	hint_label.text = "End of transmission."

func _on_level_completed() -> void:
	call_deferred("advance_level")
