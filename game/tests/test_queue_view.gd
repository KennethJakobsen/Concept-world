extends TestCase
## T-140: køsti-værktøj, køsti-visuals og gæster på køpladser i scenen.

const RIDE: Dictionary = {"id": "slow_q", "kind": "ride", "footprint": [1, 1], "capacity": 2,
	"ride_ticks": 3000, "ticket_price": 1, "excitement": 20}


func _balance() -> Balance:
	return Balance.from_dicts(
		{"start_money": 100000, "entry_fee": 0, "path_cost": 0, "guest_money_min": 500,
			"guest_money_max": 500, "day_ticks": 100000}, {"needs": {}, "happiness_start": 70, "leave_happiness": 20},
		{"queue_slots_per_cell": 2, "queue_default_max": 4, "queue_path_cost": 15, "queue_path_refund": 7,
			"max_guests_base": 8, "queue_max_cycles": 3})


## Forlystelse (10,15), indgang (10,16). Sti y=21 og x=15 ned til porten.
func _setup() -> Array:
	var s := ParkSim.new(30, 30, 4, _balance())
	s.register_def(AttractionDef.from_dict(RIDE))
	for y in range(21, 29):
		s.cmd_place_path(Vector2i(15, y))
	for x in range(10, 15):
		s.cmd_place_path(Vector2i(x, 21))
	assert_true(s.cmd_place_attraction("slow_q", Vector2i(10, 15)) != null)
	var view := ParkView.new()
	view.setup(s)
	var bt := BuildTool.new()
	bt._view = view
	assert_true(bt.set_tool(BuildTool.TOOL_QUEUE))
	return [view, s, bt]


func test_queue_tool_places_and_removes() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	assert_true(not bt.is_tool_locked(BuildTool.TOOL_QUEUE), "køsti er aldrig låst")
	assert_eq(BuildTool.tool_content_id(BuildTool.TOOL_QUEUE), "")
	var m0: int = s.economy.money
	for y in range(17, 21):
		assert_true(bt.place_queue_path(Vector2i(10, y)))
	assert_eq(s.economy.money, m0 - 4 * 15)
	var a: Attraction = s.attractions[0]
	assert_eq(a.queue_cells.size(), 4)
	assert_eq(s.queue_capacity(a), 8)
	for y in range(17, 21):
		assert_true(view.queue_visual(Vector2i(10, y)) != null, "visual pr. køcelle")
	# Forreste celle åbner mod indgangen (N) og næste køcelle (S); bageste mod forgænger (N) og stien (S).
	assert_eq(view.queue_visual(Vector2i(10, 17)).connections, QueuePathVisual.N | QueuePathVisual.S)
	assert_eq(view.queue_visual(Vector2i(10, 20)).connections, QueuePathVisual.N | QueuePathVisual.S)
	# En løs køcelle uden naboer er lukket på alle sider.
	assert_true(bt.place_queue_path(Vector2i(3, 3)))
	assert_eq(view.queue_visual(Vector2i(3, 3)).connections, 0)
	# Fjern via fjern-værktøjets sti-fjernelse.
	assert_true(bt.remove_path_at(Vector2i(10, 20)))
	assert_true(view.queue_visual(Vector2i(10, 20)) == null)
	assert_eq(a.queue_cells.size(), 3)
	assert_eq(view.queue_visual(Vector2i(10, 19)).connections, QueuePathVisual.N, "ny ende uden sti er lukket")
	bt.free()
	view.free()


func test_queued_guests_stand_on_separate_slots() -> void:
	var r: Array = _setup()
	var view: ParkView = r[0]
	var s: ParkSim = r[1]
	var bt: BuildTool = r[2]
	for y in range(17, 21):
		bt.place_queue_path(Vector2i(10, y))
	var a: Attraction = s.attractions[0]
	s.spawn_interval_ticks = 3
	s.max_guests = 14
	s.rides_per_guest_min = 5
	s.rides_per_guest_max = 5
	for i in 6000:
		s.update(SimClock.TICK_DELTA)
		if a.queue.size() >= 8:
			break
	assert_true(a.queue.size() >= 2, "gæster i kø: %d" % a.queue.size())
	view.sync_guests()
	var seen: Array[Vector3] = []
	for gid: int in a.queue:
		var n: Node3D = view._guests[gid]
		var g: Guest = s.guests[gid]
		var slot: Vector2 = s.queue_slot_position(a, g.queue_index)
		assert_true(n.position.distance_to(Vector3(slot.x, 0.0, slot.y)) < 0.01, "gæst på sin køplads")
		for p: Vector3 in seen:
			assert_true(p.distance_to(n.position) > 0.2, "ingen overlap i køen")
		seen.append(n.position)
	assert_true(Hud.attraction_text(a, s).contains("ventetid"), "kølinje med ventetid")
	bt.free()
	view.free()
