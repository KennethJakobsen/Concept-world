class_name TutorialHighlight
extends Control
## T-116: pulserende messingramme om den UI-knap, tutorial-trinnet peger på.
## Nøgler: build:<def>, overlay:<kind>, staff:<type>. Andre nøgler (entrance, attraction:<kind>)
## er verdens-highlights (gameplay) og tegnes ikke her. Fanger aldrig musen.

var target_key: String = ""
var dock: BuildDock
var rail: ParkRail
var picker_provider: Callable  ## () -> OverlayPicker (kan være null)
var _t: float = 0.0
var _rect: Rect2 = Rect2()


func _init() -> void:
	name = "TutorialHighlight"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	top_level = true


## Den knap, der skal fremhæves lige nu (falder tilbage til kategori/rail-knap, hvis kortet
## eller vælgeren ikke er åben).
func target() -> Control:
	var parts: PackedStringArray = target_key.split(":", true, 1)
	if parts.size() != 2:
		return null
	var kind: String = parts[0]
	var id: String = parts[1]
	match kind:
		"build", "staff":
			if dock == null:
				return null
			var card_id: String = id if kind == "build" else "staff:" + id
			var card: Control = dock.cards.get(card_id) as Control
			if card != null and card.is_visible_in_tree():
				return card
			var cat: String = str(dock.card_cat.get(card_id, "staff" if kind == "staff" else ""))
			return dock.cat_buttons.get(cat) as Control
		"overlay":
			var p: OverlayPicker = picker_provider.call() as OverlayPicker if picker_provider.is_valid() else null
			if p != null and p.is_visible_in_tree() and p.buttons.has(StringName(id)):
				return p.buttons[StringName(id)] as Control
			return rail.button(&"overlays") if rail != null else null
	return null


func _process(delta: float) -> void:
	_t += delta
	var c: Control = target() if target_key != "" else null
	var r: Rect2 = c.get_global_rect().grow(4.0) if c != null and c.is_visible_in_tree() else Rect2()
	visible = r.size != Vector2.ZERO
	if r != _rect:
		_rect = r
		position = r.position
		size = r.size
	queue_redraw()


func _draw() -> void:
	if _rect.size == Vector2.ZERO:
		return
	var a: float = 0.55 + 0.45 * sin(_t * 5.0)
	var col := UiTheme.BRASS_LIGHT
	col.a = a
	draw_rect(Rect2(Vector2.ZERO, size), col, false, 4.0)
	draw_rect(Rect2(Vector2(-2, -2), size + Vector2(4, 4)), Color(UiTheme.OUTLINE, a * 0.6), false, 2.0)
