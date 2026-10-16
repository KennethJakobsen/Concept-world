# T-103: Sim: køstier, tålmodighed, ledig frem for optaget, gæstemasse

- **Status:** review
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-102

## Mål
ADR-005 §1–3 og kontraktens §1 T-103. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `QUEUE`-celler, som `PathFinder` ikke følger. Kapaciteten er celler × slots, og default er 4
- [x] Tålmodighed, opgivelse og underholdning halverer tabet
- [x] Valg med `afstand + kø × queue_weight_cells`, fyldte springes over
- [x] Belægning maks 6 pr. celle, omlægning efter 20 ticks og trængsel efter 200 ticks
- [x] Udvider `_v3_to_v4`. Determinismetest med 500 gæster og ≤ 4 ms/tick-benchmark

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – simulation: startet.
- 2026-10-16 – simulation: færdig → review. `ParkWorld.Tile.QUEUE` (+ alias `CellKind`), `cmd_place_queue_path/cmd_remove_queue_path` (15/7 kr), `Attraction.queue_cells` (kæde fra indgangen, stopper ved forgrening/anden kø; genberegnes straks ved tile-ændring), `queue_capacity(a)`, `approach_cell(a)` (sti ved køens ende), `queue_slot_cell/queue_slot_position`, `guest_position(id)`, `guest_lane_offset(id)`, `wait_ticks_estimate`, `occupancy(cell)`, `crowded_cells()`, signal `queue_changed`. Guest: `patience`, `queue_index`, `blocked_ticks` (gemt). Afvigelser/præciseringer: (1) uden køsti er kapaciteten som før M7 `max(queue_default_max, ceil(kapacitet × queue_max_cycles))` – ellers kan en karrusel (8 pladser) aldrig fylde en tur med 4 i kø; med køsti er den celler × slots. (2) Tålmodighed udledes af et hash (ingen RNG-forbrug). Når den er 0: glæde −queue_impatient_decay/tick og tanken `queue_bored`; når tabet når `queue_abandon_happiness`, opgiver gæsten (ingen refusion, tanke `queue_gave_up`). Underholder i nærheden halverer tabet. (3) ADR §3-scoren bruges til behovsbygninger; forlystelser vælges stadig vægtet efter excitement (fyldte springes over). (4) Belægning: modgående trafik bytter plads, og efter 3 × `crowd_reroute_ticks` presser gæsten sig forbi ved at bytte med én i cellen, så grænsen 6 holdes uden fastlåsning. Gæster fra en tur spredes til nabostier med plads. Højst 8 omlægnings-A* pr. tick. Benchmark: ca. 2,5–2,8 ms/tick med 500 gæster (headless), determinismetest med 500 gæster i `tests/test_m7_queues.gd`, og `balance.sh` printer en perf-sektion til sidst.
