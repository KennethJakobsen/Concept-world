class_name GuestVisual
extends Node3D
## Placeholder-gaest. Farve saettes via set_color(). Gå-cyklus/emotes via PersonAnim
## (ingen AnimationPlayer; processing kun aktiv mens der animeres).

@onready var _body: MeshInstance3D = $Body
var _anim: PersonAnim


func _ready() -> void:
	if _body.material_override == null:
		set_color(Color.from_hsv(randf(), 0.55, 0.9))
	_anim = PersonAnim.new(self, [$Body as Node3D, $Head as Node3D] as Array[Node3D])
	_anim.bob_height = 0.06
	_anim.bob_speed = 11.0 + randf() * 2.0
	set_process(false)


func set_color(c: Color) -> void:
	if _body == null:
		_body = $Body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.roughness = 0.8
	_body.material_override = mat


## T-087: Viser baerbare ting (balloon, souvenir, prize_*). Tom liste fjerner alt.
func set_items(items: Array[StringName]) -> void:
	var iv := get_node_or_null("Items") as CarriedItemsVisual
	if iv == null:
		if items.is_empty():
			return
		iv = CarriedItemsVisual.new()
		iv.name = "Items"
		add_child(iv)
	iv.set_items(items)


func get_items() -> Array[StringName]:
	var iv := get_node_or_null("Items") as CarriedItemsVisual
	return iv.items() if iv != null else ([] as Array[StringName])


func set_walking(on: bool) -> void:
	if _anim == null or _anim.walking == on:
		return
	_anim.set_walking(on)
	set_process(not _anim.is_idle())


func play_emote(kind: StringName) -> void:
	if _anim == null:
		return
	_anim.play_emote(kind)
	set_process(not _anim.is_idle())


func _process(delta: float) -> void:
	_anim.step(delta)
	if _anim.is_idle():
		set_process(false)
