class_name UiTheme
extends RefCounted
## Fælles UI-tema "Tivoli-skilt" (T-138, docs/ui-style.md). Palet, StyleBoxes og type-variationer
## bygges her og gemmes som ét Theme-resource (`THEME_PATH`), som alle UI-scener bruger.
## Regenerér resourcen med: godot --headless --script res://scripts/ui/ui_theme_export.gd
##
## Type-variationer (sæt `theme_type_variation`):
##   PanelWood / PanelPaper / SignWood / DockRoot (PanelContainer), WoodLabel / TitleLabel /
##   CardName / CardPrice (Label), Medallion / Card / Tab / AlertNote / BigButton (Button).

const THEME_PATH: String = "res://scenes/ui/theme/concept_theme.tres"
const ICON_DIR: String = "res://assets/ui/icons/"
const THUMB_DIR: String = "res://assets/ui/thumbs/"

const WOOD_DARK := Color("#5A3A22")
const WOOD_MID := Color("#7A4E2D")
const WOOD_LIGHT := Color("#9C6A3F")
const PAPER := Color("#F6EBD3")
const PAPER_SHADE := Color("#E6D5B0")
const PAPER_EDGE := Color("#C9B58C")
const BRASS := Color("#D9A441")
const BRASS_LIGHT := Color("#F2C96B")
const INK := Color("#3B2A1E")
const CREAM := Color("#FFF4DC")
const RED := Color("#C8452F")
const GREEN := Color("#4F9A3A")
const TEAL := Color("#2F8C8C")
const LOCKED := Color("#8A8174")
const OUTLINE := Color("#2A1A0E")
const SHADOW := Color(0, 0, 0, 0.35)

const CATEGORY_COLORS: Dictionary = {"paths": Color("#B08A5A"), "rides": Color("#D9534F"),
	"shops": Color("#E8A33D"), "decor": Color("#5BA05B"), "staff": Color("#3F7CBF"),
	"coaster": Color("#8E5BB5")}

static var _theme: Theme


## Det fælles tema (resourcen, hvis den findes, ellers bygget i kode).
static func get_theme() -> Theme:
	if _theme == null:
		if ResourceLoader.exists(THEME_PATH):
			_theme = load(THEME_PATH) as Theme
		if _theme == null:
			_theme = build()
	return _theme


static func icon(id: String, big: bool = false) -> Texture2D:
	var p: String = ICON_DIR + ("128/" if big else "") + id + ".png"
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	return null


## Miniature for et kort-id ("carousel", "decor:bench", "staff:mechanic", "coaster:x").
## Mangler den, returneres kategori-ikonet (fallback).
static func thumb(card_id: String, cat: String) -> Texture2D:
	var base: String = card_id.get_slice(":", 1) if card_id.contains(":") else card_id
	var p: String = THUMB_DIR + base + ".png"
	if ResourceLoader.exists(p):
		return load(p) as Texture2D
	return icon("cat_" + cat, true)


static func box(bg: Color, border: Color = Color.TRANSPARENT, bw: int = 0, radius: int = 8,
		shadow: int = 0, margin: float = 8.0) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(radius)
	s.shadow_size = shadow
	s.shadow_color = SHADOW
	s.shadow_offset = Vector2(0, shadow * 0.5)
	s.set_content_margin_all(margin)
	s.anti_aliasing = true
	return s


static func _button_boxes(t: Theme, type: String, normal: StyleBox, hover: StyleBox,
		pressed: StyleBox, disabled: StyleBox) -> void:
	t.set_stylebox("normal", type, normal)
	t.set_stylebox("hover", type, hover)
	t.set_stylebox("pressed", type, pressed)
	t.set_stylebox("hover_pressed", type, pressed)
	t.set_stylebox("disabled", type, disabled)
	t.set_stylebox("focus", type, StyleBoxEmpty.new())


