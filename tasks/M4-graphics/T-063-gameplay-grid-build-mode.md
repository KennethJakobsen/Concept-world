# T-063: Grid-linjer kun i byggetilstand

- **Status:** review
- **Milepæl:** M4
- **Agent:** gameplay
- **Afhænger af:** T-059

## Mål
Terrænets grid-linjer (`line_strength` i `ground_grid.gdshader`) vises kun, når et bygge-/nedrivningsværktøj er aktivt. I vælg-værktøjet er de skjult. Blød fade (~0.2 s).

## Acceptkriterier
- [x] `GridLineFader` (`game/scripts/building/grid_line_fader.gd`) styrer `line_strength`; byggestyrken læses fra materialet (0.16)
- [x] Vælg-værktøj → 0; alle andre værktøjer (sti, bygning, fjern, decor, personale) → fuld styrke
- [x] Lineær fade over 0.2 s, drevet af `BuildTool._process`
- [x] `BuildTool` finder Ground-materialet via `ground_path` (default `../Ground`); shaderen uændret
- [x] Test: `tests/test_grid_lines.gd`
- [x] test.sh 157/0, integration.sh OK
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/scripts/building/`. Må ikke røre simulation, audio, ui, props/ride_visual, shaderen.

## Log
- 2026-10-15 – gameplay: oprettet og udført. Fader i building-laget; set_tool opdaterer mål, _process fader. Starter skjult (vælg-værktøj). Status: review.
