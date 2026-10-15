class_name LitterVisual
extends Node3D
## Affaldsbunke. set_level(0) skjuler, 1-3 viser stigende mængde.

var level: int = 0


func _ready() -> void:
	set_level(level)


func set_level(n: int) -> void:
	level = clampi(n, 0, 3)
	visible = level > 0
	for i in 3:
		var p := get_node_or_null("L%d" % (i + 1)) as Node3D
		if p:
			p.visible = i < level
