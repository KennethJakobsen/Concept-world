# T-110: Gameplay: køsti-, flyt-, rotér- og fortryd-værktøjer

- **Status:** review
- **Milepæl:** M7
- **Agent:** gameplay
- **Afhænger af:** T-106, T-109, T-101

## Mål
Kontraktens §3 T-110. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Køsti-værktøj, flyt (M) og rotér (R), også for sporbaner
- [x] Ctrl+Z / Ctrl+Shift+Z og ghost med pris og palet-farver
- [x] Sælg viser refusion. Afbrudte stier markeres røde
- [x] Gameplay-tests og `integration.sh` er grønne

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – gameplay: implementeret i `BuildTool`. Køsti fandtes (T-140). Nyt værktøj `move` (tast M): klik løfter bygning/sporbane (som helhed)/pynt, R roterer 90° (absolut rotation til `cmd_move_attraction`, `Attraction.rotated_size` til centrering), klik placerer, højreklik/Esc slipper. Ghost = `preview_move`-celler + indgang i `ParkColors.ghost`-farver. Ctrl/Cmd+Z = `cmd_undo`, Ctrl/Cmd+Shift+Z eller Ctrl+Y = `cmd_redo` (signal `undo_performed(redo, ok, label)`, error-lyd ved fejl). Pris-label (Label3D `GhostPrice`) ved musen for bygning/pynt/sti/køsti; Fjern viser "Sælg +$N" fra `sell_refund` før klik, og den flydende refusion bruger nu også `sell_refund`. Afbrudte stier (BFS fra porten, `BuildTool.disconnected_paths`) markeres røde i 4 s efter flyt/salg/fortryd og altid i flyt-værktøjet. ParkView: lytter på `attraction_moved` (genposition + rotation af flade bygninger, `_pose_attraction`; `_attraction_pos` bruger `footprint_size()`), crowd-delen er ikke rørt. BuildDock: medaljonen "Flyt (M)" tilføjes fra BuildTool via eksisterende `add_card(id, …, cat "")` (ingen ændring i UI-koden; Hud videresender `card_pressed`). Ikon `tool_move` findes ikke → tekst "M" som fallback (UI kan tilføje ikon). Tests: `test_build_tools_m7.gd` (6). test (435/0), integration og smoke grønne. Visuel kontrol (ghost, rotation af modeller, røde stier) kræver brugerens øjne.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