static func build() -> Theme:
	var t := Theme.new()
	t.default_font_size = 14
	# Paneler: papir som standard, træ som variation.
	var paper := box(PAPER, PAPER_EDGE, 2, 8, 4, 12.0)
	var wood := box(WOOD_DARK, BRASS, 3, 10, 6, 10.0)
	t.set_stylebox("panel", "PanelContainer", paper)
	t.set_stylebox("panel", "Panel", paper)
	for v: String in ["PanelWood", "PanelPaper", "SignWood", "DockRoot", "RailWood"]:
		t.set_type_variation(v, "PanelContainer")
	t.set_stylebox("panel", "PanelWood", wood)
	t.set_stylebox("panel", "PanelPaper", paper)
	var sign := box(WOOD_MID, BRASS, 2, 8, 3, 6.0)
	sign.content_margin_left = 12.0
	sign.content_margin_right = 12.0
	t.set_stylebox("panel", "SignWood", sign)
	t.set_stylebox("panel", "DockRoot", StyleBoxEmpty.new())
	var rail := box(WOOD_DARK, BRASS, 3, 10, 6, 8.0)
	rail.corner_radius_top_left = 0
	rail.corner_radius_bottom_left = 0
	t.set_stylebox("panel", "RailWood", rail)
	# Tekst: blæk på papir; WoodLabel = creme med outline.
	t.set_color("font_color", "Label", INK)
	for v: String in ["WoodLabel", "TitleLabel", "CardName", "CardPrice"]:
		t.set_type_variation(v, "Label")
	t.set_color("font_color", "WoodLabel", CREAM)
	t.set_color("font_outline_color", "WoodLabel", OUTLINE)
	t.set_constant("outline_size", "WoodLabel", 2)
	t.set_color("font_color", "TitleLabel", CREAM)
	t.set_color("font_outline_color", "TitleLabel", OUTLINE)
	t.set_constant("outline_size", "TitleLabel", 3)
	t.set_font_size("font_size", "TitleLabel", 18)
	t.set_font_size("font_size", "CardName", 13)
	t.set_font_size("font_size", "CardPrice", 13)
	# Knapper: træ.
	var bn := box(WOOD_MID, Color("#3F2816"), 2, 8, 2, 8.0)
	bn.border_width_bottom = 4
	var bh := box(WOOD_LIGHT, BRASS_LIGHT, 2, 8, 3, 8.0)
	bh.border_width_bottom = 4
	var bp := box(WOOD_DARK, BRASS, 2, 8, 0, 8.0)
	bp.border_width_top = 4
	var bd := box(Color("#6E5E50"), Color("#4E4339"), 2, 8, 0, 8.0)
	for s: StyleBoxFlat in [bn, bh, bp, bd]:
		s.content_margin_top = 6.0
		s.content_margin_bottom = 6.0
	_button_boxes(t, "Button", bn, bh, bp, bd)
	for c: String in ["font_color", "font_hover_color", "font_focus_color", "font_hover_pressed_color"]:
		t.set_color(c, "Button", CREAM)
	t.set_color("font_pressed_color", "Button", BRASS_LIGHT)
	t.set_color("font_disabled_color", "Button", Color("#C9BBA8"))
	t.set_color("font_outline_color", "Button", OUTLINE)
	t.set_constant("outline_size", "Button", 2)
	t.set_constant("h_separation", "Button", 8)
	t.set_constant("icon_max_width", "Button", 24)
	# Hovedmenu-knap: større tekst.
	t.set_type_variation("BigButton", "Button")
	t.set_font_size("font_size", "BigButton", 18)
	# Medaljon (rund ikonknap).
	t.set_type_variation("Medallion", "Button")
	var mn := box(WOOD_MID, BRASS, 3, 30, 4, 6.0)
	var mh := box(WOOD_LIGHT, BRASS_LIGHT, 3, 30, 4, 6.0)
	var mp := box(WOOD_DARK, BRASS_LIGHT, 4, 30, 2, 6.0)
	var md := box(Color("#6E5E50"), Color("#4E4339"), 3, 30, 0, 6.0)
	_button_boxes(t, "Medallion", mn, mh, mp, md)
	t.set_constant("icon_max_width", "Medallion", 40)
	# Kort.
	t.set_type_variation("Card", "Button")
	var cn := box(PAPER, PAPER_EDGE, 2, 8, 3, 6.0)
	var ch := box(Color("#FFF8E6"), BRASS_LIGHT, 2, 8, 6, 6.0)
	var cs := box(PAPER, BRASS, 3, 8, 6, 6.0)
	cs.shadow_color = Color(BRASS, 0.6)
	cs.shadow_offset = Vector2.ZERO
	_button_boxes(t, "Card", cn, ch, cs, cn.duplicate())
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_disabled_color"]:
		t.set_color(c, "Card", INK)
	t.set_constant("outline_size", "Card", 0)
	# Faneblade.
	t.set_type_variation("Tab", "Button")
	var tn := box(WOOD_MID, Color.TRANSPARENT, 0, 8, 0, 6.0)
	tn.corner_radius_bottom_left = 0
	tn.corner_radius_bottom_right = 0
	tn.content_margin_left = 10.0
	tn.content_margin_right = 10.0
	tn.content_margin_top = 4.0
	tn.content_margin_bottom = 4.0
	var th := tn.duplicate() as StyleBoxFlat
	th.bg_color = WOOD_LIGHT
	var ts := tn.duplicate() as StyleBoxFlat
	ts.bg_color = PAPER_SHADE
	ts.border_color = PAPER_EDGE
	ts.set_border_width_all(2)
	ts.border_width_bottom = 0
	_button_boxes(t, "Tab", tn, th, ts, tn.duplicate())
	t.set_color("font_pressed_color", "Tab", INK)
	t.set_color("font_hover_pressed_color", "Tab", INK)
	t.set_constant("icon_max_width", "Tab", 20)
	# Varsel-seddel.
	t.set_type_variation("AlertNote", "Button")
	var an := box(PAPER, PAPER_EDGE, 2, 6, 3, 6.0)
	an.border_width_left = 6
	an.border_color = TEAL
	var ah := an.duplicate() as StyleBoxFlat
	ah.bg_color = Color("#FFF8E6")
	_button_boxes(t, "AlertNote", an, ah, ah, an)
	for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
		t.set_color(c, "AlertNote", INK)
	t.set_constant("outline_size", "AlertNote", 0)
	t.set_font_size("font_size", "AlertNote", 13)
	t.set_constant("icon_max_width", "AlertNote", 28)
	# Tjekbokse og lignende står på papir.
	for ty: String in ["CheckBox", "CheckButton"]:
		var e := StyleBoxEmpty.new()
		_button_boxes(t, ty, e, e, e, e)
		for c: String in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color"]:
			t.set_color(c, ty, INK)
		t.set_constant("outline_size", ty, 0)
	# Tekstfelter.
	var le := box(Color("#FFFBF0"), PAPER_EDGE, 2, 6, 0, 6.0)
	t.set_stylebox("normal", "LineEdit", le)
	var lf := le.duplicate() as StyleBoxFlat
	lf.border_color = BRASS
	t.set_stylebox("focus", "LineEdit", lf)
	t.set_color("font_color", "LineEdit", INK)
	t.set_color("font_placeholder_color", "LineEdit", Color(INK, 0.5))
	t.set_color("caret_color", "LineEdit", INK)
	# Bjælker.
	t.set_stylebox("background", "ProgressBar", box(PAPER_SHADE, PAPER_EDGE, 1, 4, 0, 0.0))
	t.set_stylebox("fill", "ProgressBar", box(GREEN, Color.TRANSPARENT, 0, 4, 0, 0.0))
	t.set_color("font_color", "ProgressBar", INK)
	t.set_stylebox("slider", "HSlider", box(PAPER_SHADE, PAPER_EDGE, 1, 4, 0, 2.0))
	# Tooltip.
	var tip := box(Color(INK, 0.95), BRASS, 2, 6, 4, 8.0)
	t.set_stylebox("panel", "TooltipPanel", tip)
	t.set_color("font_color", "TooltipLabel", CREAM)
	t.set_font_size("font_size", "TooltipLabel", 13)
	# Separatorer.
	var sep := StyleBoxLine.new()
	sep.color = BRASS
	sep.thickness = 2
	sep.vertical = true
	t.set_stylebox("separator", "VSeparator", sep)
	t.set_constant("separation", "VSeparator", 10)
	var hsep := StyleBoxLine.new()
	hsep.color = PAPER_EDGE
	hsep.thickness = 2
	t.set_stylebox("separator", "HSeparator", hsep)
	return t


