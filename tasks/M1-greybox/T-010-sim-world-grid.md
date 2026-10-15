# T-010: Simulation – ParkWorld grid og stier

- **Status:** done
- **Milepæl:** M1
- **Agent:** simulation
- **Afhænger af:** T-004

## Mål
Rent data-grid for parken, som alle andre systemer bygger på.

## API-kontrakt (skal overholdes – bruges af gameplay/graphics)
`class_name ParkWorld extends RefCounted` i `game/simulation/world/park_world.gd`
- `const TILE_SIZE: float = 1.0`
- `func _init(width: int, height: int)`
- `var width: int`, `var height: int`
- `func in_bounds(cell: Vector2i) -> bool`
- `func get_tile(cell: Vector2i) -> int` (enum `Tile { GRASS, PATH, ATTRACTION, ENTRANCE }`)
- `func can_place_path(cell: Vector2i) -> bool`, `func place_path(cell: Vector2i) -> bool`, `func remove_path(cell: Vector2i) -> bool`
- `var entrance: Vector2i` (sat i konstruktør til midten af nederste kant, tile = ENTRANCE)
- `signal tile_changed(cell: Vector2i, tile: int)`

## Acceptkriterier
- [x] API som ovenfor
- [x] Tests: grænser, placér/fjern sti, kan ikke placere oven på attraktion/indgang, signal udsendes
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: implementeret med tests, ./tools/test.sh grøn (17 tests) → review
- 2026-10-15 – qa: kode gennemgået mod API-kontrakt, tests 18/18 grønne, smoke + web-build OK → done
