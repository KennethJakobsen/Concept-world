class_name LockOverlay
extends RefCounted
## Gør en byggeknap låst: deaktiveret, hængelås og tooltip "Kræver forskning".
## Byggekort (BuildDock) får kort-udgaven: desatureret miniature, lås i midten, "Forskning".

const LOCK_NAME: String = "Lock"


static func apply(b: Button, locked: bool, reason: String = "") -> void:
	if b.has_meta(BuildDock.META_CARD):
		BuildDock.apply_card_lock(b, locked)
	else:
		var lock: Control = b.get_node_or_null(LOCK_NAME) as Control
		if locked and lock == null:
			lock = UiTheme.icon_rect("lock", 16.0)
			lock.name = LOCK_NAME
			b.add_child(lock)
		if lock != null:
			lock.visible = locked
			lock.position = Vector2(maxf(0.0, b.size.x - 18.0), 2.0)
		b.self_modulate = Color(0.6, 0.58, 0.55) if locked else Color(1, 1, 1)
	b.tooltip_text = (reason if reason != "" else M5Texts.LOCKED_TOOLTIP) if locked else TooltipService.text_for(b)
	if locked:
		b.disabled = true


static func is_locked(b: Button) -> bool:
	var lock: Node = b.get_node_or_null(LOCK_NAME)
	return lock != null and (lock as CanvasItem).visible


## T-134: låsetekst for en sporbane, hvis stykker mangler forskning ("" = ikke låst af stykker).
## "Kræver forskning: <emne> – <stykker>" (GDD T-131).
static func track_lock_text(sim: ParkSim, def_id: String) -> String:
	if sim == null or not sim.has_method("missing_pieces"):
		return ""
	var def: AttractionDef = sim.get_def(def_id)
	if def == null or not def.is_tracked():
		return ""
	var missing: Array[String] = sim.missing_pieces(def_id)
	if missing.is_empty():
		return ""
	var topics: Array[String] = []
	var names: Array[String] = []
	for pid: String in missing:
		var p: TrackPieceDef = CoasterContent.piece(pid)
		names.append(p.name if p != null else pid)
		var t: String = _topic_name(sim, pid)
		if t != "" and not topics.has(t):
			topics.append(t)
	return "Kræver forskning: %s – %s" % [", ".join(topics), ", ".join(names)]


static func _topic_name(sim: ParkSim, item_id: String) -> String:
	if sim.research == null or sim.research.def == null:
		return ""
	var rd: ResearchDef = sim.research.def
	var tid: String = str(rd.item(item_id).get("topic", ""))
	for t: Dictionary in rd.topics:
		if str(t.get("id", "")) == tid or (tid == "" and (t.get("unlocks", []) as Array).has(item_id)):
			return str(t.get("name", ""))
	return ""
