class_name SoundEffects
extends Node

const SAMPLE_RATE: int = 22050

var rng := RandomNumberGenerator.new()

func play_event(event_name: StringName) -> void:
    var freq: float = 440.0
    var sweep: float = 0.0
    var duration: float = 0.12
    var noise_mix: float = 0.1

    match event_name:
        &"record":
            freq = 850.0
            sweep = -350.0
            duration = 0.99

        &"rewind":
            freq = 700.0
            sweep = -550.0
            duration = 0.35
            noise_mix = 0.3

        &"playback":
            freq = 330.0
            sweep = 220.0
            duration = 0.13

        &"erase":
            freq = 240.0
            duration = 0.09
            noise_mix = 0.5

        &"broken":
            freq = 120.0
            duration = 0.35
            noise_mix = 0.8

        &"sync":
            freq = 520.0
            sweep = 420.0
            duration = 0.25

        &"hit":
            freq = 90.0
            duration = 0.25
            noise_mix = 0.95

        &"complete":
            freq = 660.0
            sweep = 440.0
            duration = 0.45

        _:
            return
    play_tone(freq, sweep, duration, noise_mix)

func play_tone(freq: float, sweep: float, duration: float, noise_mix: float) -> void:
    var sample_count: int = int(SAMPLE_RATE * duration)

    var bytes = PackedByteArray()
    bytes.resize(sample_count * 2)

    var phase: float = 0.0

    for i in range(sample_count):
        var progress: float = float(i) / float(sample_count)

        var curr_freq = freq + sweep * progress

        phase += TAU * curr_freq / float(SAMPLE_RATE)

        var tone: float = sin(phase)
        var noise = rng.randf_range(-1.0, 1.0)

        var envelope: float = pow(1.0 - progress, 2.0) * minf(1.0, progress * 100.0)

        var sample: float = (tone * (1.0 - noise_mix) + noise * noise_mix) * envelope * 0.22
        bytes.encode_s16(i * 2, int(clampf(sample, -1.0, 1.0) * 32767.0))

    var wave := AudioStreamWAV.new()
    wave.format = AudioStreamWAV.FORMAT_16_BITS
    wave.mix_rate = SAMPLE_RATE
    wave.stereo = false
    wave.data = bytes

    var audio_player := AudioStreamPlayer.new()

    add_child(audio_player)
    audio_player.stream = wave
    audio_player.volume_db = -9.0

    audio_player.finished.connect(audio_player.queue_free)

    audio_player.play()
