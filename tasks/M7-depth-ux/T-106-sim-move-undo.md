# T-106: Sim: flyt (også sporbaner), sælg-refusion og fortryd

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-105

## Mål
ADR-005 §4–5 og kontraktens §1 T-106. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [ ] `cmd_move_attraction`/`preview_move` for alle kinds, også coaster/flume/train/transport som helhed med 90°-rotation
- [ ] `sell_refund` med 100 % inden for vinduet uden kunder
- [ ] `UndoStack` med 20 skridt, undo/redo og præcise penge. Ugyldigt inverse giver `ok=false`
- [ ] Tests: hver fortrydelig kommando, flyt af svævebane genopbygger links, ratings er uændrede

## Log
- 2026-10-16 – architect: oprettet (T-098)
