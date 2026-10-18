class_name SoundEffects
extends Node

@export_range(-24.0, 0.0, 0.5) var effect_volume_db: float = -8.0
@export var enabled: bool = true

const MAX_VOICES := 8

const SOUNDS := {
    &"record": preload("res://sfx/record.wav"),
    &"rewind": preload("res://sfx/rewind.wav"),
    &"playback": preload("res://sfx/playback.wav"),
    &"playback_2": preload("res://sfx/playback_2.wav"),
    &"playback_3": preload("res://sfx/playback_3.wav"),
    &"erase": preload("res://sfx/erase.wav"),
    &"broken": preload("res:///sfx/broken.wav"),
    &"sync": preload("res:///sfx/sync.wav"),
    &"hit": preload("res:///sfx/hit.wav"),
    &"complete": preload("res://sfx/complete.wav"),
    &"plate_on": preload("res://sfx/plate_on.wav"),
    &"plate_off": preload("res://sfx/plate_off.wav"),
    &"door_open": preload("res://sfx/door_open.wav"),
    &"door_close": preload("res://sfx/door_close.wav"),
    &"barrier_on": preload("res://sfx/barrier_on.wav"),
    &"barrier_off": preload("res://sfx/barrier_off.wav"),
    &"start": preload("res://sfx/start.wav"),
    &"jump": preload("res://sfx/jump.wav"),
    &"land": preload("res://sfx/land.wav"),
}
const TAPE_HISS := preload("res://sfx/tape_hiss.wav")

var _voices: Array[AudioStreamPlayer] = []
var _next_voice := 0
var _wear := 0.0
var _hiss_target_db := -80.0
var _hiss_player: AudioStreamPlayer
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
    add_to_group("jam_sfx")
    _rng.randomize()

    for i in range(MAX_VOICES):
        var voice := AudioStreamPlayer.new()
        voice.volume_db = effect_volume_db
        add_child(voice)
        _voices.append(voice)

    _hiss_player = AudioStreamPlayer.new()
    add_child(_hiss_player)
    var loop_stream := TAPE_HISS.duplicate() as AudioStreamWAV
    loop_stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
    _hiss_player.stream = loop_stream
    _hiss_player.volume_db = -80.0


func play_event(event_name: StringName) -> void:
    if not enabled:
        return

    var sound_name := event_name
    if event_name == &"playback":
        if _wear >= 0.75:
            sound_name = &"playback_3"
        elif _wear >= 0.25:
            sound_name = &"playback_2"

    if not SOUNDS.has(sound_name):
        push_warning("Unknown SFX event: %s" % event_name)
        return

    # Use a free voice where possible so overlapping events aren't cut off.
    var voice := _find_voice()
    voice.stop()
    voice.stream = SOUNDS[sound_name]
    voice.volume_db = effect_volume_db
    voice.pitch_scale = 1.0

    # Slight variation keeps repeated switches from sounding identical.
    if event_name in [&"plate_on", &"plate_off", &"land"]:
        voice.pitch_scale = _rng.randf_range(0.97, 1.04)

    voice.play()


func set_wear(value: float) -> void:
    _wear = clampf(value, 0.0, 1.0)


func set_tape_state(is_playing: bool, wear: float) -> void:
    set_wear(wear)

    if not enabled or not is_playing:
        _hiss_target_db = -80.0
        return

    # Quiet when clean; louder as the analogue tape deteriorates.
    _hiss_target_db = lerpf(-39.0, -22.0, _wear)
    if not _hiss_player.playing:
        _hiss_player.play()


func _process(delta: float) -> void:
    if _hiss_player == null:
        return

    _hiss_player.volume_db = move_toward(
        _hiss_player.volume_db,
        _hiss_target_db,
        160.0 * delta
    )
    if _hiss_target_db <= -79.0 and _hiss_player.volume_db <= -79.0:
        if _hiss_player.playing:
            _hiss_player.stop()


func _find_voice() -> AudioStreamPlayer:
    for offset in range(MAX_VOICES):
        var index := (_next_voice + offset) % MAX_VOICES
        if not _voices[index].playing:
            _next_voice = (index + 1) % MAX_VOICES
            return _voices[index]

    var voice := _voices[_next_voice]
    _next_voice = (_next_voice + 1) % MAX_VOICES
    return voice
