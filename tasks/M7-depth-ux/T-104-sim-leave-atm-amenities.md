# T-104: Sim: gå hjem, hæveautomat, spande, bænke og lys

- **Status:** done
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-103

## Mål
Kontraktens §1 T-104 (GDD §3 og §9). Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `LEAVING`-tilstand med tanker. Gæsten køber ikke og står ikke i kø
- [x] ATM-hævning (seedet), gebyr `atm_fees`, maks 2 pr. besøg
- [x] Spandens fyldniveau og overløb, bænk med 2 pladser, lys om natten og straf på mørke stier
- [x] Signaler fra kontrakten og `litter_at`. Udvider `_v3_to_v4`

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – simulation: in-progress → review. `Guest.leaving/leave_reason` (tired/no_money/unhappy; tanken er fortsat "Jeg vil hjem."), `atm_uses`, `resting_on`. ATM: gæst uden penge går til nærmeste automat inden for `range_cells` (glæde ≥ `min_happiness`, maks `max_per_visit`), hævning med sim-RNG, gebyr → `atm_fees`, signal `atm_used`; ATM tæller ikke i billigste pris/tiltrækning. Spande: `bin_capacity(d)` (decor `capacity`), `set_bin_fill`, `bin_state_changed` (0/1/2), fuld spand → affaldet lægges på spandens celle. Bænk: `seats` (default 2), `guest_sat/guest_stood`, `bench_occupants/bench_free_seats/bench_seat`. Lys: `ParkWorld.light_level(cell)` (dag 1 / gry+skumring 0,5 / nat 0 + lygter i aura_radius), `dark_path_penalty_per_tick` på mørke stier, lygtens `night_aura` om natten. `litter_at(cell)`, `decor_info(id)`, sim-signal `litter_changed(cell)`. `_v3_to_v4` udvidet (guests leaving/leave_reason/atm_uses/resting_on, decor fill). Økonomikategorier `atm_fees` (+ `rewards` til T-105). Tests: `test_m7_amenities.gd` (8).
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
