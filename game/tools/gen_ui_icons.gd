extends SceneTree
## T-137: Genererer UI-ikonerne (docs/ui-style.md §5 og §8) som egne, procedurelle SVG'er,
## der rasteriseres til PNG i 64 og 128 px.
## Kør: cd game && godot --headless --script res://tools/gen_ui_icons.gd
## Output: res://assets/ui/icons/<id>.png (64) og res://assets/ui/icons/128/<id>.png (128).

const INK := "#3B2A1E"
const BRASS := "#D9A441"
const BRASS_L := "#F2C96B"
const RED := "#C8452F"
const GREEN := "#4F9A3A"
const TEAL := "#2F8C8C"
const CREAM := "#FFF4DC"
const PAPER := "#F6EBD3"
const WOOD := "#7A4E2D"
const WOOD_L := "#9C6A3F"
const GREY := "#8A8174"
const OUT_DIR := "res://assets/ui/icons"


func _init() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT_DIR + "/128"))
	var icons := _icons()
	for id: String in icons:
		var svg := '<svg xmlns="http://www.w3.org/2000/svg" width="64" height="64" viewBox="0 0 64 64">' \
			+ '<g stroke="%s" stroke-width="3" stroke-linejoin="round" stroke-linecap="round">' % INK \
			+ String(icons[id]) + "</g></svg>"
		for size: int in [64, 128]:
			var img := Image.new()
			var err := img.load_svg_from_string(svg, size / 64.0)
			if err != OK:
				push_error("SVG fejlede: " + id)
				continue
			var path := OUT_DIR + ("/%s.png" if size == 64 else "/128/%s.png") % id
			img.save_png(ProjectSettings.globalize_path(path))
	print("gen_ui_icons: %d ikoner" % icons.size())
	quit()


# --- SVG-hjælpere -------------------------------------------------------------

func c(cx: float, cy: float, r: float, fill: String, extra: String = "") -> String:
	return '<circle cx="%s" cy="%s" r="%s" fill="%s" %s/>' % [cx, cy, r, fill, extra]


func el(cx: float, cy: float, rx: float, ry: float, fill: String, extra: String = "") -> String:
	return '<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s" %s/>' % [cx, cy, rx, ry, fill, extra]


func r(x: float, y: float, w: float, h: float, fill: String, rx: float = 2.0, extra: String = "") -> String:
	return '<rect x="%s" y="%s" width="%s" height="%s" rx="%s" fill="%s" %s/>' % [x, y, w, h, rx, fill, extra]


func p(d: String, fill: String, extra: String = "") -> String:
	return '<path d="%s" fill="%s" %s/>' % [d, fill, extra]


func poly(pts: Array, fill: String, extra: String = "") -> String:
	var s := PackedStringArray()
	for i in range(0, pts.size(), 2):
		s.append("%s,%s" % [pts[i], pts[i + 1]])
	return '<polygon points="%s" fill="%s" %s/>' % [" ".join(s), fill, extra]


func ln(x1: float, y1: float, x2: float, y2: float, col: String = INK, w: float = 3.0) -> String:
	return '<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s"/>' % [x1, y1, x2, y2, col, w]


## Tyk, farvet streg med ink-outline (to lag).
func thick(d: String, col: String, w: float) -> String:
	return p(d, "none", 'stroke-width="%s"' % (w + 6)) + p(d, "none", 'stroke="%s" stroke-width="%s"' % [col, w])


func hl(x: float, y: float, rx: float = 4.0, ry: float = 2.5) -> String:
	return el(x, y, rx, ry, "#FFFFFF", 'stroke="none" opacity="0.55"')


func star(cx: float, cy: float, ro: float, ri: float, fill: String, extra: String = "") -> String:
	var pts := []
	for i in 10:
		var a := -PI / 2 + i * PI / 5
		var rr := ro if i % 2 == 0 else ri
		pts.append_array([snappedf(cx + cos(a) * rr, 0.01), snappedf(cy + sin(a) * rr, 0.01)])
	return poly(pts, fill, extra)


func gear(cx: float, cy: float, ro: float, ri: float, teeth: int, fill: String) -> String:
	var pts := []
	var n := teeth * 4
	for i in n:
		var a := TAU * i / n
		var rr := ro if (i % 4 == 1 or i % 4 == 2) else ri
		pts.append_array([snappedf(cx + cos(a) * rr, 0.01), snappedf(cy + sin(a) * rr, 0.01)])
	return poly(pts, fill) + c(cx, cy, ri * 0.38, PAPER)


