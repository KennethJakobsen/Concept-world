class_name BuildDock
extends PanelContainer
## Byggedok (T-101, restylet T-138 efter docs/ui-style.md §6.1): en træbjælke nederst i midten med
## værktøjs-medaljoner (Vælg/Fjern) og 6 kategori-medaljoner (kun ikoner). Over bjælken et
## papirpanel med billedkort (miniature + navn + pris) for den valgte kategori, med sideskift.
## Noden hedder "BuildMenu" af hensyn til eksisterende tests/integration.

signal category_selected(cat: String)
signal card_pressed(id: String)
signal layout_changed  ## T-141: kortpanelet åbnet/lukket -> Hud skal genplacere docken

const CATEGORIES: Array[String] = ["paths", "rides", "shops", "decor", "staff", "coaster"]
const CATEGORY_NAMES: Dictionary = {"paths": "Stier", "rides": "Forlystelser", "shops": "Butikker",
	"decor": "Pynt", "staff": "Personale", "coaster": "Rutsjebane"}
const CARD_SIZE: Vector2 = Vector2(120, 150)
const CARD_GAP: int = 8
const MAX_COLS: int = 7
const CAT_PX: float = 60.0
const TOOL_PX: float = 48.0
const META_CARD: StringName = &"card"
const META_PRICE: StringName = &"price"

var current: String = "rides"
var cards: Dictionary = {}       ## id -> Button (kort og værktøjer)
var card_cat: Dictionary = {}    ## id -> kategori ("" = værktøj, altid synlig)
var cat_buttons: Dictionary = {} ## kategori -> Button
var columns: int = MAX_COLS
var rows: int = 1
var page: int = 0
var selected_id: String = ""

var card_panel: PanelContainer
var bar: PanelContainer
var _grid: GridContainer
var _title: Label
var _page_label: Label
var _prev: Button
var _next: Button
var _tools: HBoxContainer
var _cats: HBoxContainer


func build() -> void:
	name = "BuildMenu"
	theme_type_variation = &"DockRoot"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.name = "V"
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(v)
	# Kortpanel.
	card_panel = PanelContainer.new()
	card_panel.name = "Cards"
	card_panel.theme_type_variation = &"PanelPaper"
	card_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	card_panel.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	v.add_child(card_panel)
	var cv := VBoxContainer.new()
	card_panel.add_child(cv)
	var head := HBoxContainer.new()
	head.name = "Head"
	cv.add_child(head)
	_title = Label.new()
	_title.name = "Title"
	_title.add_theme_font_size_override("font_size", 16)
	_title.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	head.add_child(_title)
	_prev = UiTheme.medallion("arrow_left", 28.0)
	_prev.name = "Prev"
	TooltipService.attach(_prev, "Forrige side")
	_prev.pressed.connect(func() -> void: set_page(page - 1))
	head.add_child(_prev)
	_page_label = Label.new()
	_page_label.name = "Page"
	head.add_child(_page_label)
	_next = UiTheme.medallion("arrow_right", 28.0)
	_next.name = "Next"
	TooltipService.attach(_next, "Næste side")
	_next.pressed.connect(func() -> void: set_page(page + 1))
	head.add_child(_next)
	_grid = GridContainer.new()
	_grid.name = "Grid"
	_grid.columns = columns
	_grid.add_theme_constant_override("h_separation", CARD_GAP)
	_grid.add_theme_constant_override("v_separation", CARD_GAP)
	cv.add_child(_grid)
	# Træbjælke.
	bar = PanelContainer.new()
	bar.name = "Bar"
	bar.theme_type_variation = &"PanelWood"
	bar.mouse_filter = Control.MOUSE_FILTER_STOP
	bar.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 6)
	gap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(gap)
	v.add_child(bar)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	bar.add_child(h)
	_tools = HBoxContainer.new()
	_tools.name = "Tools"
	_tools.alignment = BoxContainer.ALIGNMENT_CENTER
	_tools.add_theme_constant_override("separation", 8)
	h.add_child(_tools)
	h.add_child(VSeparator.new())
	_cats = HBoxContainer.new()
	_cats.name = "Categories"
	_cats.add_theme_constant_override("separation", 8)
	h.add_child(_cats)
	card_panel.visible = false


