class_name UiSound
extends RefCounted
## Fælles klik-lyd: alle Buttons, der kommer ind i scenetræet, får play_ui(&"click") via AudioManager.
## Installeres én gang pr. SceneTree (node_added); tåler at AudioManager mangler (headless/tests).

const META: StringName = &"_ui_click_wired"


static func audio_manager() -> Node:
	var tree := Engine.get_main_loop() as SceneTree
	if tree == null or tree.root == null:
		return null
	return tree.root.get_node_or_null("AudioManager")


static func play(id: StringName = &"click") -> void:
	var am: Node = audio_manager()
	if am != null and am.has_method("play_ui"):
		am.call("play_ui", id)


static func install(tree: SceneTree) -> void:
	if tree == null:
		return
	if not tree.node_added.is_connected(_on_node_added):
		tree.node_added.connect(_on_node_added)
	if tree.root != null:
		wire(tree.root)


## Forbinder klik-lyd på n og alle under-noder (idempotent).
static func wire(n: Node) -> void:
	_on_node_added(n)
	for c: Node in n.get_children():
		wire(c)


static func is_wired(b: BaseButton) -> bool:
	return b.has_meta(META)


static func _on_node_added(n: Node) -> void:
	var b := n as BaseButton
	if b == null or b.has_meta(META):
		return
	b.set_meta(META, true)
	b.pressed.connect(_click)
	if b is CheckBox or b is CheckButton:
		return
	# (toggle-knapper udsender også pressed)


static func _click() -> void:
	play(&"click")
