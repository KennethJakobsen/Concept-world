# T-033: Simulation – Fuld park går i stå (glæde styrtdykker)

- **Status:** done
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-030

## Mål
QA (T-032): fuld park (alle 7 bygninger) rammer 96/96 fra dag 2, glæde falder 78→47 og omdømme 78→36. Find årsagen (kø-længder? gæster der ikke kan gå hjem? behov uden kapacitet? afvisninger der loopér?) med instrumentering i balance_sim, og ret den.
Overvej: maks kølængde pr. bygning (gæst vælger andet ved fuld kø), "Køen er for lang!"-tanke, at utilfredse gæster faktisk forlader parken, og at max_guests ikke overstiger hvad bygningerne kan betjene.

## Acceptkriterier
- [x] Årsag dokumenteret i loggen med tal
- [x] Fuld park: glæde holder sig > 65 og omdømme stiger/holder over 5 dage
- [x] Regressionstest
## Log
- 2026-10-15 – architect: oprettet efter QA-fund
- 2026-10-15 – simulation: startet; instrumentering i balance_sim (tilstande, kølængder, behov over tærskel, tanker pr. dag for fuld park).
- 2026-10-15 – simulation: **Årsag** (QA-layout, dag 2–5): pariserhjul (indgang y=54) og radiobiler (indgang y=55) var ikke forbundet til stinettet, men talte alligevel med i attraction_score (11.18) og max_guests (96). Reelt kørte kun karrusellen (kap. 8 / 200 ticks): kø 42–60 gæster, 64–74 af 96 gæster i QUEUING; mens de stod i kø steg sult/tørst/toilet (dag 4: hunger 32, thirst 31, toilet 30 over tærskel) og toilettet fik kø 16–23. Kø-gæster kunne aldrig opgive køen og blev ved med at miste glæde → glæde 47, omdømme 36. Altså tre sim-fejl: (1) unåelige bygninger tæller, (2) ubegrænsede køer, (3) utilfredse gæster i kø går ikke hjem.
- 2026-10-15 – simulation: **Rettelser:** (1) `is_reachable(a)`/`is_operating(a)` (BFS fra indgangen, cachet, invalideres ved tile_changed) – kun åbne OG nåbare bygninger tæller i attraction_score, max_guests og "≥1 åben forlystelse". (2) Kø-loft `capacity × queue_max_cycles`; fuld kø fravælges ved beslutning, og ved ankomst afvises med tanken "Køen er for lang!" (ParkSim.QUEUE_FULL_THOUGHT) og glæde −queue_full_happiness_penalty. (3) Gæst i kø med glæde < leave_happiness forlader køen og går hjem. balance_sim: fuld park har nu sti til pariserhjul/radiobiler; QA's gamle layout køres som ekstra scenarie.
- 2026-10-15 – simulation: **Før/efter** (balance.sh, 5 dage):
  - Før, QA-layout (T-032): glæde 78→71→51→47→57, omdømme 69→79→72→37→36, 96/96 fra dag 2.
  - Efter, samme QA-layout: score 6.71, max 52; glæde 80→85→83→84→81, omdømme 54→58→63→67→71, kø karrusel ≤ 24.
  - Efter, fuld park med forbundne stier: glæde 79→88→86→86→86, omdømme 54→63→70→77→82, gæster 55–86/96, netto +1236…+1809/dag.
  - Startpark uændret i opførsel (glæde 80–86, omdømme 54→70); entré 30 uændret (10/dag).
  (Designer har samtidig ændret park.json i T-034 – tallene er målt med den aktuelle fil.)
- 2026-10-15 – simulation: **Nye Balance-defaults til designer** (valgfri nøgler i park.json): `queue_max_cycles` = 3.0 (0 = ubegrænset), `queue_full_happiness_penalty` = 1.0. Ny API: `is_reachable(a)`, `is_operating(a)`, `is_queue_full(a)`, `QUEUE_FULL_THOUGHT`. Rettede også en ObjectDB-lækage (lambda-forbindelse → metode). Regressionstests: test_crowding.gd (5, inkl. QA-layoutet med rigtigt content over 3 dage: glæde > 65, omdømme ≥ start, kø ≤ loft). 66/66 grøn.
- 2026-10-15 – qa: godkendt. Import ok, test 66/66, smoke 300 frames uden ERROR, web-build ok. balance: startpark omdømme 53.8→70.0, kumuleret netto −204 dag 3/+571 dag 4; fuld park glæde 79–88, omdømme 53.7→82.1; QA-layout glæde 80–85, omdømme →71. HUD viser g.thought direkte fra sim ("Køen er for lang!" via ParkSim.QUEUE_FULL_THOUGHT). → done
