# T-119: Sim: impulskøb i butikker uden behov (ballon, souvenir)

- **Status:** done
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-095

## Mål
Ballonbåsen og Mindebutikken får 0 besøg, fordi gæster kun går i butikker for at dække et behov (fund i T-095). Tilføj impulskøb: gæster, der passerer/er tæt på en butik med `carry_item` (eller uden behov), kan købe med en sandsynlighed afhængig af glæde, penge, pris og om de allerede har tingen. Parametre i data (med defaults i kode), sim-RNG, deterministisk.

## Acceptkriterier
- [x] Butikker uden behov får besøg via impulskøb; ingen gæst køber samme ting to gange
- [x] Parametre læses fra data med defaults
- [x] Tests (seedet) for frekvens og determinisme

## Log
- 2026-10-16 – orkestrator: oprettet ud fra T-095
- 2026-10-16 – simulation: `_try_impulse` i `_choose_goal` (efter akutte behov, før forlystelser): nærmeste åbne shop med `carry_item`, som gæsten ikke har, inden for radius (sti-celler); chance = base × glæde/100 × (1 − pris/penge × price_sensitivity), sim-RNG. Respekterer `_usable` (pris/kø). Tests: `tests/test_impulse_buy.gd`.
  Nye parametre til designer (`guests.json`, defaults i `Balance`): `"impulse": {"base_chance": 0.35, "radius": 12, "min_happiness": 40, "price_sensitivity": 1.0}`.
  test.sh: 302/303 – eneste fejl er `test_research_ids_exist_in_catalog` (research.json, designers parallelle arbejde). integration.sh OK.
- 2026-10-16 – simulation (opfølgning T-119): sporstykker fra ikke-coaster-systemer (flume_*, train_*, monorail_* inkl. stationer) regnes som låst op, når en bane af systemet er låst op (`ParkSim.is_unlocked`). Rutsjebanestykker forskes fortsat individuelt. Test: `test_research.gd::test_flume_pieces_follow_ride_unlock`. test.sh 304/304, integration OK.
  - 2026-10-16 – designer (T-095): `impulse` tilføjet i guests.json (0.35/12/40/1.0, uændret). Måling i en park med alle 13 forlystelser og alle butikker, 5 dage, seeds 1/2/3: Ballonbåsen 0/0/0 → 179/203/182, Mindebutikken 0/0/0 → 114/134/96 (ca. 1070 gæster i alt). Besøg på forlystelser 1588/1606/1564 → 1568/1508/1487 (−1 til −6 %). Øvrige boder er stort set uændrede. balance.sh 5/5 i alle tre scenarier (scenarie-botten bygger ikke ballon- og souvenirbutikker, så resultaterne er de samme som før). test.sh 304/0.
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. → done
