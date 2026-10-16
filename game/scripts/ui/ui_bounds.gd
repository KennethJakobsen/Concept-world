class_name UiBounds
extends RefCounted
## T-146: tjek af at rail-paneler (og deres knapper/tekster) ligger inden for viewporten.
## Kræver at HUD'en er i scenetræet (ellers er tekstens minimumsstørrelse 0).
## Bruges af tools/integration_flow.gd ved flere opløsninger/UI-skalaer.

const RAIL_IDS: Array[StringName] = [&"park", &"staff", &"research", &"settings"]


## Returnerer en liste af fejlbeskeder (tom = alt inden for).
static func check_control(root: Control, bounds: Rect2, what: String) -> Array[String]:
	var out: Array[String] = []
	_walk(root, root, bounds, what, out)
	return out


static func _walk(top: Control, n: Control, bounds: Rect2, what: String, out: Array[String]) -> void:
	if not n.is_visible_in_tree():
		return
	if n is Button or n is Label or n == top:
		# Inde i en lodret ScrollContainer kan indholdet rulles frem – der tjekkes kun vandret
		# og kun inden for scroll-feltets synlige område.
		var r: Rect2 = n.get_global_rect()
		var clip: Rect2 = bounds
		var scrolled: bool = false
		var p: Node = n.get_parent()
		while p != null and p != top.get_parent():
			if p is ScrollContainer:
				scrolled = true
			p = p.get_parent()
		var ok: bool = r.position.x >= bounds.position.x - 0.5 and r.end.x <= bounds.end.x + 0.5
		if not scrolled:
			ok = ok and clip.grow(0.5).encloses(r)
		if not ok:
			out.append("%s: %s %s uden for %s" % [what, n.name, r, bounds])
	for c in n.get_children():
		if c is Control:
			_walk(top, c, bounds, what, out)
