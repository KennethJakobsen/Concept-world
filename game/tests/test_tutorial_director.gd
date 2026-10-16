extends TestCase
## T-115: TutorialDirector – alle trin gennemføres headless ved handling, ikke ved klik.


func _make() -> Array:
	var def: ScenarioDef = ScenarioDef.find("tutorial")
	assert_true(def != null, "tutorial.json findes")
	var s: ParkSim = ParkSim.new_from_scenario(def, 1)
	var t: TutorialDirector = TutorialDirector.for_scenario("tutorial", s)
	assert_true(t != null, "tutorial-flag genkendt")
	return [s, t]


func test_non_tutorial_has_no_director() -> void:
	assert_true(TutorialDirector.for_scenario("sandbox", ParkSim.new(10, 10, 1)) == null)


func test_full_run_by_actions() -> void:
	var st: Array = _make()
	var s: ParkSim = st[0]
	var t: TutorialDirector = st[1]
	var seen: Array = []
	var done: Array = []
	t.step_changed.connect(func(i: int, step: Dictionary) -> void: seen.append(str(step.get("id"))))
	t.finished.connect(func(sk: bool) -> void: done.append(sk))
	t.start()
	assert_eq(t.index, 0)
	assert_eq(t.arrow_cell(), s.world.entrance, "pil ved indgangen")
	t.poll()
	assert_eq(t.index, 0, "intet sker uden handling")
	var e: Vector2i = s.world.entrance
	# Trin 1: sti fra indgangen.
	for y in range(e.y - 1, e.y - 6, -1):
		s.cmd_place_path(Vector2i(e.x, y))
	t.poll()
	assert_eq(t.index, 1, "sti forbundet")
	# Trin 2: karrusel.
	var ride: Attraction = null
	for x in range(e.x + 1, e.x + 8):
		for y in range(e.y - 10, e.y - 1):
			if ride == null:
				ride = s.cmd_place_attraction("carousel", Vector2i(x, y))
	assert_true(ride != null, "karrusel placeret")
	t.poll()
	assert_eq(t.index, 2)
	# Trin 3: drikkebod.
	var shop: Attraction = null
	for x in range(e.x - 8, e.x):
		for y in range(e.y - 10, e.y - 1):
			if shop == null:
				shop = s.cmd_place_attraction("drinks_stand", Vector2i(x, y))
	assert_true(shop != null, "bod placeret")
	t.poll()
	assert_eq(t.index, 3)
	assert_eq(t.arrow_cell(), shop.origin, "pil ved boden")
	# Trin 4: pris.
	assert_true(s.cmd_set_price(shop.id, shop.price + 1))
	t.poll()
	assert_eq(t.index, 4)
	# Trin 5: overlay (UI-event).
	t.notify("overlay_opened:litter")
	assert_eq(t.index, 4, "forkert overlay tæller ikke")
	t.notify("overlay_opened:queue")
	assert_eq(t.index, 5)
	# Trin 6: rengøring.
	assert_true(s.cmd_hire_staff("cleaner", Vector2i(e.x, e.y - 2)) >= 0)
	t.poll()
	assert_true(not t.active())
	assert_eq(seen.size(), 6)
	assert_eq(done, [false])


func test_skip() -> void:
	var st: Array = _make()
	var t: TutorialDirector = st[1]
	var done: Array = []
	t.finished.connect(func(sk: bool) -> void: done.append(sk))
	t.start()
	assert_true(t.skippable)
	t.skip()
	assert_true(not t.active())
	assert_eq(done, [true])
	t.skip()
	assert_eq(done.size(), 1, "kun én gang")
