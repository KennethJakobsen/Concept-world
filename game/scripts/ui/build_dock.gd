class_name BuildDock
extends PanelContainer
## Bund-dok (T-101, GDD §4): værktøjer (Vælg/Fjern), 6 kategorier og en bakke med kort for den
## valgte kategori. Kort = knap med navn + pris, tooltip med stats og lås, hvis ikke forsket.
## Første barn er en HFlowContainer (Hud.layout beregner højden ud fra ombrydning).
## Noden hedder "BuildMenu" af hensyn til eksisterende tests/integration.

signal category_selected(cat: String)
signal card_pressed(id: String)

const CATEGORIES: Array[String] = ["paths", "rides", "shops", "decor", "staff", "coaster"]
const CATEGORY_NAMES: Dictionary = {"paths": "Stier", "rides": "Forlystelser", "shops": "Butikker",
	"decor": "Pynt", "staff": "Personale", "coaster": "Rutsjebane"}
const CARD_MIN: Vector2 = Vector2(92, 40)

var flow: HFlowContainer
var current: String = "rides"
var cards: Dictionary = {}       ## id -> Button
var card_cat: Dictionary = {}    ## id -> kategori ("" = altid synlig)
var cat_buttons: Dictionary = {} ## kategori -> Button


func build() -> void:
	name = "BuildMenu"
	mouse_filter = Control.MOUSE_FILTER_STOP
	flow = HFlowContainer.new()
	flow.name = "Flow"
	add_child(flow)


func add_category(cat: String) -> Button:
	var b := Button.new()
	b.name = "Tab_" + cat
	b.text = CATEGORY_NAMES.get(cat, cat)
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.add_theme_color_override("font_pressed_color", Color(1.0, 0.9, 0.5))
	TooltipService.attach(b, CATEGORY_NAMES.get(cat, cat), "Vis kort i kategorien")
	b.pressed.connect(func() -> void: category_selected.emit(cat))
	flow.add_child(b)
	cat_buttons[cat] = b
	return b


## Kort (eller værktøjsknap, hvis cat == ""). Returnerer knappen.
func add_card(id: String, title: String, cost_text: String, cat: String, tip_body: String = "") -> Button:
	var b := Button.new()
	b.name = "Card_" + id.replace(":", "_")
	b.text = title if cost_text == "" else "%s\n%s" % [title, cost_text]
	b.clip_text = false
	b.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	if cat != "":
		b.custom_minimum_size = CARD_MIN
	TooltipService.attach(b, title, tip_body)
	b.pressed.connect(func() -> void: card_pressed.emit(id))
	flow.add_child(b)
	cards[id] = b
	card_cat[id] = cat
	return b


func set_category(cat: String) -> void:
	current = cat
	for id: String in cards:
		var c: String = card_cat.get(id, "")
		(cards[id] as Button).visible = c == "" or c == cat
	for c: String in cat_buttons:
		(cat_buttons[c] as Button).set_pressed_no_signal(c == cat)


func visible_ids() -> Array[String]:
	var out: Array[String] = []
	for id: String in cards:
		if (cards[id] as Button).visible:
			out.append(id)
	return out
