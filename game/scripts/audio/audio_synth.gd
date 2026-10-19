class_name AudioSynth
extends RefCounted
## Procedurel generering af alle lyd-id'er som AudioStreamWAV (16-bit mono).
## Deterministisk (seedet RNG), så lydene er ens hver gang.

const RATE: int = 22050

## Kendte id'er → generator. Bruges når der ikke findes et katalog/en fil.
const SFX_IDS: Array[StringName] = [&"build", &"demolish", &"cash", &"breakdown", &"repair",
	&"sweep", &"ride_start", &"cheer", &"error", &"splash", &"vomit"]
const UI_IDS: Array[StringName] = [&"click", &"hover", &"open", &"close"]
const AMBIENCE_IDS: Array[StringName] = [&"day", &"night"]
const MUSIC_IDS: Array[StringName] = [&"menu", &"park"]


static func has(id: StringName) -> bool:
	return id in SFX_IDS or id in UI_IDS or id in AMBIENCE_IDS or id in MUSIC_IDS


static func generate(id: StringName) -> AudioStreamWAV:
	match id:
		&"build": return _make(_thuds(3, 0.09, 140.0, 0.12), false)
		&"demolish": return _make(_noise_burst(0.45, 0.6, 2), false)
		&"cash": return _make(_soft_pling(1046.5, 0.28, 0.12), false)
		&"breakdown": return _make(_mix(_sweep(220.0, 70.0, 0.6, 0.35), _noise_burst(0.6, 0.25, 3)), false)
		&"repair": return _make(_thuds(4, 0.11, 900.0, 0.03), false)
		&"sweep": return _make(_noise_burst(0.3, 0.3, 4, true), false)
		&"ride_start": return _make(_seq([[523.0, 0.12], [659.0, 0.12], [784.0, 0.25]], 0.25, false), false)
		&"cheer": return _make(_cheer(0.9), false)
		&"error": return _make(_seq([[180.0, 0.12], [140.0, 0.2]], 0.3, false, true), false)
		&"splash": return _make(_splash(0.6, 0.14), false)
		&"vomit": return _make(_vomit(0.3, 0.16), false)
		&"click": return _make(_tone(1200.0, 0.03, 0.25), false)
		&"hover": return _make(_tone(1800.0, 0.02, 0.08), false)
		&"open": return _make(_sweep(400.0, 800.0, 0.1, 0.2), false)
		&"close": return _make(_sweep(800.0, 400.0, 0.1, 0.2), false)
		&"day": return _make(_ambience(4.0, false), true)
		&"night": return _make(_ambience(4.0, true), true)
		&"menu": return _make(_compose(90.0, 3, 220.0, MENU_A, MENU_B, 31, false), true)
		&"park": return _make(_compose(110.0, 4, 261.63, PARK_A, PARK_B, 47, true), true)
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


