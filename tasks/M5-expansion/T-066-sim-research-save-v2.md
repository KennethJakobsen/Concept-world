# T-066: Sim – forskning og save v2

- **Status:** review
- **Milepæl:** M5
- **Agent:** simulation
- **Afhænger af:** – (brug defaults/test-fixtures, indtil T-065 lander)

## Mål
Implementér `_CONTRACT.md` §1 (forskning) og §4 (save-version 2 med migration for alle M5-nøgler, så T-067/T-068 kun udfylder dem).

## Acceptkriterier
- [x] `ResearchDef`, `Research` og `ParkSim.research` med `is_unlocked`, `cmd_set_research_funding`, `cmd_set_research_priority`, `research_status`, `research_unlocked` og `warning(&"research_done")`
- [x] Daglig progress og omkostning bogført som `"research"`. Valget af næste item er deterministisk og respekterer prioritet
- [x] Placering af låste attraktioner/decor afvises. `enabled = false` betyder, at alt er låst op
- [x] `SaveMigrations.CURRENT = 2` med `_v1_to_v2`. En v1-fixture i `game/tests/fixtures/` indlæses uden tab, og gammel adfærd bevares (alt er låst op)
- [x] Round-trip- og determinisme-test med forskning i gang
- [x] Test af, at alle id'er i `research.json` findes i kataloget (springes over med en note, hvis filen mangler)
- [x] `tools/test.sh`, `tools/integration.sh` og `tools/balance.sh` er grønne

## Ejer / må ikke røre
Ejer: `game/simulation/`, sim-tests og fixtures i `game/tests/`. Må ikke røre `game/scripts/`, `game/scenes/` og `game/content/`.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: implementeret. `game/simulation/research/` (`ResearchDef` med defaults fra kontrakten, når `research.json` mangler, og `Research`). `ParkSim.research` er som default slået fra (alt låst op). T-067 slår den til via `setup(true, extra)`. Låste id'er afvises i `cmd_place_attraction`/`cmd_place_decor`. Daglig forskning bogføres som `"research"`. `SaveMigrations.CURRENT = 2` med `_v1_to_v2`, fixture `game/tests/fixtures/save_v1.json`. Tests i `test_research.gd`. `test_economy` accepterer nu `kind "coaster"` (wooden_coaster.json fra T-065). test/integration/balance er grønne.
