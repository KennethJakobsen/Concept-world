class_name AudioSynth
extends RefCounted
## Procedurel generering af alle lyd-id'er som AudioStreamWAV (16-bit mono).
## Deterministisk (seedet RNG), så lydene er ens hver gang.

const RATE: int = 22050

## Kendte id'er → generator. Bruges når der ikke findes et katalog/en fil.
const SFX_IDS: Array[StringName] = [&"build", &"demolish", &"cash", &"breakdown", &"repair",
	&"sweep", &"ride_start", &"cheer", &"error"]
const UI_IDS: Array[StringName] = [&"click", &"hover", &"open", &"close"]
const AMBIENCE_IDS: Array[StringName] = [&"day", &"night"]
const MUSIC_IDS: Array[StringName] = [&"menu", &"park"]


static func has(id: StringName) -> bool:
	return id in SFX_IDS or id in UI_IDS or id in AMBIENCE_IDS or id in MUSIC_IDS


static func generate(id: StringName) -> AudioStreamWAV:
	match id:
		&"build": return _make(_thuds(3, 0.09, 140.0, 0.12), false)
		&"demolish": return _make(_noise_burst(0.45, 0.6, 2), false)
		&"cash": return _make(_seq([[1568.0, 0.06], [2093.0, 0.16]], 0.3, true), false)
		&"breakdown": return _make(_mix(_sweep(220.0, 70.0, 0.6, 0.35), _noise_burst(0.6, 0.25, 3)), false)
		&"repair": return _make(_thuds(4, 0.11, 900.0, 0.03), false)
		&"sweep": return _make(_noise_burst(0.3, 0.3, 4, true), false)
		&"ride_start": return _make(_seq([[523.0, 0.12], [659.0, 0.12], [784.0, 0.25]], 0.25, false), false)
		&"cheer": return _make(_cheer(0.9), false)
		&"error": return _make(_seq([[180.0, 0.12], [140.0, 0.2]], 0.3, false, true), false)
		&"click": return _make(_tone(1200.0, 0.03, 0.25), false)
		&"hover": return _make(_tone(1800.0, 0.02, 0.08), false)
		&"open": return _make(_sweep(400.0, 800.0, 0.1, 0.2), false)
		&"close": return _make(_sweep(800.0, 400.0, 0.1, 0.2), false)
		&"day": return _make(_ambience(4.0, false), true)
		&"night": return _make(_ambience(4.0, true), true)
		&"menu": return _make(_music([0, 4, 7, 12, 7, 4], 0.3, 220.0), true)
		&"park": return _make(_music([0, 2, 4, 7, 9, 7, 4, 2], 0.22, 261.63), true)
	return null


static func _make(samples: PackedFloat32Array, loop: bool) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32767.0))
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	if loop:
		w.loop_mode = AudioStreamWAV.LOOP_FORWARD
		w.loop_begin = 0
		w.loop_end = samples.size()
	return w


static func _env(t: float, dur: float, attack: float = 0.005) -> float:
	if t < attack:
		return t / attack
	return maxf(0.0, 1.0 - (t - attack) / maxf(dur - attack, 0.0001))


static func _tone(freq: float, dur: float, amp: float, square: bool = false) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var s := sin(TAU * freq * t)
		if square:
			s = signf(s) * 0.6
		out[i] = s * amp * _env(t, dur)
	return out


static func _sweep(f0: float, f1: float, dur: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	for i in n:
		var t := float(i) / RATE
		phase += TAU * lerpf(f0, f1, t / dur) / RATE
		out[i] = sin(phase) * amp * _env(t, dur)
	return out


static func _seq(notes: Array, amp: float, bell: bool, square: bool = false) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for note: Array in notes:
		var part := _tone(float(note[0]), float(note[1]), amp, square)
		if bell:
			part = _mix(part, _tone(float(note[0]) * 2.0, float(note[1]), amp * 0.3))
		out.append_array(part)
	return out


static func _noise_burst(dur: float, amp: float, seed_v: int, smooth: bool = false) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		var x := rng.randf_range(-1.0, 1.0)
		prev = lerpf(prev, x, 0.15 if smooth else 0.5)
		out[i] = prev * amp * _env(t, dur, 0.02 if smooth else 0.003)
	return out


static func _thuds(count: int, gap: float, freq: float, dur: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for k in count:
		var hit := _mix(_sweep(freq * 1.5, freq, dur, 0.5), _noise_burst(dur * 0.5, 0.2, 10 + k))
		out.append_array(hit)
		var pad := PackedFloat32Array()
		pad.resize(maxi(0, int((gap - dur) * RATE)))
		out.append_array(pad)
	return out


static func _cheer(dur: float) -> PackedFloat32Array:
	var out := _noise_burst(dur, 0.25, 7, true)
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for v in 5:
		var f := rng.randf_range(300.0, 700.0)
		var voice := _sweep(f, f * 1.3, dur * rng.randf_range(0.5, 0.9), 0.08)
		out = _mix(out, voice)
	return out


static func _ambience(dur: float, night: bool) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 21 if night else 22
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		prev = lerpf(prev, rng.randf_range(-1.0, 1.0), 0.03)
		var s := prev * 0.5
		if night:
			# fårekyllinger: korte pulserende højfrekvente toner
			var chirp := 1.0 if fmod(t, 0.5) < 0.12 else 0.0
			s += sin(TAU * 4200.0 * t) * 0.04 * chirp * (0.5 + 0.5 * sin(TAU * 30.0 * t))
		else:
			# fjern mumlen
			s += sin(TAU * 180.0 * t + sin(TAU * 0.7 * t) * 3.0) * 0.02
		# bløde kanter, så loopet ikke klikker
		s *= minf(1.0, minf(t, dur - t) / 0.05)
		out[i] = s
	return out


static func _music(steps: Array, step_s: float, root: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for rep in 2:
		for st: int in steps:
			var f := root * pow(2.0, float(st) / 12.0)
			var part := _mix(_tone(f, step_s, 0.18), _tone(f * 0.5, step_s, 0.1))
			out.append_array(part)
	return out


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate() if a.size() >= b.size() else b.duplicate()
	var other := b if a.size() >= b.size() else a
	for i in other.size():
		out[i] += other[i]
	return out