func add_category(cat: String) -> Button:
	var b: Button = UiTheme.medallion("cat_" + cat, CAT_PX, UiTheme.CATEGORY_COLORS.get(cat, UiTheme.BRASS))
	b.name = "Tab_" + cat
	b.toggle_mode = true
	TooltipService.attach(b, CATEGORY_NAMES.get(cat, cat),
		"Tast %d. Vis kort i kategorien" % (CATEGORIES.find(cat) + 1))
	b.pressed.connect(_on_category.bind(cat))
	_cats.add_child(b)
	cat_buttons[cat] = b
	return b


func _on_category(cat: String) -> void:
	if cat == current and cards_open():
		close_cards()
		return
	category_selected.emit(cat)


## Kort (eller værktøjs-medaljon, hvis cat == ""). Returnerer knappen.
func add_card(id: String, title: String, cost_text: String, cat: String, tip_body: String = "") -> Button:
	var b: Button
	if cat == "":
		b = UiTheme.medallion("tool_" + id, TOOL_PX, UiTheme.RED if id == "remove" else UiTheme.BRASS)
		b.toggle_mode = true
		_tools.add_child(b)
	else:
		b = _make_card(id, title, cost_text, cat)
		_grid.add_child(b)
	b.name = "Card_" + id.replace(":", "_")
	b.set_meta(META_PRICE, cost_text)
	TooltipService.attach(b, title, tip_body)
	b.pressed.connect(_on_card.bind(id))
	cards[id] = b
	card_cat[id] = cat
	return b


func _make_card(id: String, title: String, cost_text: String, cat: String) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"Card"
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.toggle_mode = true
	b.custom_minimum_size = CARD_SIZE
	b.set_meta(META_CARD, true)
	var content := VBoxContainer.new()
	content.name = "Content"
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.set_anchors_preset(Control.PRESET_FULL_RECT)
	content.offset_left = 4
	content.offset_right = -4
	content.offset_top = 4
	content.offset_bottom = -4
	content.add_theme_constant_override("separation", 2)
	b.add_child(content)
	var band := ColorRect.new()
	band.name = "Band"
	band.color = UiTheme.CATEGORY_COLORS.get(cat, UiTheme.BRASS)
	band.custom_minimum_size = Vector2(0, 4)
	band.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(band)
	var thumb := TextureRect.new()
	thumb.name = "Thumb"
	thumb.texture = UiTheme.thumb(id, cat)
	thumb.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	thumb.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	thumb.custom_minimum_size = Vector2(112, 84)
	thumb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(thumb)
	var name_l := Label.new()
	name_l.name = "Name"
	name_l.theme_type_variation = &"CardName"
	name_l.text = title
	name_l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_l.clip_text = true
	name_l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_l.custom_minimum_size = Vector2(104, 0)
	content.add_child(name_l)
	var pr := HBoxContainer.new()
	pr.name = "PriceRow"
	pr.alignment = BoxContainer.ALIGNMENT_CENTER
	pr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(pr)
	pr.add_child(UiTheme.icon_rect("coin", 14.0))
	var price := Label.new()
	price.name = "Price"
	price.theme_type_variation = &"CardPrice"
	price.text = cost_text
	pr.add_child(price)
	var check: TextureRect = UiTheme.icon_rect("check", 20.0)
	check.name = "Check"
	check.position = Vector2(CARD_SIZE.x - 24, 6)
	check.visible = false
	b.add_child(check)
	b.mouse_entered.connect(_lift.bind(content, -3.0))
	b.mouse_exited.connect(_lift.bind(content, 0.0))
	return b


func _lift(c: Control, dy: float) -> void:
	if not c.is_inside_tree():
		return
	var tw: Tween = c.create_tween()
	tw.tween_property(c, "position:y", 4.0 + dy, 0.08)


func _on_card(id: String) -> void:
	set_selected(id)
	card_pressed.emit(id)


## Markerer det aktive kort/værktøj (messingkant + flueben).
func set_selected(id: String) -> void:
	selected_id = id
	for k: String in cards:
		var b: Button = cards[k]
		b.set_pressed_no_signal(k == id)
		var chk: Node = b.get_node_or_null("Check")
		if chk != null:
			(chk as CanvasItem).visible = k == id


