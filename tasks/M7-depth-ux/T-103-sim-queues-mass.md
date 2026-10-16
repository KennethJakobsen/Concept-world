# T-103: Sim: køstier, tålmodighed, ledig frem for optaget, gæstemasse

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-102

## Mål
ADR-005 §1–3 og kontraktens §1 T-103. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [ ] `QUEUE`-celler, som `PathFinder` ikke følger. Kapaciteten er celler × slots, og default er 4
- [ ] Tålmodighed, opgivelse og underholdning halverer tabet
- [ ] Valg med `afstand + kø × queue_weight_cells`, fyldte springes over
- [ ] Belægning maks 6 pr. celle, omlægning efter 20 ticks og trængsel efter 200 ticks
- [ ] Udvider `_v3_to_v4`. Determinismetest med 500 gæster og ≤ 4 ms/tick-benchmark

## Log
- 2026-10-16 – architect: oprettet (T-098)