## T-055: blødt, dæmpet pling (sinus + svag oktav, langsom attack, eksponentiel decay).
static func _soft_pling(freq: float, dur: float, amp: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	for i in n:
		var t := float(i) / RATE
		var e := minf(1.0, t / 0.012) * exp(-t * 14.0)
		out[i] = (sin(TAU * freq * t) + 0.15 * sin(TAU * freq * 2.0 * t)) * amp * e
	return out


## T-156: vandplask – hvid stoej, hurtig attack, 0.6 s eksponentiel decay, baandpas ca. 800-4000 Hz.
static func _splash(dur: float, amp: float) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 156
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var a_lo := 1.0 - exp(-TAU * 800.0 / RATE)
	var a_hi := 1.0 - exp(-TAU * 4000.0 / RATE)
	var lp_hi := 0.0
	var lp_lo := 0.0
	for i in n:
		var t := float(i) / RATE
		var x := rng.randf_range(-1.0, 1.0)
		lp_hi += a_hi * (x - lp_hi)
		lp_lo += a_lo * (lp_hi - lp_lo)
		var e := minf(1.0, t / 0.004) * exp(-t * 8.0) * minf(1.0, (dur - t) / 0.02)
		out[i] = (lp_hi - lp_lo) * 1.6 * amp * e
	return out


## T-156: kort, daempet klask – lavpasfiltreret stoej, cutoff falder 400 -> 120 Hz over 0.3 s.
static func _vomit(dur: float, amp: float) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 157
	var n := int(dur * RATE)
	var out := PackedFloat32Array()
	out.resize(n)
	var lp := 0.0
	for i in n:
		var t := float(i) / RATE
		var fc := lerpf(400.0, 120.0, t / dur)
		lp += (1.0 - exp(-TAU * fc / RATE)) * (rng.randf_range(-1.0, 1.0) - lp)
		var e := minf(1.0, t / 0.01) * exp(-t * 9.0) * minf(1.0, (dur - t) / 0.02)
		out[i] = lp * 4.0 * amp * e
	return out


# --- Musik (T-055) -------------------------------------------------------------
# Akkorder angives som halvtoner over grundtonen (dur-skala-trin). Hver sektion = 8 takter.
const MAJ: Array[int] = [0, 4, 7]
const MIN: Array[int] = [0, 3, 7]
## [rod (halvtoner), akkordtype]
const PARK_A: Array = [[0, 0], [9, 1], [5, 0], [7, 0], [0, 0], [4, 1], [5, 0], [7, 0]]
const PARK_B: Array = [[5, 0], [7, 0], [4, 1], [9, 1], [2, 1], [7, 0], [0, 0], [7, 0]]
const MENU_A: Array = [[0, 0], [5, 0], [9, 1], [7, 0], [0, 0], [2, 1], [5, 0], [7, 0]]
const MENU_B: Array = [[9, 1], [4, 1], [5, 0], [0, 0], [2, 1], [7, 0], [5, 0], [7, 0]]
const SCALE: Array[int] = [0, 2, 4, 5, 7, 9, 11]


## Sektioner A – A' – B – A'' med variation i melodien, bas og percussion.
static func _compose(bpm: float, beats: int, root: float, prog_a: Array, prog_b: Array,
		seed_v: int, perc: bool) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var beat_s := 60.0 / bpm
	var bar_s := beat_s * beats
	var sections: Array = [[prog_a, 0, 0.0], [prog_a, 1, 0.0], [prog_b, 2, 0.25], [prog_a, 3, 0.0]]
	var total := int(bar_s * 8.0 * sections.size() * RATE) + 1
	var out := PackedFloat32Array()
	out.resize(total)
	# Grundmotiv (rytme + kontur) for A; varieres i A' og A''.
	var motif: Array = _motif(rng, beats)
	var t0 := 0.0
	for sec: Array in sections:
		var prog: Array = sec[0]
		var var_lvl: int = sec[1]
		var lift: float = sec[2]
		var sec_motif: Array = motif if var_lvl == 0 else (_motif(rng, beats) if var_lvl == 2 else _vary(motif, rng, var_lvl))
		for bar in 8:
			var ch: Array = prog[bar]
			var croot: int = ch[0]
			var tones: Array[int] = MIN if int(ch[1]) == 1 else MAJ
			var bt := t0 + bar * bar_s
			# bas: oom-pah (grundtone på 1, kvint/akkord på resten)
			for b in beats:
				var bf := root * 0.25 * pow(2.0, float(croot + (0 if b == 0 else tones[2 if b % 2 == 1 else 1])) / 12.0)
				_add_note(out, bt + b * beat_s, beat_s * (0.9 if b == 0 else 0.5), bf, 0.09 if b == 0 else 0.05, 1)
			# akkord-pad (blød, lav)
			for tn: int in tones:
				_add_note(out, bt, bar_s * 0.95, root * 0.5 * pow(2.0, float(croot + tn) / 12.0), 0.025, 2)
			# melodi: motiv-trin mappes til akkordtoner/skala omkring akkordens rod
			var last_bar := bar == 7
			for ev: Array in sec_motif[bar % sec_motif.size()]:
				var pos: float = ev[0]
				var dur: float = ev[1]
				var deg: int = ev[2]
				if last_bar and pos > 0.0:
					continue
				var semis := _degree_to_semis(croot, deg, tones, last_bar)
				var f := root * pow(2.0, (float(semis) + lift * 12.0) / 12.0)
				_add_note(out, bt + pos * beat_s, dur * beat_s * (2.0 if last_bar else 1.0), f, 0.11, 0)
			if perc:
				for b in beats:
					_add_hit(out, bt + b * beat_s, 0.05 if b % 2 == 0 else 0.025, rng)
		t0 += bar_s * 8.0
	# blød kant i loop-sømmen
	var edge := int(0.01 * RATE)
	for i in edge:
		var k := float(i) / edge
		out[i] *= k
		out[total - 1 - i] *= k
	return out


## Motiv: 4 takter à liste af [beat-position, varighed (beats), trin]. Trin: 0..4 = akkordtone-indeks/skala.
static func _motif(rng: RandomNumberGenerator, beats: int) -> Array:
	var rhythms: Array = [[[0.0, 1.0], [1.0, 1.0], [2.0, 1.0]], [[0.0, 1.5], [1.5, 0.5], [2.0, 1.0]],
		[[0.0, 0.5], [0.5, 0.5], [1.0, 1.0], [2.0, 1.0]], [[0.0, 2.0], [2.0, 1.0]]]
	if beats == 4:
		rhythms = [[[0.0, 1.0], [1.0, 1.0], [2.0, 1.0], [3.0, 1.0]], [[0.0, 1.5], [1.5, 0.5], [2.0, 2.0]],
			[[0.0, 0.5], [0.5, 0.5], [1.0, 1.0], [2.0, 0.5], [2.5, 0.5], [3.0, 1.0]], [[0.0, 2.0], [2.0, 1.0], [3.0, 1.0]]]
	var m: Array = []
	var deg := 2
	for bar in 4:
		var r: Array = rhythms[rng.randi_range(0, rhythms.size() - 1)]
		var notes: Array = []
		for ev: Array in r:
			deg = clampi(deg + rng.randi_range(-2, 2), 0, 6)
			notes.append([ev[0], ev[1], deg])
		m.append(notes)
	return m


static func _vary(m: Array, rng: RandomNumberGenerator, lvl: int) -> Array:
	var out: Array = []
	for bar: Array in m:
		var nb: Array = []
		for ev: Array in bar:
			var d: int = ev[2]
			if rng.randf() < 0.35 * lvl:
				d = clampi(d + rng.randi_range(-1, 2), 0, 6)
			nb.append([ev[0], ev[1], d])
		out.append(nb)
	return out


static func _degree_to_semis(croot: int, deg: int, tones: Array[int], final: bool) -> int:
	if final:
		return 12 + croot + tones[0]
	# lige trin = akkordtone, ulige = skalatone (gennemgangstone)
	if deg % 2 == 0:
		return 12 + croot + tones[(deg / 2) % 3] + (12 if deg >= 6 else 0)
	var s := 12 + croot + tones[(deg / 2) % 3]
	for st: int in SCALE:
		if (st - (s % 12) + 12) % 12 >= 1 and (st - (s % 12) + 12) % 12 <= 2:
			return s + ((st - (s % 12) + 12) % 12)
	return s + 2


## kind: 0 = lead (trekant-agtig + let vibrato), 1 = bas (sinus), 2 = pad (sinus, langsom attack)
static func _add_note(out: PackedFloat32Array, start: float, dur: float, freq: float, amp: float, kind: int) -> void:
	var i0 := int(start * RATE)
	var n := int(dur * RATE)
	var att := 0.08 if kind == 2 else 0.01
	for i in n:
		var idx := i0 + i
		if idx >= out.size():
			return
		var t := float(i) / RATE
		var e := minf(1.0, t / att) * minf(1.0, (dur - t) / 0.04)
		if kind != 2:
			e *= exp(-t * (2.5 if kind == 0 else 4.0))
		var s: float
		if kind == 0:
			var ph := TAU * freq * t + 0.02 * sin(TAU * 5.0 * t)
			s = sin(ph) + 0.25 * sin(ph * 2.0) + 0.1 * sin(ph * 3.0)
		else:
			s = sin(TAU * freq * t)
		out[idx] += s * amp * e


static func _add_hit(out: PackedFloat32Array, start: float, amp: float, rng: RandomNumberGenerator) -> void:
	var i0 := int(start * RATE)
	var n := int(0.05 * RATE)
	var prev := 0.0
	for i in n:
		var idx := i0 + i
		if idx >= out.size():
			return
		prev = lerpf(prev, rng.randf_range(-1.0, 1.0), 0.6)
		out[idx] += prev * amp * exp(-float(i) / RATE * 60.0)


static func _mix(a: PackedFloat32Array, b: PackedFloat32Array) -> PackedFloat32Array:
	var out := a.duplicate() if a.size() >= b.size() else b.duplicate()
	var other := b if a.size() >= b.size() else a
	for i in other.size():
		out[i] += other[i]
	return out
