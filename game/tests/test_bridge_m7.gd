extends TestCase
## T-111: M7-bridge – salgsbatching, overlay-data, skrald/spand/bænk, taster.


func test_sales_batcher_windows() -> void:
	var b := SalesBatcher.new()
	b.add({1: 5, 2: 3})
	assert_true(b.advance(0.1).is_empty(), "vindue ikke lukket")
	b.add({1: 5})
	assert_true(b.advance(0.1).is_empty())
	var out: Dictionary = b.advance(0.06)
	assert_eq(int(out.get(1, 0)), 10)
	assert_eq(int(out.get(2, 0)), 3)
	assert_true(b.pending().is_empty(), "nulstillet efter flush")
	assert_true(b.advance(0.3).is_empty(), "tomt vindue giver intet")


func test_sales_tick_flows_to_floating_and_flash() -> void:
	var view := ParkView.new()
	var s := ParkSim.new(20, 20, 1)
	view.setup(s)
	var a: Attraction = s.cmd_place_attraction("burger_stand", Vector2i(5, 5))
	assert_true(a != null)
	var flushed: Array = []
	var flashes: Array = []
	view.sales_flushed.connect(func(d: Dictionary) -> void: flushed.append(d))
	view.money_flash.connect(func(sgn: int) -> void: flashes.append(sgn))
	view._last_money = s.economy.money
	s.economy.earn(30, "test")
	s.sales_tick.emit({a.id: 12})
	s.sales_tick.emit({a.id: 18})
	view._flush_sales(0.3)
	assert_eq(flushed.size(), 1)
	assert_eq(int((flushed[0] as Dictionary)[a.id]), 30)
	assert_eq(flashes, [1])
	view.free()


func test_overlay_data_kinds() -> void:
	var s := ParkSim.new(20, 20, 2)
	for x in range(3, 8):
		assert_true(s.cmd_place_path(Vector2i(x, 10)))
	s.world.set_litter(Vector2i(4, 10), 5)
	var lit: Dictionary = OverlayData.build(s, &"litter")
	assert_eq(float((lit["cells"] as Dictionary)[Vector2i(4, 10)]), 1.0)
	var light: Dictionary = OverlayData.build(s, &"light")
	assert_true((light["cells"] as Dictionary).has(Vector2i(3, 10)), "lys pr. sticelle")
	var cov: Dictionary = OverlayData.build(s, &"coverage")
	assert_eq(float((cov["cells"] as Dictionary)[Vector2i(5, 10)]), 0.0, "ingen dækning uden personale/spande")
	assert_true(s.cmd_place_decor("bin", Vector2i(5, 10)) >= 0)
	cov = OverlayData.build(s, &"coverage")
	assert_eq(float((cov["cells"] as Dictionary)[Vector2i(5, 10)]), 1.0)
	var q: Dictionary = OverlayData.build(s, &"queue")
	assert_true(q.has("markers"))
	assert_true(OverlayData.build(null, &"happiness")["cells"].is_empty())
	var view := ParkView.new()
	view.setup(s)
	view.show_overlay(&"litter")
	assert_eq(view.overlay_kind(), &"litter")
	view.hide_overlay()
	assert_eq(view.overlay_kind(), &"")
	view.free()


func test_litter_scatter_and_bins() -> void:
	var view := ParkView.new()
	var s := ParkSim.new(20, 20, 2)
	view.setup(s)
	assert_true(s.cmd_place_path(Vector2i(4, 4)))
	s.world.set_litter(Vector2i(4, 4), 3)
	assert_eq(view.litter_node_count(), 1)
	s.world.set_litter(Vector2i(4, 4), 0)
	assert_eq(view.litter_node_count(), 0)
	var items: Array = ParkView.litter_items(s.litter_at(Vector2i(4, 4)), Vector2i(4, 4))
	assert_true(items.is_empty())
	var bid: int = s.cmd_place_decor("bin", Vector2i(4, 4))
	assert_true(bid >= 0)
	s.bin_state_changed.emit(bid, 2)  # visual: fuld-ikon
	view.free()


func test_bench_seat_signals() -> void:
	var view := ParkView.new()
	var s := ParkSim.new(20, 20, 2)
	s.spawn_interval_ticks = 1
	s.max_guests = 1
	view.setup(s)
	assert_true(s.cmd_place_path(Vector2i(4, 4)))
	var did: int = s.cmd_place_decor("bench", Vector2i(4, 4))
	for i in 10:
		s.update(SimClock.TICK_DELTA)
	if s.guests.is_empty():
		view.free()
		return
	var gid: int = s.guests.keys()[0]
	s.guest_sat.emit(gid, did, 1)
	assert_eq(view.seated_count(), 1)
	s.guest_stood.emit(gid)
	assert_eq(view.seated_count(), 0)
	view.free()


func test_category_keys_cover_dock() -> void:
	assert_eq(BuildTool.KEY_CATEGORIES.size(), BuildDock.CATEGORIES.size())
	for k: Variant in BuildTool.KEY_CATEGORIES:
		assert_true(BuildDock.CATEGORIES.has(BuildTool.KEY_CATEGORIES[k]))
