class_name UiFit
extends RefCounted
## T-146: hold paneler inden for et givet område. Panelets indhold lægges i en lodret
## ScrollContainer ("Fit"), så højden kan begrænses (scroll ved behov) uden at Control
## klamper størrelsen op til indholdets minimum og skubber knapper ud over skærmkanten.

const SCROLL_NAME: String = "Fit"


## Flytter alle børn af `p` ind i en lodret ScrollContainer. Idempotent.
static func wrap_scroll(p: Container) -> ScrollContainer:
	var existing: Node = p.get_node_or_null(SCROLL_NAME)
	if existing is ScrollContainer:
		return existing
	var sc := ScrollContainer.new()
	sc.name = SCROLL_NAME
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	sc.mouse_filter = Control.MOUSE_FILTER_PASS
	var kids: Array[Node] = p.get_children()
	p.add_child(sc)
	for k in kids:
		p.remove_child(k)
		sc.add_child(k)
		if k is Control:
			(k as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return sc


## Sætter scroll-højden og panelets størrelse, så panelet højst fylder `max_size`.
## Returnerer den faktiske størrelse.
static func fit(p: Control, max_size: Vector2) -> Vector2:
	var sc: ScrollContainer = p.get_node_or_null(SCROLL_NAME) as ScrollContainer
	if sc != null:
		var frame: Vector2 = Vector2.ZERO
		if p is PanelContainer:
			var sb: StyleBox = p.get_theme_stylebox("panel")
			if sb != null:
				frame = sb.get_minimum_size()
		var content_h: float = 0.0
		for c in sc.get_children():
			if c is Control and (c as Control).visible:
				content_h = maxf(content_h, (c as Control).get_combined_minimum_size().y)
		sc.custom_minimum_size.y = maxf(0.0, minf(content_h, max_size.y - frame.y))
	var want: Vector2 = p.get_combined_minimum_size()
	want.x = minf(maxf(want.x, p.custom_minimum_size.x), max_size.x)
	want.y = minf(want.y, max_size.y)
	p.size = want
	return p.size
