class_name ThoughtBubble
extends Node3D
## Lille tankeboble over en gæst. Billboard-quad + Label3D (Compatibility-venlig).

@onready var _label: Label3D = $Label
@onready var _bg: MeshInstance3D = $Background


func _ready() -> void:
	visible = false


func show_text(t: String) -> void:
	if not is_node_ready():
		await ready
	_label.text = t
	var w: float = maxf(0.4, 0.09 * t.length() + 0.2)
	_bg.scale = Vector3(w / 0.6, 1.0, 1.0)
	visible = true


func hide_bubble() -> void:
	visible = false
