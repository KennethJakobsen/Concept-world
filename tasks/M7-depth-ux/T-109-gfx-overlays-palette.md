# T-109: Grafik: kort-overlays og farveblind-palet

- **Status:** done
- **Milepæl:** M7
- **Agent:** graphics
- **Afhænger af:** T-107

## Mål
Kontraktens §2 T-109. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `OverlayRenderer.show/hide` for glæde, skrald, kø, dækning og lys med dæmpet verden
- [x] `ColorPalette` (viridis + blå/orange) og ghost-farver fra paletten
- [x] Form-signal (tegnet ✓/✗) i farveblind-tilstand
- [x] Screenshots

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – graphics: færdig → review. **Afvigelser:** klassen hedder `ParkColors` (Godot har en indbygget `ColorPalette`), og metoderne hedder `show_overlay/hide_overlay` (Node3D har allerede `show()/hide()`).
  - `ParkColors` (`scripts/rendering/park_colors.gd`, statisk): `colorblind` (static var), `set_colorblind(on)`, `refresh_from_settings()` (læser `UserSettings` [accessibility] colorblind), `valid(a)`, `invalid(a)`, `ghost(ok, a=0.45)` (grøn/rød eller blå/orange), `viridis(t)`, `overlay_color(kind, v)`, `legend(kind) -> [{color, label}]` (3 trin fra dårligt til godt, danske tekster) og `OVERLAY_KINDS = [happiness, litter, queue, coverage, light]`.
  - `OverlayRenderer` (`scripts/rendering/overlay_renderer.gd`, Node3D): `show_overlay(kind, data)`, `hide_overlay()`, `current_kind()` og signalet `overlay_changed(kind)`. `data = {cells: Dictionary[Vector2i→0..1] | Array[Vector2i], markers: Array[Vector2i] (fx crowded_cells()), dim: float=0.55}`. Værdien 1 betyder godt for glæde/dækning/lys og meget for skrald/kø, og skalaen vendes, så gul altid er godt. Verden dæmpes med en fuldskærms-quad (spatial shader, `depth_test_disabled`). Felterne tegnes med en MultiMesh oven på verden. Det virker i Compatibility.
  - Ghosts: `CellHighlight` og `CoasterTrackMesh.set_ghost` bruger `ParkColors.ghost()`. I farveblind-tilstand tegner `CellHighlight` et procedurelt ✓/✗.
  - **Bridge (T-111):** opret én `OverlayRenderer` i ParkView. `GameSession.overlay_data(kind)` bygger `cells` (happiness: gennemsnitlig glæde/100 pr. sti-celle; litter: antal/5; queue: `occupancy/max_guests_per_cell` + `markers = crowded_cells()`; coverage: celler inden for rækkevidde af staff/spande = 1; light: `light_level(cell)`). Kald `ParkColors.refresh_from_settings()` ved opstart og `set_colorblind()` ved ændring, og byg derefter de aktive ghosts om.
  - **UI (T-113):** overlay-vælgeren bruger `ParkColors.OVERLAY_KINDS` og `ParkColors.legend(kind)` og kalder bridge, som kalder `show_overlay/hide_overlay`. Farveblind-checkboksen kalder `ParkColors.set_colorblind()`.
  - Demo: `scenes/rendering/overlay_demo.tscn` (1–5, 0, C). Screenshots: `docs/screenshots/t109_{happiness,litter,queue,coverage,light,ghost,ghost_cb}.png`. Test: `tests/test_render_overlay.gd`. `test.sh`: 381/382, hvor den ene fejl er T-112's `test_ui_m7_inspector` (ui arbejder parallelt). Smoke OK.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
