class_name StaffVisual
extends Node3D
## Personale-figur. Samme rod-API som GuestVisual (set_color, set_walking, play_emote) + hop.

@export var bob_height: float = 0.05
@export var bob_speed: float = 10.0

var walking: bool = false
var _anim: PersonAnim
@onready var _figure: Node3D = $Figure


func _ready() -> void:
	_anim = PersonAnim.new(self, [_figure] as Array[Node3D])
	_anim.bob_height = bob_height
	_anim.bob_speed = bob_speed
	set_process(false)


func set_color(c: Color) -> void:
	var body: MeshInstance3D = get_node("Figure/Body")
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.8
	body.material_override = mat


func set_walking(on: bool) -> void:
	walking = on
	if _anim == null or _anim.walking == on:
		return
	_anim.set_walking(on)
	set_process(not _anim.is_idle())


func play_emote(kind: StringName) -> void:
	if _anim == null:
		return
	_anim.play_emote(kind)
	set_process(not _anim.is_idle())


## Lille enkelt-hop (fx når en opgave er løst).
func hop() -> void:
	play_emote(&"happy")


func _process(delta: float) -> void:
	_anim.step(delta)
	if _anim.is_idle():
		set_process(false)
