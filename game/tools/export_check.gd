extends SceneTree
## T-072: kører mod den eksporterede pck (Web-presetets filtre) og tjekker, at
## ScenarioDef.list_all() finder scenarierne via DirAccess i pakken.

func _init() -> void:
	var defs: Array[ScenarioDef] = ScenarioDef.list_all()
	var ids: Array[String] = []
	var last: int = -999999
	var sorted_ok: bool = true
	for d in defs:
		ids.append(d.id)
		sorted_ok = sorted_ok and d.order >= last
		last = d.order
	print("export_check: scenarier i pck: %s" % [ids])
	var ok: bool = defs.size() >= 4 and ids.has("sandbox") and sorted_ok
	print("export_check: %s" % ("OK" if ok else "FEJL"))
	quit(0 if ok else 1)
