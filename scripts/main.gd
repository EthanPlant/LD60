extends Node2D

const LEVEL_SCENES = [
	preload("res://scenes/levels/level_01.tscn"),
	preload("res://scenes/levels/level_02.tscn"),
	preload("res://scenes/levels/level_03.tscn"),
	preload("res://scenes/levels/level_04.tscn"),
	preload("res://scenes/levels/level_05.tscn"),
	preload("res://scenes/levels/level_06.tscn"),
]

@onready var title_screen: TitleScreen = $HUD/TitleScreen
@onready var level_container: Node2D = $LevelContainer
@onready var hud: CamcorderHUD = $HUD/OSD
@onready var vhs: VHSOverlay = $FX
@onready var sfx: SoundEffects = $SFX

var current_level: LevelController = null
var current_level_index = 0
var game_finished: bool = false

func _ready() -> void:
	title_screen.start_requested.connect(_on_title_start)

	hud.hide()
	title_screen.show_screen()

	vhs.reset_effect()
	vhs.set_wear(0.12)

func _process(_delta: float) -> void:
	if current_level == null:
		return

	if game_finished:
		return

	if is_instance_valid(current_level):
		current_level.player.set_recording_visual(current_level.recorder.state == TapeRecorder.State.RECORDING)
		vhs.set_wear(current_level.recorder.get_wear_ratio())

func _unhandled_input(event: InputEvent) -> void:
	if game_finished:
		if event is InputEventKey:
			if event.pressed and not event.echo and event.keycode == KEY_ENTER:
				game_finished = false
				load_level(0)
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

	current_level.feedback_requested.connect(_on_feedback)
	hud.begin_level(current_level.level_name, current_level.level_hint, current_level.recorder)
	current_level.recorder.tape_event.connect(_on_tape_event)
	
	vhs.reset_effect()

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

	vhs.reset_effect()
	sfx.play_event(&"complete")

	hud.show_ending()

func _on_title_start() -> void:
	title_screen.hide()
	hud.show()

	vhs.reset_effect()

	load_level(0)

func _on_level_completed() -> void:
	call_deferred("advance_level")

func _on_feedback(message: String) -> void:
	var danger = message.begins_with("TRACKING_LOST")
	if danger:
		vhs.trigger_rewind()
		sfx.play_event(&"hit")
	else:
		sfx.play_event(&"sync")
		
	hud.show_feedback(message, danger)

func _on_tape_event(event_name: StringName) -> void:
	sfx.play_event(event_name)

	if event_name == &"rewind":
		vhs.trigger_rewind()
