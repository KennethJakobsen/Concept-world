class_name CoasterRatings
extends RefCounted
## Excitement/intensity/nausea (0..10, 2 decimaler) ud fra profilen. Vægte: content/coaster/ratings.json.
## g-bidrag regnes som overskud over 1 g (|max_g − 1|); fart i m/s.


static func rate(profile: CoasterProfile, weights: Dictionary) -> Dictionary:
	var e: Dictionary = weights.get("excitement", {})
	var i: Dictionary = weights.get("intensity", {})
	var nz: Dictionary = weights.get("nausea", {})
	var th: Dictionary = weights.get("thresholds", {})
	var g_ex: float = maxf(0.0, profile.max_g - 1.0)
	var length_bonus: float = minf(_w(e, "per_length") * profile.length, _w(e, "max_length_bonus", INF))
	var exc: float = _w(e, "base") + length_bonus + _w(e, "per_max_speed") * profile.max_speed \
		+ _w(e, "per_drop") * profile.drops + _w(e, "per_max_g") * g_ex \
		+ _w(e, "per_max_lat") * profile.max_lat + _w(e, "per_duration_s") * profile.duration_s
	var factor: float = _w(th, "penalty_factor", 1.0)
	if profile.max_g > _w(th, "max_g_penalty", INF):
		exc *= factor
	if profile.max_lat > _w(th, "max_lat_penalty", INF):
		exc *= factor
	var inten: float = _w(i, "base") + _w(i, "per_max_speed") * profile.max_speed + _w(i, "per_max_g") * g_ex \
		+ _w(i, "per_max_lat") * profile.max_lat + _w(i, "per_drop") * profile.drops
	var naus: float = _w(nz, "base") + _w(nz, "per_max_lat") * profile.max_lat + _w(nz, "per_max_g") * g_ex \
		+ _w(nz, "per_turn") * profile.turns
	return {"excitement": _r(exc), "intensity": _r(inten), "nausea": _r(naus)}


static func _w(d: Dictionary, k: String, fallback: float = 0.0) -> float:
	return float(d.get(k, fallback))


static func _r(x: float) -> float:
	return snappedf(clampf(x, 0.0, 10.0), 0.01)
