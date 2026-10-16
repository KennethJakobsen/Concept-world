class_name CoasterPhysics
extends RefCounted
## 1D-fysik langs banen (ADR-003): lineær højde pr. stykke, energibevarelse, friktion,
## kædelift og station med konstant fart. Faste skridt på DT sekunder.
## Toget (trains.json) kan valgfrit overskrive curve_radius og transition_len (m).

const DT: float = 0.05
const G: float = 9.81
const MIN_SPEED: float = 0.1
const CURVE_RADIUS: float = 0.5  ## celler (= m) for kurver
const TRANSITION_LEN: float = 1.0  ## m, hvor en hældningsovergang fordeles (±0,5 m om samlingen)
const MAX_STEPS: int = 100000


static func simulate(track: CoasterTrack, train: Dictionary, pieces: Dictionary = {}) -> CoasterProfile:
	var prof := CoasterProfile.new()
	var defs: Dictionary = pieces if not pieces.is_empty() else track.defs
	var n: int = track.pieces.size()
	if n == 0:
		return prof
	var starts := PackedFloat32Array()
	var lens := PackedFloat32Array()
	var theta := PackedFloat32Array()
	var kinds: Array[String] = []
	var turns := PackedInt32Array()
	var h0 := PackedFloat32Array()
	var rises := PackedFloat32Array()
	var lifts := PackedFloat32Array()
	var fricts := PackedFloat32Array()
	var train_fr: float = float(train.get("friction", 0.02))
	var train_lift: float = float(train.get("lift_speed", 2.5))
	var station_v: float = float(train.get("station_speed", 2.0))
	var radius: float = float(train.get("curve_radius", CURVE_RADIUS))
	var trans: float = float(train.get("transition_len", TRANSITION_LEN))
	var s_acc: float = 0.0
	for i in n:
		var p: TrackPiece = track.pieces[i]
		var d: TrackPieceDef = defs.get(p.def_id, null)
		if d == null:
			return prof
		starts.append(s_acc)
		lens.append(d.length)
		s_acc += d.length
		theta.append(atan2(float(d.rise), d.horizontal_length()))
		kinds.append(d.kind)
		turns.append(d.turn)
		h0.append(float(p.level))
		rises.append(float(d.rise))
		lifts.append(d.lift_speed if d.lift_speed >= 0.0 else train_lift)
		fricts.append(d.friction if d.friction >= 0.0 else train_fr)
		prof.max_height = maxi(prof.max_height, maxi(p.level, p.level + d.rise))
		if d.turn != 0:
			prof.turns += 1
		if d.splash:
			prof.splashes += 1
			prof.splash_s.append(s_acc)
			prof.splash_pieces.append(i)
	for i in n:
		if rises[i] < 0.0 and rises[posmod(i - 1, n)] >= 0.0:
			prof.drops += 1
	if prof.drops == 0 and n > 0:
		var all_down: bool = true
		for r in rises:
			all_down = all_down and r < 0.0
		if all_down:
			prof.drops = 1
	var total: float = s_acc
	prof.length = total
	if track.speed_mode == "constant":
		return _simulate_constant(prof, total, float(train.get("cruise_speed", station_v)))
	var s: float = 0.0
	var v: float = station_v
	var t: float = 0.0
	var idx: int = 0
	prof.ok = true
	var steps: int = 0
	while true:
		_record(prof, t, s, v, idx, starts, lens, theta, turns, n, radius, trans)
		if s >= total or steps >= MAX_STEPS:
			break
		steps += 1
		var ds: float = v * DT
		var s_new: float = s + ds
		var step_t: float = DT
		if s_new >= total:
			s_new = total
			step_t = (total - s) / maxf(v, 1e-6)
			ds = total - s
		var h_prev: float = _height(s, idx, starts, lens, h0, rises)
		while idx < n - 1 and s_new >= starts[idx + 1]:
			idx += 1
		var h: float = _height(s_new, idx, starts, lens, h0, rises)
		var v2: float = v * v + 2.0 * G * (h_prev - h) - fricts[idx] * v * v * ds
		if kinds[idx] == "station":
			v = station_v
		elif kinds[idx] == "lift":
			v = maxf(sqrt(maxf(v2, 0.0)), lifts[idx])
		elif v2 <= MIN_SPEED * MIN_SPEED:
			prof.ok = false
			v = 0.0
			s = s_new
			t += step_t
			_record(prof, t, s, v, idx, starts, lens, theta, turns, n, radius, trans)
			break
		else:
			v = sqrt(v2)
		s = s_new
		t += step_t
	if steps >= MAX_STEPS:
		prof.ok = false
	prof.duration_s = t
	return prof


static func _height(s: float, idx: int, starts: PackedFloat32Array, lens: PackedFloat32Array,
		h0: PackedFloat32Array, rises: PackedFloat32Array) -> float:
	var f: float = clampf((s - starts[idx]) / lens[idx], 0.0, 1.0)
	return h0[idx] + rises[idx] * f


static func _record(prof: CoasterProfile, t: float, s: float, v: float, idx: int, starts: PackedFloat32Array,
		lens: PackedFloat32Array, theta: PackedFloat32Array, turns: PackedInt32Array, n: int,
		radius: float, trans: float) -> void:
	# Vertikal krumning: nærmeste samling (start eller slut af stykket idx).
	var kappa: float = 0.0
	var half: float = trans * 0.5
	var into: float = s - starts[idx]
	if into < half:
		kappa = (theta[idx] - theta[posmod(idx - 1, n)]) / trans
	elif lens[idx] - into < half:
		kappa = (theta[(idx + 1) % n] - theta[idx]) / trans
	var g: float = 1.0 + v * v * kappa / G
	var lat: float = v * v / (radius * G) if turns[idx] != 0 else 0.0
	prof.samples_t.append(t)
	prof.samples_s.append(s)
	prof.samples_v.append(v)
	prof.samples_g.append(g)
	prof.samples_lat.append(lat)
	prof.max_speed = maxf(prof.max_speed, v)
	prof.max_g = maxf(prof.max_g, g)
	prof.max_lat = maxf(prof.max_lat, lat)


## ADR-004: konstant fart (minitog, svævebane). g = 1, ingen lateral g; altid ok.
static func _simulate_constant(prof: CoasterProfile, total: float, v: float) -> CoasterProfile:
	v = maxf(v, MIN_SPEED)
	prof.ok = true
	var t: float = 0.0
	var s: float = 0.0
	while true:
		prof.samples_t.append(t)
		prof.samples_s.append(s)
		prof.samples_v.append(v)
		prof.samples_g.append(1.0)
		prof.samples_lat.append(0.0)
		if s >= total:
			break
		var ds: float = minf(v * DT, total - s)
		t += ds / v
		s += ds
	prof.max_speed = v
	prof.max_g = 1.0
	prof.max_lat = 0.0
	prof.duration_s = t
	return prof
