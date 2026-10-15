# T-013: Simulation – Gæster der går rundt

- **Status:** review
- **Milepæl:** M1
- **Agent:** simulation
- **Afhænger af:** T-011, T-012

## Mål
Gæster spawner ved indgangen, vælger en attraktion (eller vandrer på stier), går dertil, stiller sig i kø, kører, gentager et par gange og forlader parken.

## API-kontrakt
- `class_name Guest extends RefCounted`: `id:int`, `cell:Vector2i`, `next_cell:Vector2i`, `progress:float` (0..1 mellem cell og next_cell), `state:int` (enum WALKING, QUEUING, RIDING, LEAVING)
- `class_name ParkSim extends RefCounted` i `game/simulation/park_sim.gd`: samler alt
  - `func _init(width:int, height:int, seed:int)`; `var world: ParkWorld`, `var clock: SimClock`, `var guests: Dictionary` (id→Guest), `var attractions: Array[Attraction]`
  - `func update(delta: float)` (driver clock → tick)
  - Kommandoer: `cmd_place_path(cell)`, `cmd_remove_path(cell)`, `cmd_place_attraction(def_id: String, origin)`
  - Signaler: `guest_spawned(guest)`, `guest_removed(guest_id)`
  - Spawn-rate konfigurerbar; seedet RNG (deterministisk)

## Acceptkriterier
- [x] Tests: gæst når attraktion og kører; deterministisk ved samme seed; gæst forlader parken; ingen gæster spawner uden sti fra indgang
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: implementeret med tests, ./tools/test.sh grøn (17 tests) → review