func tri(cx: float, cy: float, s: float, fill: String) -> String:
	return poly([cx - s * 0.5, cy - s * 0.6, cx + s * 0.6, cy, cx - s * 0.5, cy + s * 0.6], fill)


func face(fill: String, mood: int) -> String:
	var s := c(32, 32, 26, fill) + hl(22, 18, 6, 3.5)
	s += el(23, 27, 3, 4, INK, 'stroke="none"') + el(41, 27, 3, 4, INK, 'stroke="none"')
	var mouth := ["M20,48 Q32,36 44,48", "M21,45 Q32,39 43,45", "M21,43 L43,43", "M21,40 Q32,47 43,40", "M19,38 Q32,54 45,38"]
	s += p(mouth[mood - 1], "none", 'stroke-width="3.5"')
	if mood == 1:
		s += ln(18, 18, 27, 22) + ln(46, 18, 37, 22)
	return s


func head(cap: bool) -> String:
	var s := c(32, 34, 24, "#5FA7A7") + p("M14,54 Q32,38 50,54", "#3F7CBF") + c(32, 30, 11, "#F2C9A0") + hl(27, 25, 3, 2)
	if cap:
		s += p("M20,27 Q32,10 44,27 Z", "#3F7CBF") + r(18, 25, 30, 4, "#3F7CBF", 2) + star(32, 20, 3.5, 1.6, BRASS, 'stroke-width="1"')
	return s


# --- Ikonliste (§8) -------------------------------------------------------------

