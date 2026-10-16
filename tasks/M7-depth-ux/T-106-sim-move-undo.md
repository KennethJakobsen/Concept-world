# T-106: Sim: flyt (også sporbaner), sælg-refusion og fortryd

- **Status:** review
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-105

## Mål
ADR-005 §4–5 og kontraktens §1 T-106. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `cmd_move_attraction`/`preview_move` for alle kinds, også coaster/flume/train/transport som helhed med 90°-rotation
- [x] `sell_refund` med 100 % inden for vinduet uden kunder
- [x] `UndoStack` med 20 skridt, undo/redo og præcise penge. Ugyldigt inverse giver `ok=false`
- [x] Tests: hver fortrydelig kommando, flyt af svævebane genopbygger links, ratings er uændrede

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – simulation: implementeret. `UndoStack` (`simulation/commands/undo_stack.gd`, 20 trin fra `park.json.undo_steps`), `cmd_undo/redo`, `can_undo/redo`, `undo_label/redo_label`, signal `undo_changed`. Fortrydes: sti, køsti (byg/fjern), bygning, sporbane som helhed (posten oprettes ved `cmd_finish_coaster`), pynt (byg/fjern/flyt), flyt, sælg, pris, config og opskrift. Pris/config på samme felt i træk slås sammen til én post. Inverse fejl (`occupied`, `no_money`, `missing`) lader posten ligge. Pengene føres tilbage i samme kategori som originalen. `cmd_move_attraction`/`preview_move` med absolut rotation 0..3 (`Attraction.rotation`, gemt, default 0): flade bygninger drejer footprint/indgang, sporbaner flyttes stift og drejes om stationen, transport-links genopbygges, ratings uændrede. Signal `attraction_moved(id)` (+ `coaster_changed` for baner). `cmd_move_decor`. `sell_refund` (100 % inden for `sell_full_refund_ticks` uden kunder, `Attraction.built_tick`, gemt, migreres til 0). Begrænsninger: fjernet pynt på en fjernet sti genskabes ikke ved fortryd; stykke-for-stykke banebyg fortrydes med backspace som før. Tests: `test_m7_move_undo.gd` (12). `test_economy`/`test_coaster` tilpasset den nye refusion. test/integration/balance grønne.