func set_category(cat: String) -> void:
	current = cat
	page = 0
	card_panel.visible = true
	_title.text = CATEGORY_NAMES.get(cat, cat)
	for c: String in cat_buttons:
		(cat_buttons[c] as Button).set_pressed_no_signal(c == cat)
	_apply_page()


## Dockens aktuelle minimumsstørrelse beregnet fra de synlige dele (T-141). Bruges af Hud.layout i
## stedet for den cachede get_combined_minimum_size(), som kan være forældet i samme frame som
## kortpanelet skjules/vises – det fik docken til at blive hængende, hvor panelet havde været.
func dock_size() -> Vector2:
	var out := Vector2.ZERO
	for c: Node in get_node("V").get_children():
		var ctl := c as Control
		if ctl == null or not ctl.visible:
			continue
		var m: Vector2 = ctl.get_combined_minimum_size()
		out.x = maxf(out.x, m.x)
		out.y += m.y
	var sb: StyleBox = get_theme_stylebox("panel")
	if sb != null:
		out += sb.get_minimum_size()
	return out


func cards_open() -> bool:
	return card_panel != null and card_panel.visible


func close_cards() -> void:
	card_panel.visible = false
	for c: String in cat_buttons:
		(cat_buttons[c] as Button).set_pressed_no_signal(false)
	layout_changed.emit()


## Antal kolonner/rækker (sat af Hud.layout ud fra vinduesstørrelsen).
func set_grid(cols: int, p_rows: int) -> void:
	cols = clampi(cols, 2, MAX_COLS)
	if cols == columns and p_rows == rows:
		return
	columns = cols
	rows = maxi(1, p_rows)
	_grid.columns = columns
	_apply_page()


func per_page() -> int:
	return columns * rows


func page_count() -> int:
	return maxi(1, ceili(float(category_ids(current).size()) / float(per_page())))


func set_page(p: int) -> void:
	page = clampi(p, 0, page_count() - 1)
	_apply_page()


## Kort i kategorien (uden værktøjer), i rækkefølge.
func category_ids(cat: String) -> Array[String]:
	var out: Array[String] = []
	for id: String in cards:
		if card_cat[id] == cat:
			out.append(id)
	return out


func _apply_page() -> void:
	var ids: Array[String] = category_ids(current)
	page = clampi(page, 0, page_count() - 1)
	var first: int = page * per_page()
	for id: String in cards:
		if card_cat[id] == "":
			continue
		var i: int = ids.find(id)
		(cards[id] as Button).visible = i >= first and i < first + per_page()
	var multi: bool = page_count() > 1
	_prev.visible = multi
	_next.visible = multi
	_page_label.visible = multi
	_page_label.text = "%d/%d" % [page + 1, page_count()]
	_prev.disabled = page == 0
	_next.disabled = page >= page_count() - 1


## Id'er i den valgte kategori + værktøjer (uafhængigt af sideskift).
func visible_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in cards:
		var c: String = card_cat[id]
		if c == "" or c == current:
			out.append(id)
	return out


## Pris i rødt, hvis man ikke har råd.
func set_affordable(id: String, ok: bool) -> void:
	var b: Button = cards.get(id)
	if b == null or not b.has_meta(META_CARD):
		return
	var price: Label = b.get_node("Content/PriceRow/Price")
	if not LockOverlay.is_locked(b):
		price.add_theme_color_override("font_color", UiTheme.INK if ok else UiTheme.RED)


static func price_text(b: Button) -> String:
	return str(b.get_meta(META_PRICE, ""))


## Låst kort (T-138 §6.1): desatureret, hængelås i midten, "Forskning" i stedet for pris.
static func apply_card_lock(b: Button, locked: bool) -> void:
	var content: Control = b.get_node("Content")
	content.modulate = Color(UiTheme.LOCKED, 0.9) if locked else Color(1, 1, 1)
	var price: Label = b.get_node("Content/PriceRow/Price")
	price.text = "Forskning" if locked else price_text(b)
	if locked:
		price.add_theme_color_override("font_color", UiTheme.INK)
	var lock: Control = b.get_node_or_null(LockOverlay.LOCK_NAME)
	if locked and lock == null:
		lock = UiTheme.icon_rect("lock", 28.0)
		lock.name = LockOverlay.LOCK_NAME
		lock.position = Vector2((CARD_SIZE.x - 28.0) * 0.5, 34.0)
		b.add_child(lock)
	if lock != null:
		lock.visible = locked
