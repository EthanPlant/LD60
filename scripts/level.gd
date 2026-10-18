class_name LevelController
extends Node2D

signal completed
signal feedback_requested(message: String)
signal sfx_requested(name: StringName)

@export var level_name: String = "Untitled Level"
@export_multiline var level_hint: String = ""

@onready var player: PlayerController = $Player
@onready var recorder: TapeRecorder = $Recorder
@onready var exit: ExitZone = $Exit

var spawn_transform: Transform2D
var finished: bool = false
var hit_pending = false

func _ready() -> void:
	spawn_transform = player.global_transform

	recorder.reset_requested.connect(reset_room)
	recorder.ghost_removed.connect(forget_activator)

	exit.reached.connect(_on_exit_reached)

	player.jump.connect(_on_jump)

	for node in get_tree().get_nodes_in_group("puzzle_doors"):
		var door := node as Door

		if door != null and is_ancestor_of(door):
			door.door_event.connect(_on_door_event)

	for node in get_tree().get_nodes_in_group("puzzle_barriers"):
		var barrier := node as ElectricalBarrier

		if barrier != null and is_ancestor_of(barrier):
			barrier.player_hit.connect(_on_barrier_hit)
			barrier.state_change.connect(_on_barrier_change)

	for node in get_tree().get_nodes_in_group("puzzle_sync_gates"):
		var gate := node as SyncGate

		if gate != null and is_ancestor_of(gate):
			gate.synchronized.connect(_on_synchronized)

func reset_room() -> void:
	player.reset_to(spawn_transform)

	for node in get_tree().get_nodes_in_group("puzzle_plates"):
		if is_ancestor_of(node):
			var plate: PressurePlate = node as PressurePlate
			plate.reset_state()
	
	for node in get_tree().get_nodes_in_group("puzzle_doors"):
		if is_ancestor_of(node):
			var door: Door = node as Door
			door.reset_state()

	for node in get_tree().get_nodes_in_group("puzzle_barriers"):
		if is_ancestor_of(node):
			var barrier: ElectricalBarrier = node as ElectricalBarrier
			barrier.reset_state()

	for node in get_tree().get_nodes_in_group("puzzle_sync_gates"):
		if is_ancestor_of(node):
			var gate: SyncGate = node as SyncGate
			gate.reset_state()

	exit.reset_state()

func forget_activator(actor: Node2D) -> void:
	for node in get_tree().get_nodes_in_group("puzzle_plates"):
		if is_ancestor_of(node):
			var plate: PressurePlate = node as PressurePlate
			plate.forget_activator(actor)

func restart_after_hit() -> void:
	if not finished:
		recorder.restart_attempt()

		hit_pending = false

func _on_jump() -> void:
	sfx_requested.emit(&"jump")

func _on_door_event(open: bool) -> void:
	if open:
		sfx_requested.emit(&"door_open")
	else:
		sfx_requested.emit(&"door_close")

func _on_synchronized() -> void:
	feedback_requested.emit("SYNC ESTABLISHED -- DOOR UNLOCKED")

func _on_barrier_change(energized: bool) -> void:
	if energized:
		sfx_requested.emit(&"barrier_on")
	else:
		sfx_requested.emit(&"barrier_off")

func _on_barrier_hit() -> void:
	if finished or hit_pending:
		return

	hit_pending = true

	feedback_requested.emit("TRACKING LOST -- REWINDING")

	call_deferred("restart_after_hit")

func _on_exit_reached() -> void:
	if finished:
		return

	if recorder.state != TapeRecorder.State.PLAYING:
		return

	finished = true
	exit.lock()
	player.set_movement_enabled(false)

	completed.emit()