extends TestCase
## T-036: SaveStore (user://).


func _store() -> SaveStore:
	var dir: String = "user://test_saves_%d/" % Time.get_ticks_usec()
	return SaveStore.new(dir)


func _cleanup(st: SaveStore) -> void:
	for s in st.list():
		st.delete(s)
	DirAccess.remove_absolute(st.base_dir)


func test_save_load_list_delete() -> void:
	var st := _store()
	assert_eq(st.list(), [])
	assert_eq(st.load("nope"), {})
	assert_true(st.save("b_slot", {"x": 1, "f": 0.1234567890123}))
	assert_true(st.save(SaveStore.AUTOSAVE_SLOT, {"y": [1, 2]}))
	assert_eq(st.list(), ["autosave", "b_slot"])
	var d: Dictionary = st.load("b_slot")
	assert_eq(int(d["x"]), 1)
	assert_eq(d["f"], 0.1234567890123)
	assert_true(st.save("b_slot", {"x": 2}))
	assert_eq(int(st.load("b_slot")["x"]), 2)
	assert_true(st.delete("b_slot"))
	assert_true(not st.delete("b_slot"))
	assert_eq(st.list(), ["autosave"])
	_cleanup(st)


func test_invalid_slot() -> void:
	var st := _store()
	assert_true(not st.save("../evil", {}))
	assert_true(not st.save("", {}))
	assert_eq(st.list(), [])
	_cleanup(st)


func test_full_sim_through_store() -> void:
	var st := _store()
	var a := ParkSim.new(20, 20, 5)
	a.cmd_place_path(Vector2i(10, 18))
	assert_true(st.save("park1", a.to_save()))
	var b := ParkSim.from_save(st.load("park1"))
	assert_true(b != null)
	assert_eq(b.world.get_tile(Vector2i(10, 18)), ParkWorld.Tile.PATH)
	assert_eq(b.economy.money, a.economy.money)
	_cleanup(st)
