# T-085: Sim: sideshows og præmier

- **Status:** done
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-084

## Mål
Mekanik D (kontrakt §2). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `kind: sideshow` med kø, pris og gevinst via sim-RNG
- [x] `"prizes"` i økonomien, `prizes_won` gemmes (udvider `_v2_to_v3`)
- [x] Signalet `prize_won`, og `attraction_stats` er udvidet
- [x] Tests for gevinstfrekvens (seedet) og økonomi

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – simulation: implementeret. `AttractionDef.win_chance/prize_cost/prize_happiness/prize_item`, `Attraction.prizes_won/prize_cost_total/is_sideshow()`. Sideshows indgår i gæsternes forlystelsesvalg (vægtet efter excitement, tæller som et besøg) og prissættes som shops. Gevinst via sim-RNG → `economy.charge(prize_cost, "prizes")`, glæde, `Guest.items` (via `_give_item`, som T-086 udvider) og signal `prize_won`. Tab → excitement som glæde. Nye API'er: `ParkSim.attraction_stats(id)` og `ParkSim.finance_report()` (fandtes ikke før), `Economy.CATEGORIES`. `_v2_to_v3` udvidet med `prize_cost_total`. Tests: test_sideshow.gd. test.sh og integration.sh grønne.
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. → done
