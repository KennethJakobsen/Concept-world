# T-135: Gameplay: omgivelser (T-108) i ParkView

- **Status:** review
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-108

## Mål
`ParkView` opretter `SurroundingsRenderer` efter setup med scenariets tema (se T-108-loggen).

## Acceptkriterier
- [x] Mur, port og bælte vises i parken for alle scenarier
- [x] Kameragrænser udvidet så bæltet kan ses
- [x] Ingen dobbelt indgang (gammel `entrance.tscn` vs. ny port)
- [x] Tests + smoke grønne

## Log
- 2026-10-16 – orkestrator: oprettet efter T-108
- 2026-10-16 – gameplay: `ParkView.rebuild()` kalder `_build_surroundings()`, som opretter `SurroundingsRenderer` (i `Content`, så den genbygges ved load) med tema fra `content/scenarios/<def_id>.json` → `surroundings.theme` (`scenario_theme()`, ingen sim-ændring). Fri leg/ukendt bruger park.json-default. Den gamle `entrance.tscn` er fjernet fra parken, så porten er den eneste indgang. `ParkCamera` har fået `bounds`/`set_bounds()` (clamp af fokus), og grænsen sættes til parken + 0,75 × margin. `max_distance` er hævet fra 60 til 80. Test: `tests/test_park_surroundings.gd` (tema pr. scenarie, ingen entrance.tscn). Screenshots: `docs/screenshots/t135_{green_meadow,river_valley,mountain_peak}.png` via `scripts/bridge/surroundings_screenshots.gd`, og alle tre temaer er set og ser rigtige ud. test.sh: 355 bestået, 21 fejl. Ingen af fejlene er T-135: `coaster_track_mesh.gd` (`ghost()`/`load_defs`, graphics i gang) og `test_ui_m7_foundation` inspector-tabs (ui i gang). Integration og smoke fejler i øjeblikket på samme compile-fejl i `coaster_track_mesh.gd`, så de skal køres igen, når graphics er færdig. Visuel bekræftelse fra brugeren mangler.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
