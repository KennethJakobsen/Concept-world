class_name CoasterProfile
extends RefCounted
## Forudberegnet 1D-profil for én omgang (CoasterPhysics). Genberegnes ved load; gemmes ikke.

var length: float = 0.0
var duration_s: float = 0.0
var samples_t: PackedFloat32Array = PackedFloat32Array()  ## tid (s) pr. sample
var samples_s: PackedFloat32Array = PackedFloat32Array()  ## buelængde (m)
var samples_v: PackedFloat32Array = PackedFloat32Array()  ## fart (m/s)
var samples_g: PackedFloat32Array = PackedFloat32Array()  ## vertikal g
var samples_lat: PackedFloat32Array = PackedFloat32Array()  ## lateral g
var max_speed: float = 0.0
var max_g: float = 0.0
var max_lat: float = 0.0
var drops: int = 0
var turns: int = 0
var max_height: int = 0
var ok: bool = false


func _index_at(t: float) -> Array:
	var n: int = samples_t.size()
	if n == 0:
		return [0, 0.0]
	var time: float = clampf(t, 0.0, 1.0) * duration_s
	var lo: int = 0
	var hi: int = n - 1
	while hi - lo > 1:
		var mid: int = (lo + hi) / 2
		if samples_t[mid] <= time:
			lo = mid
		else:
			hi = mid
	var span: float = samples_t[hi] - samples_t[lo]
	var f: float = 0.0 if span <= 0.0 else clampf((time - samples_t[lo]) / span, 0.0, 1.0)
	return [lo, f]


## Buelængde (m) ved t = andel 0..1 af turens køretid (svarer til Attraction.ride_progress()).
func position_at(t: float) -> float:
	if samples_s.is_empty():
		return 0.0
	var r: Array = _index_at(t)
	var i: int = r[0]
	var j: int = mini(i + 1, samples_s.size() - 1)
	return lerpf(samples_s[i], samples_s[j], r[1])


## Fart (m/s) ved t = andel 0..1 af køretiden.
func speed_at(t: float) -> float:
	if samples_v.is_empty():
		return 0.0
	var r: Array = _index_at(t)
	var i: int = r[0]
	var j: int = mini(i + 1, samples_v.size() - 1)
	return lerpf(samples_v[i], samples_v[j], r[1])
