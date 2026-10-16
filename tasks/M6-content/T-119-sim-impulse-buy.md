# T-119: Sim: impulskøb i butikker uden behov (ballon, souvenir)

- **Status:** review
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
