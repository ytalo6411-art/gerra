extends Node
## Original procedural placeholder audio: one wind bed and short interaction cues.

var wind := AudioStreamPlayer.new()
var sfx := AudioStreamPlayer.new()
var clips: Dictionary = {}

func build() -> void:
	add_child(wind)
	add_child(sfx)
	wind.volume_db = -23
	sfx.volume_db = -17
	wind.stream = _synthesize("wind", 3.54)
	for key: String in ["step", "pickup", "water", "door", "fire", "food", "shelter", "save"]:
		clips[key] = _synthesize(key, 0.13 if key == "step" else 0.26)

func start() -> void:
	if not wind.playing:
		wind.play()

func silent(pause: bool) -> void:
	wind.stream_paused = pause

func cue(kind: String) -> void:
	if clips.has(kind):
		sfx.stream = clips[kind]
		sfx.volume_db = -24 if kind == "step" else -15
		var pitch := 0.88 + 0.24 * randf() if kind == "step" else 1.0
		sfx.pitch_scale = pitch
		sfx.play()

static func _synthesize(kind: String, seconds: float) -> AudioStreamWAV:
	const RATE := 16000
	var rng := RandomNumberGenerator.new()
	rng.seed = 4708 + kind.hash()
	var count := int(seconds * RATE)
	var audio := PackedByteArray()
	audio.resize(count * 2)
	var low := 0.0
	for i in range(count):
		var phase := float(i) / float(count)
		var t := float(i) / RATE
		var sample := rng.randf_range(-1, 1)
		low = lerpf(low, sample, 0.055 if kind == "wind" else 0.18)
		var pulse := smoothstep(0.0, 0.055, phase) * (1.0 - smoothstep(0.12, 1.0, phase))
		var signal_value := 0.0
		match kind:
			"wind": signal_value = (low * 0.7 + sample * 0.071) * (0.63 + sin(phase * TAU) * 0.32) * smoothstep(0.0, 0.025, phase) * (1.0 - smoothstep(0.975, 1.0, phase))
			"step", "door", "pickup": signal_value = (low + sample * 0.145) * pulse * (0.95 if kind == "door" else 0.65)
			"water": signal_value = (low * 0.47 + sin(TAU * (404.0 * t - 450.0 * t * t)) * 0.20) * pulse
			"fire": signal_value = (sample * 0.22 + low * 0.39) * pulse * (0.53 + 0.40 * sin(TAU * t * 32.0))
			_: signal_value = (low * 0.3 + 0.14 * sin(TAU * t * 384.0) + 0.09 * sin(TAU * t * 576.0)) * pulse
		audio.encode_s16(i * 2, int(clampf(signal_value, -1, 1) * 32700.0))
	var clip := AudioStreamWAV.new()
	clip.format = AudioStreamWAV.FORMAT_16_BITS
	clip.mix_rate = RATE
	clip.data = audio
	if kind == "wind":
		clip.loop_mode = AudioStreamWAV.LOOP_FORWARD
		clip.loop_end = count
	return clip
