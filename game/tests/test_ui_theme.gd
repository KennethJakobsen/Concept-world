extends TestCase
## T-138: fælles UI-tema "Tivoli-skilt" og billedbaseret byggedok.


func test_theme_resource_matches_builder() -> void:
	assert_true(ResourceLoader.exists(UiTheme.THEME_PATH), "tema-resourcen findes")
	var t: Theme = UiTheme.get_theme()
	for v: String in ["PanelWood", "PanelPaper", "SignWood", "WoodLabel", "TitleLabel", "Medallion", "Card",
			"Tab", "AlertNote", "BigButton"]:
		assert_true(t.get_type_variation_base(v) != &"", "variation " + v)
	var wood: StyleBoxFlat = t.get_stylebox("panel", "PanelWood")
	assert_eq(wood.bg_color, UiTheme.WOOD_DARK)
	assert_eq(wood.border_color, UiTheme.BRASS)
	assert_eq(t.get_color("font_color", "Label"), UiTheme.INK)
	assert_true(t.has_stylebox("panel", "TooltipPanel"))


func test_hud_and_menu_use_shared_theme() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	assert_true((hud.get_node("Root") as Control).theme == UiTheme.get_theme())
	hud.free()
	var m := MainMenu.new()
	m.build()
	assert_true(m.theme == UiTheme.get_theme())
	m.free()


func test_thumb_fallback_to_category_icon() -> void:
	assert_true(UiTheme.thumb("carousel", "rides") != null)
	assert_true(UiTheme.thumb("decor:bench", "decor") != null)
	var fb: Texture2D = UiTheme.thumb("does_not_exist", "shops")
	assert_true(fb != null and fb.resource_path.ends_with("cat_shops.png"), "fallback = kategori-ikon")


func test_dock_cards_categories_paging_and_lock() -> void:
	var hud := Hud.new()
	hud.sim = ParkSim.new(20, 20, 1)
	hud._build_ui()
	var dock: BuildDock = hud.build_dock
	assert_true(not dock.cards_open(), "kortpanel lukket ved start")
	for c: String in BuildDock.CATEGORIES:
		var b: Button = dock.cat_buttons[c]
		assert_true(b.icon != null and b.text == "", "kategori %s er et ikon" % c)
	hud.set_tab("shops")
	assert_true(dock.cards_open())
	dock.set_grid(3, 1)
	var shops: Array[String] = dock.category_ids("shops")
	var shown: int = 0
	for id: String in shops:
		if (dock.cards[id] as Button).visible:
			shown += 1
	assert_eq(shown, mini(3, shops.size()))
	if shops.size() > 3:
		dock.set_page(1)
		assert_true((dock.cards[shops[3]] as Button).visible)
	var card: Button = dock.cards["carousel"]
	assert_true(card.get_node("Content/Thumb") is TextureRect)
	LockOverlay.apply(card, true)
	assert_true(LockOverlay.is_locked(card))
	assert_eq((card.get_node("Content/PriceRow/Price") as Label).text, "Forskning")
	LockOverlay.apply(card, false)
	assert_true(not LockOverlay.is_locked(card))
	card.pressed.emit()
	assert_eq(dock.selected_id, "carousel")
	assert_true(card.button_pressed and (card.get_node("Check") as CanvasItem).visible)
	assert_true(hud.handle_escape(), "Esc lukker kortpanelet")
	assert_true(not dock.cards_open())
	hud.free()
