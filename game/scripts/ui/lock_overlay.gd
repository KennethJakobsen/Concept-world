class_name LockOverlay
extends RefCounted
## Gør en byggeknap låst: deaktiveret, hængelås og tooltip "Kræver forskning".
## Byggekort (BuildDock) får kort-udgaven: desatureret miniature, lås i midten, "Forskning".

const LOCK_NAME: String = "Lock"


static func apply(b: Button, locked: bool) -> void:
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
	b.tooltip_text = M5Texts.LOCKED_TOOLTIP if locked else TooltipService.text_for(b)
	if locked:
		b.disabled = true


static func is_locked(b: Button) -> bool:
	var lock: Node = b.get_node_or_null(LOCK_NAME)
	return lock != null and (lock as CanvasItem).visible