func _icons() -> Dictionary:
	var d := {}
	# Kategorier
	d["cat_paths"] = poly([6, 46, 22, 36, 38, 44, 22, 56], "#B08A5A") + poly([24, 34, 38, 26, 54, 34, 40, 43], "#C9A877") \
		+ hl(30, 32) + r(46, 12, 4, 24, INK, 1) + r(41, 6, 14, 9, BRASS_L, 3) + c(48, 10, 2, "#FFFFFF", 'stroke="none"')
	d["cat_rides"] = r(14, 36, 36, 18, CREAM, 2) + ln(24, 38, 24, 54) + ln(40, 38, 40, 54) \
		+ poly([32, 10, 56, 38, 8, 38], "#D9534F") + poly([32, 10, 26, 38, 20, 38], "#FFFFFF", 'stroke="none"') \
		+ poly([32, 10, 44, 38, 38, 38], "#FFFFFF", 'stroke="none"') + poly([32, 10, 56, 38, 8, 38], "none") \
		+ ln(32, 10, 32, 3) + poly([32, 3, 42, 6, 32, 9], BRASS, 'stroke-width="2"')
	d["cat_shops"] = r(10, 26, 44, 30, CREAM, 2) + r(20, 33, 24, 16, "#7FC4D8", 1) \
		+ p("M27,40 L32,48 L37,40 Z", "#E8A33D", 'stroke-width="2"') + c(32, 38, 4.5, "#F7B2C4", 'stroke-width="2"') \
		+ p("M8,16 H56 L58,28 Q53,32 48,28 Q43,32 38,28 Q33,32 28,28 Q23,32 18,28 Q13,32 6,28 Z", "#E8A33D") \
		+ r(18, 16, 9, 12, "#FFFFFF", 0, 'stroke="none"') + r(37, 16, 9, 12, "#FFFFFF", 0, 'stroke="none"') \
		+ p("M8,16 H56 L58,28 Q53,32 48,28 Q43,32 38,28 Q33,32 28,28 Q23,32 18,28 Q13,32 6,28 Z", "none")
	d["cat_decor"] = r(22, 36, 7, 20, WOOD, 2) + c(25, 24, 17, "#5BA05B") + hl(18, 15, 5, 3) \
		+ ln(47, 56, 47, 40, GREEN) + c(47, 34, 4, BRASS_L) + c(41, 34, 3.5, "#E87FA0", 'stroke-width="2"') \
		+ c(53, 34, 3.5, "#E87FA0", 'stroke-width="2"') + c(47, 28, 3.5, "#E87FA0", 'stroke-width="2"') + c(47, 40, 3.5, "#E87FA0", 'stroke-width="2"') + c(47, 34, 3.5, BRASS_L, 'stroke-width="2"')
	d["cat_staff"] = p("M10,40 Q12,10 32,10 Q52,10 54,40 Z", "#3F7CBF") + p("M6,40 H58 Q56,50 32,50 Q8,50 6,40 Z", "#2F5F99") \
		+ hl(22, 18, 5, 3) + star(32, 27, 9, 4, BRASS)
	d["cat_coaster"] = p("M4,52 Q14,52 20,30 Q26,10 34,26 Q38,34 42,40 Q50,52 60,44", "none", 'stroke="#8E5BB5" stroke-width="5"') \
		+ ln(16, 40, 16, 56) + ln(26, 18, 26, 56) + ln(44, 44, 44, 56) + ln(6, 56, 58, 56) \
		+ r(24, 6, 16, 10, RED, 3, 'transform="rotate(30 32 11)"') + hl(28, 9, 3, 1.5)
	# Værktøjer
	d["tool_select"] = p("M24,10 Q24,6 28,6 Q32,6 32,10 V28 L44,30 Q52,32 50,40 L46,54 Q45,58 40,58 H26 Q22,58 20,54 L12,40 Q10,34 16,34 L24,40 Z", "#FFFFFF") \
		+ ln(32, 30, 32, 40, INK, 2) + ln(40, 31, 40, 40, INK, 2) + hl(27, 12, 2, 3)
	d["tool_remove"] = r(30, 8, 6, 26, GREY, 2, 'transform="rotate(25 33 21)"') \
		+ p("M8,30 H44 Q48,30 48,36 L52,54 H6 Q4,44 8,30 Z", RED) + ln(10, 54, 52, 54) + hl(14, 35, 4, 2)
	d["tool_rotate"] = r(22, 24, 20, 18, "#E8A33D", 2) + hl(26, 28, 3, 2) \
		+ thick("M14,24 A20,20 0 1 1 18,48", BRASS, 4) + poly([6, 22, 20, 20, 14, 32], BRASS)
	d["tool_undo"] = thick("M20,26 H40 Q54,26 54,40 Q54,54 40,54 H28", BRASS, 5) + poly([6, 26, 22, 14, 22, 38], BRASS)
	d["arrow_left"] = poly([12, 32, 48, 10, 48, 54], BRASS) + hl(38, 20, 4, 2)
	d["arrow_right"] = poly([52, 32, 16, 10, 16, 54], BRASS) + hl(24, 20, 4, 2)
	d["close"] = r(28, 4, 8, 56, WOOD_L, 3, 'transform="rotate(45 32 32)"') + r(28, 4, 8, 56, WOOD_L, 3, 'transform="rotate(-45 32 32)"')
	d["check"] = thick("M12,34 L26,48 L52,16", BRASS, 7)
	d["lock"] = p("M20,30 V20 Q20,8 32,8 Q44,8 44,20 V30", "none", 'stroke="%s" stroke-width="10"' % INK) \
		+ p("M20,30 V20 Q20,8 32,8 Q44,8 44,20 V30", "none", 'stroke="%s" stroke-width="5"' % GREY) \
		+ r(12, 28, 40, 30, BRASS, 5) + hl(19, 33, 4, 2) + c(32, 40, 4, INK, 'stroke="none"') + r(30, 41, 4, 10, INK, 1, 'stroke="none"')
	d["coin"] = c(32, 32, 26, BRASS) + c(32, 32, 19, BRASS_L, 'stroke-width="2"') + hl(22, 18, 5, 3) \
		+ ln(27, 20, 27, 44, INK, 5) + ln(29, 34, 39, 22, INK, 5) + ln(31, 31, 40, 44, INK, 5)
	# TopBar
	var stack := ""
	for i in 4:
		var y := 50.0 - i * 9.0
		stack += r(10, y - 4, 34, 9, BRASS, 4) + el(27, y - 4, 17, 4, BRASS_L, 'stroke-width="2"')
	d["money"] = stack + c(46, 46, 13, BRASS) + c(46, 46, 8, BRASS_L, 'stroke-width="2"') + hl(42, 40, 3, 2)
	d["guests"] = c(22, 20, 9, "#F2C9A0") + p("M6,56 Q6,32 22,32 Q38,32 38,56 Z", TEAL) \
		+ c(44, 24, 8, "#F2C9A0") + p("M30,58 Q30,36 44,36 Q58,36 58,58 Z", "#D9534F") + hl(19, 16, 2.5, 1.5)
	var rays := ""
	for i in 8:
		var a := TAU * i / 8.0
		rays += ln(32 + cos(a) * 20, 32 + sin(a) * 20, 32 + cos(a) * 28, 32 + sin(a) * 28, BRASS, 5)
	d["clock_day"] = rays + c(32, 32, 15, "#F2C96B") + hl(26, 26, 4, 2.5)
	d["clock_night"] = p("M40,8 A24,24 0 1 0 58,42 A20,20 0 0 1 40,8 Z", "#F6EBD3") + star(16, 14, 7, 3, BRASS_L, 'stroke-width="2"') + hl(22, 22, 3, 2)
	var mood_cols := ["#C8452F", "#E07A3A", "#E8C33D", "#9BC24A", "#4F9A3A"]
	for i in 5:
		d["mood_%d" % (i + 1)] = face(mood_cols[i], i + 1)
	d["star_full"] = star(32, 33, 28, 12, BRASS) + hl(26, 22, 4, 2)
	d["star_empty"] = star(32, 33, 28, 12, "#6E5E50", 'stroke="#8A8174" stroke-width="4"')
	d["speed_pause"] = r(14, 10, 13, 44, CREAM, 3) + r(37, 10, 13, 44, CREAM, 3)
	d["speed_1"] = tri(32, 32, 40, CREAM)
	d["speed_2"] = tri(22, 32, 30, CREAM) + tri(42, 32, 30, CREAM)
	d["speed_4"] = tri(14, 30, 22, CREAM) + tri(31, 30, 22, CREAM) + tri(48, 30, 22, CREAM) + c(48, 54, 5, BRASS, 'stroke-width="2"')
	d["bell"] = p("M32,8 Q48,8 48,30 Q48,44 56,48 H8 Q16,44 16,30 Q16,8 32,8 Z", BRASS) + c(32, 54, 5, BRASS_L) \
		+ c(32, 6, 3, BRASS) + hl(24, 18, 3, 4)
	# ParkRail
	d["rail_park"] = r(8, 22, 10, 36, WOOD_L, 2) + r(46, 22, 10, 36, WOOD_L, 2) + p("M6,24 Q32,6 58,24 V30 Q32,14 6,30 Z", RED) \
		+ ln(32, 14, 32, 4) + poly([32, 3, 44, 6, 32, 10], BRASS, 'stroke-width="2"') + r(20, 30, 24, 4, CREAM, 1)
	d["rail_staff"] = r(12, 10, 40, 48, WOOD_L, 4) + r(16, 16, 32, 38, PAPER, 2) + r(24, 6, 16, 8, GREY, 2) \
		+ c(24, 28, 4, TEAL, 'stroke-width="2"') + c(32, 28, 4, RED, 'stroke-width="2"') + c(40, 28, 4, "#3F7CBF", 'stroke-width="2"') \
		+ ln(21, 40, 43, 40, INK, 2) + ln(21, 47, 37, 47, INK, 2)
	d["rail_research"] = gear(44, 44, 15, 11, 8, GREY) + p("M18,6 H30 M21,6 V22 L8,50 Q6,56 12,56 H36 Q42,56 40,50 L27,22 V6", "#BFE6EE") \
		+ p("M13,42 H35 L40,50 Q42,56 36,56 H12 Q6,56 8,50 Z", GREEN) + hl(18, 46, 2, 2)
	d["rail_settings"] = gear(32, 32, 27, 20, 9, BRASS) + hl(22, 18, 4, 2)
	d["rail_menu"] = r(8, 10, 48, 11, WOOD_L, 4) + r(8, 27, 48, 11, WOOD_L, 4) + r(8, 44, 48, 11, WOOD_L, 4) + hl(14, 14, 4, 1.5)
	d["rail_finance"] = p("M18,20 Q8,32 10,46 Q12,58 32,58 Q52,58 54,46 Q56,32 46,20 Z", WOOD_L) + p("M20,20 L16,8 L26,12 L32,6 L38,12 L48,8 L44,20 Z", WOOD) \
		+ c(32, 40, 8, BRASS) + ln(18, 20, 46, 20, BRASS, 3) + hl(20, 30, 3, 4)
	# Varsler / Inspector
	d["alert_danger"] = p("M32,6 L60,56 H4 Z", RED) + r(29, 20, 6, 20, CREAM, 2, 'stroke="none"') + c(32, 47, 3.5, CREAM, 'stroke="none"')
	d["alert_info"] = c(32, 32, 26, TEAL) + c(32, 19, 4, CREAM, 'stroke="none"') + r(28, 27, 8, 22, CREAM, 2, 'stroke="none"')
	d["alert_ok"] = c(32, 32, 26, GREEN) + thick("M18,33 L28,43 L46,22", CREAM, 5)
	d["alert_broken"] = gear(38, 40, 20, 14, 8, GREY) + r(8, 22, 40, 8, "#C9C9C9", 3, 'transform="rotate(-40 28 26)"') \
		+ p("M6,20 A9,9 0 1 0 20,8 L16,16 Z", "#C9C9C9")
	d["alert_trash"] = r(14, 18, 36, 40, GREEN, 4) + r(10, 12, 44, 8, "#3E7A2E", 3) + ln(24, 26, 24, 50, INK, 2) + ln(32, 26, 32, 50, INK, 2) + ln(40, 26, 40, 50, INK, 2) \
		+ c(22, 9, 5, "#E8A33D", 'stroke-width="2"') + r(30, 2, 10, 10, "#FFFFFF", 1, 'stroke-width="2" transform="rotate(15 35 7)"') + c(46, 8, 4, "#D9534F", 'stroke-width="2"')
	d["stat_hunger"] = p("M8,28 Q8,8 32,8 Q56,8 56,28 Z", "#E8A33D") + r(6, 30, 52, 6, GREEN, 3) + r(8, 36, 48, 8, WOOD, 3) \
		+ p("M8,46 H56 Q56,56 46,56 H18 Q8,56 8,46 Z", "#E8A33D") + hl(20, 16, 4, 2)
	d["stat_thirst"] = p("M32,4 Q52,30 52,40 A20,20 0 0 1 12,40 Q12,30 32,4 Z", "#4FA3D9") + hl(24, 38, 3, 5)
	d["stat_toilet"] = r(14, 6, 36, 54, TEAL, 3) + r(19, 11, 26, 44, "#3A9F9F", 2) + c(39, 34, 3, BRASS, 'stroke-width="2"') \
		+ c(28, 22, 4, CREAM, 'stroke-width="2"') + p("M22,44 L28,30 L34,44 Z", CREAM, 'stroke-width="2"')
	d["stat_energy"] = r(8, 18, 44, 28, CREAM, 5) + r(52, 26, 6, 12, GREY, 2) + r(13, 23, 10, 18, GREEN, 2, 'stroke="none"') + r(26, 23, 10, 18, GREEN, 2, 'stroke="none"')
	d["stat_fun"] = p("M32,44 Q30,52 34,60", "none", 'stroke-width="2"') + el(32, 24, 17, 20, "#D9534F") + poly([29, 44, 35, 44, 32, 48], "#D9534F", 'stroke-width="2"') + hl(25, 15, 4, 6)
	d["stat_queue"] = c(10, 24, 6, CREAM) + c(26, 24, 6, CREAM) + c(42, 24, 6, CREAM) + thick("M8,46 H46", BRASS, 4) + poly([44, 38, 58, 46, 44, 54], BRASS)
	d["stat_capacity"] = r(14, 6, 36, 28, RED, 6) + r(10, 32, 44, 12, RED, 4) + ln(16, 44, 16, 58) + ln(48, 44, 48, 58) + hl(22, 12, 4, 2)
	d["stat_excitement"] = poly([36, 4, 12, 36, 28, 36, 22, 60, 52, 24, 34, 24, 42, 4], BRASS_L)
	d["stat_intensity"] = p("M32,4 Q40,18 48,24 Q58,34 54,46 Q50,60 32,60 Q14,60 10,46 Q6,34 18,22 Q20,32 26,32 Q20,16 32,4 Z", "#E07A3A") \
		+ p("M32,30 Q42,40 40,50 Q38,56 32,56 Q24,56 24,48 Q24,40 32,30 Z", BRASS_L, 'stroke-width="2"')
	d["stat_nausea"] = c(32, 32, 26, "#9BC24A") + p("M32,32 m-3,0 a3,3 0 1 1 6,0 a7,7 0 1 1 -14,0 a11,11 0 1 1 22,0 a15,15 0 1 1 -30,0", "none", 'stroke="#2F6B22" stroke-width="3"')
	d["guest_portrait"] = head(false)
	d["staff_portrait"] = head(true)
	# Hovedmenu
	d["menu_continue"] = poly([16, 8, 54, 32, 16, 56], GREEN) + hl(24, 20, 3, 5)
	d["menu_new"] = r(8, 10, 48, 38, WOOD_L, 5) + r(29, 48, 6, 12, WOOD) + r(28, 16, 8, 26, CREAM, 2) + r(19, 25, 26, 8, CREAM, 2)
	d["menu_load"] = p("M6,14 H24 L28,20 H54 V52 H6 Z", "#C99A50") + p("M6,52 L14,28 H62 L54,52 Z", BRASS_L)
	d["menu_settings"] = d["rail_settings"]
	d["menu_quit"] = r(8, 6, 30, 52, WOOD_L, 2) + r(13, 11, 20, 42, WOOD, 1) + c(29, 34, 2.5, BRASS, 'stroke-width="1.5"') \
		+ thick("M34,32 H52", RED, 4) + poly([48, 22, 60, 32, 48, 42], RED)
	return d
