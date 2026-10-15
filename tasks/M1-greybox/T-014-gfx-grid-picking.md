# T-014: Grafik – Terræn, grid-overlay, musepicking og placeholder-meshes

- **Status:** done
- **Milepæl:** M1
- **Agent:** graphics
- **Afhænger af:** T-009

## Mål
Visuelt fundament til byggeri. Må ikke afhænge af simulationen.

## API-kontrakt
- `class_name GridPicker extends Node` i `game/scripts/rendering/grid_picker.gd`: `func cell_under_mouse(camera: Camera3D) -> Vector2i` (ray mod y=0-planet; cell = floor(x), floor(z)), `const INVALID := Vector2i(-9999,-9999)`
- `class_name CellHighlight extends MeshInstance3D`: `func show_at(cell: Vector2i, valid: bool)`, `func hide_highlight()` (grøn/rød halvgennemsigtig)
- `game/scenes/props/`: `path_tile.tscn` (1×1 flise), `carousel.tscn` (3×3 low-poly placeholder, roterende top), `guest.tscn` (kapsel ~0.5 høj, tilfældig farve via `func set_color(c: Color)`), `entrance.tscn` (port)
- Grid-overlay shader på jorden (tynde linjer, kun Compatibility-kompatible features). Celle (x,y) har centrum i world (x+0.5, 0, y+0.5).

## Acceptkriterier
- [x] Alt virker i Compatibility-renderer
- [x] Props-scener kan instansieres alene

## Log
- 2026-10-15 – graphics: GridPicker, CellHighlight, grid-shader på jord (64×64, hjørne i 0,0), props (path_tile, carousel, guest, entrance); kamera start (32,0,40). Test+web-build grøn.
- 2026-10-15 – qa: kode gennemgået mod API-kontrakt, tests 18/18 grønne, smoke + web-build OK → done
