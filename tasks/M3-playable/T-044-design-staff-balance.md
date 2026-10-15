# T-044: Design – Personale-balance

- **Status:** done
- **Milepæl:** M3
- **Agent:** designer
- **Afhænger af:** T-041

## Mål
QA-fund (T-041): uden nedbrud er personale ren udgift; mekaniker-inspektion giver 0 nedbrud (for stærk); én ødelagt forlystelse dræber en startpark. Justér content (staff_rules.json, staff/, rides): større affaldsstraf, svagere inspektionsbonus, evt. lavere løn. Iterér med ./tools/balance.sh (T-041-sektion, 5 seeds).

## Acceptkriterier
- [x] Med personale > uden personale i gennemsnit over 5 seeds (dag 7)
- [x] Med mekaniker: nedbrud sker stadig af og til, men repareres
- [x] Break-even med personale omkring dag 4
## Log
- 2026-10-15 – architect: oprettet efter QA-fund
- 2026-10-15 – designer: mekaniker-løn 80→60, rengøring 60→45, inspection_reliability_bonus 0.01→0.002, inspect_interval 1200→2400, happiness_penalty_dirty_per_tick 0.05→0.15. balance.sh (T-041, 5 seeds, dag 7):

| | Penge d7 | Omdømme | Gæster | Glæde | Nedbrud | Ødelagt-dage |
|---|---|---|---|---|---|---|
| Uden (snit) | 982 | 58.3 | 204 | 71.8 | 0.8 | 3.97 |
| Med (snit) | 4309 | 75.4 | 373 | 83.2 | 1.0 | 0.06 |

  Med mekaniker: 0–2 nedbrud pr. seed, repareret (≤0.12 ødelagt-dage). Break-even med personale dag 4 (kumuleret -445 dag 3, +238 dag 4). Seed 12345 uden nedbrud: uden personale er stadig ~830 rigere, men omdømmet er 16 lavere – acceptabelt trade-off. Punkt 3 (tilgivelse ved eneste ødelagte ride) ikke adresseret – kræver kode. test.sh 117/117. → review
- 2026-10-15 – qa: test.sh 117/117, integration OK, balance.sh reproducerer tal, smoke main_menu/main uden fejl → done