## Ikon-knap i medaljon-stil.
static func medallion(icon_id: String, px: float, ring: Color = BRASS) -> Button:
	var b := Button.new()
	b.theme_type_variation = &"Medallion"
	b.focus_mode = Control.FOCUS_NONE
	b.mouse_filter = Control.MOUSE_FILTER_STOP
	b.custom_minimum_size = Vector2(px, px)
	b.icon = icon(icon_id, px > 48.0)
	b.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	b.expand_icon = true
	b.add_theme_constant_override("icon_max_width", int(px * 0.66))
	var r: int = int(px * 0.5)
	for st: String in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var base: StyleBox = get_theme().get_stylebox(st, &"Medallion")
		if base is StyleBoxFlat:
			var s := (base as StyleBoxFlat).duplicate() as StyleBoxFlat
			s.set_corner_radius_all(r)
			if st == "normal" and ring != BRASS:
				s.border_color = ring
			b.add_theme_stylebox_override(st, s)
	return b


## Lille ikon som TextureRect.
static func icon_rect(icon_id: String, px: float) -> TextureRect:
	var r := TextureRect.new()
	r.texture = icon(icon_id)
	r.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	r.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	r.custom_minimum_size = Vector2(px, px)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return r


static func money_text(v: int) -> String:
	var s: String = str(absi(v))
	var out: String = ""
	while s.length() > 3:
		out = "." + s.right(3) + out
		s = s.left(s.length() - 3)
	return ("-" if v < 0 else "") + s + out
