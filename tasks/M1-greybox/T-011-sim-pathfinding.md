# T-011: Simulation – Pathfinding på stier

- **Status:** review
- **Milepæl:** M1
- **Agent:** simulation
- **Afhænger af:** T-010

## Mål
A* over sti-celler (PATH, ENTRANCE og attraktioners indgangscelle). 4-naboskab.

## API-kontrakt
`class_name PathFinder extends RefCounted` i `game/simulation/world/path_finder.gd`
- `func _init(world: ParkWorld)`
- `func find_path(from: Vector2i, to: Vector2i) -> Array[Vector2i]` (tom hvis ingen vej; inkluderer start og mål)
- Cacher/invaliderer ved `tile_changed`.

## Acceptkriterier
- [x] Tests: lige vej, omvej, ingen vej, opdatering efter fjernet sti
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: implementeret med tests, ./tools/test.sh grøn (17 tests) → review
