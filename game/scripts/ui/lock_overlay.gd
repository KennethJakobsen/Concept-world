class_name LockOverlay
extends RefCounted
## Gør en byggeknap låst: grå, deaktiveret, tegnet hængelås og tooltip "Kræver forskning".

const LOCK_NAME: String = "Lock"


static func apply(b: Button, locked: bool) -> void:
	var lock: UiIcons = b.get_node_or_null(LOCK_NAME) as UiIcons
	if locked and lock == null:
		lock = UiIcons.new("lock", 14.0)
		lock.name = LOCK_NAME
		lock.color = Color(1.0, 0.85, 0.3)
		b.add_child(lock)
	if lock != null:
		lock.visible = locked
		lock.position = Vector2(maxf(0.0, b.size.x - 16.0), 2.0)
	b.tooltip_text = M5Texts.LOCKED_TOOLTIP if locked else TooltipService.text_for(b)
	b.self_modulate = Color(0.55, 0.55, 0.55) if locked else Color(1, 1, 1)
	if locked:
		b.disabled = true


static func is_locked(b: Button) -> bool:
	var lock: Node = b.get_node_or_null(LOCK_NAME)
	return lock != null and (lock as CanvasItem).visible
