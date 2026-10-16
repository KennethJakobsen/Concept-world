class_name OverlayData
extends RefCounted
## T-111: Samler sim-data til OverlayRenderer.show_overlay(kind, data). Kun læsning af sim-state.
## data = {cells: Dictionary[Vector2i -> 0..1], markers: Array[Vector2i]}.
## 1 = godt for happiness/coverage/light og "meget" for litter/queue (som OverlayRenderer forventer).

const LITTER_FULL: float = 5.0


static func build(sim: ParkSim, kind: StringName) -> Dictionary:
	var cells: Dictionary = {}
	var markers: Array[Vector2i] = []
	if sim == null:
		return {"cells": cells, "markers": markers}
	match kind:
		&"happiness":
			var sum: Dictionary = {}
			var cnt: Dictionary = {}
			for gid: int in sim.guests:
				var g: Guest = sim.guests[gid]
				if not _is_walkable(sim, g.cell):
					continue
				sum[g.cell] = float(sum.get(g.cell, 0.0)) + g.happiness
				cnt[g.cell] = int(cnt.get(g.cell, 0)) + 1
			for c: Vector2i in sum:
				cells[c] = clampf(float(sum[c]) / float(cnt[c]) / 100.0, 0.0, 1.0)
		&"litter":
			for c: Vector2i in sim.world.litter:
				var n: int = int(sim.world.litter[c])
				if n > 0:
					cells[c] = clampf(float(n) / LITTER_FULL, 0.0, 1.0)
		&"queue":
			var mx: float = float(maxi(1, sim.balance.max_guests_per_cell))
			for c: Vector2i in _walkable_cells(sim):
				var o: int = sim.occupancy(c)
				if o > 0:
					cells[c] = clampf(float(o) / mx, 0.0, 1.0)
			markers = sim.crowded_cells()
		&"coverage":
			var staff_list: Array = sim.staff.values()
			var bins: Array[Vector2i] = []
			for did: int in sim.decor:
				var d: Decor = sim.decor[did]
				if d.def.kind == "bin":
					bins.append(d.cell)
			var br: int = sim.balance.bin_radius
			for c: Vector2i in _walkable_cells(sim):
				var cov: bool = false
				for st: Staff in staff_list:
					var r: int = st.def.work_radius
					if r <= 0 or _manhattan(st.home_cell, c) <= r:
						cov = true
						break
				if not cov:
					for b: Vector2i in bins:
						if _manhattan(b, c) <= br:
							cov = true
							break
				cells[c] = 1.0 if cov else 0.0
		&"light":
			for c: Vector2i in _walkable_cells(sim):
				cells[c] = clampf(sim.light_level(c), 0.0, 1.0)
	return {"cells": cells, "markers": markers}


static func _manhattan(a: Vector2i, b: Vector2i) -> int:
	return absi(a.x - b.x) + absi(a.y - b.y)


static func _is_walkable(sim: ParkSim, c: Vector2i) -> bool:
	var t: int = sim.world.get_tile(c)
	return t == ParkWorld.Tile.PATH or t == ParkWorld.Tile.QUEUE


static func _walkable_cells(sim: ParkSim) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var w: ParkWorld = sim.world
	for y in w.height:
		for x in w.width:
			var c := Vector2i(x, y)
			if _is_walkable(sim, c):
				out.append(c)
	return out
