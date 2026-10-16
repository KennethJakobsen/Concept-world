# T-150: balance_sim måler M7-mekanik

- **Status:** done
- **Milepæl:** M7
- **Agent:** qa
- **Afhænger af:** T-117

## Mål
`balance.sh` måler endnu ikke T-117's mål. Designeren målte dem med et midlertidigt script og skal kunne gentage målingerne. Tilføj sektionen `=== T-117: M7-balance ===` i `game/tools/balance_sim.gd`:
1. **Salt:** startpark + `fries_stand` med og uden opskriften `salt`. Drikkebodens salg (`purchase_made`) over 5 dage og 5 seeds, både samlet og i %.
2. **Køopgivelser:** fuld park med personale. Antal gæster, der går fra QUEUING til WALKING med tanken `queue_gave_up`, divideret med antal kø-indtrædener.
3. **ATM:** fuld park med og uden `atm`. `_total_revenue()` over 5 dage og 3 seeds, i %.
4. **Milepæle:** `green_meadow`-bot. Den dag hver `milestone_achieved` udløses.

## Acceptkriterier
- [x] De fire målinger udskrives, og `balance.sh` er stadig grøn

## Log
- 2026-10-16 – designer: oprettet fra T-117
- 2026-10-16 – simulation: `_m7_balance()` i balance_sim.gd (sektionen `=== T-117: M7-balance ===`, ca. 1 min). Parklayoutet er flyttet ud i `_build_park()`, og `_scenario_run` har fået et valgfrit milepæl-dict. Første tal: salt −1,2 % drikkesalg (1956→1932), køopgivelser 0/1951, ATM −5,4 %, milepæle green_meadow: guests_100/stars_3/clean_park dag 2, first_thrill dag 5, sideshow_ready dag 11. balance.sh er grøn (15½ min i alt).
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
