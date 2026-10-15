# T-067: Sim – scenarier, mål, sejr/nederlag

- **Status:** done
- **Milepæl:** M5
- **Agent:** simulation
- **Afhænger af:** T-065, T-066

## Mål
Implementér `_CONTRACT.md` §2.

## Acceptkriterier
- [x] `ScenarioDef.from_json` og `ScenarioDef.list_all()` (sorteret efter `order`)
- [x] `ParkSim.new_from_scenario` sætter kort, penge, omdømme, entré, start-bygninger og unlocks op
- [x] `Scenario`-evaluering i `_end_day`: alle 6 objective-typer, deadline og `money_below`/`reputation_below` med streak. Sejr vinder over nederlag samme dag. Ingen yderligere evaluering efter afslutning
- [x] `scenario_status()`, `scenario_finished(won, reason)` og `park_value()`
- [x] Tests for hver objective-type, deadline, lose-streak (nulstilles ved bedring) og save/load midt i et scenarie
- [x] Gamle saves (`scenario = null`) opfører sig som sandbox
- [x] `tools/test.sh` og `tools/balance.sh` er grønne. `balance.sh` får et scenarie-run pr. scenarie (vindes det med en simpel bot-strategi eller ej? Skriv det i loggen)

## Ejer / må ikke røre
Som T-066.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: implementeret. `game/simulation/scenario/` indeholder `ScenarioDef` (`from_dict`, `from_json`, `find`, `list_all`, hvor `.remap` håndteres) og `Scenario` (state, streaks og `evaluate_day`). `ParkSim.new_from_scenario` placerer start-bygninger gratis (pengene sættes bagefter) og flytter indgangen via den nye `ParkWorld.set_entrance`. Den kalder `research.setup(enabled, start.unlocked)`. `scenario == null` i sandbox (inkl. `sandbox.json`) og for gamle saves. API'et består af `scenario_status()`, `scenario_finished`, `park_value()`, `rides_count()` og `max_coaster_excitement()` (læser `Attraction.ratings`, et felt jeg har tilføjet nu, og som T-068 udfylder/gemmer). Evalueringen sker i `_end_day` efter `economy.close_day`. Ved load slås def'en op via `ScenarioDef.find(def_id)` (eller `from_save`'s `p_defs`). Tests ligger i `test_scenario.gd` (200 i alt er grønne). integration og balance er grønne.
  - **Decor-format (T-065-note):** jeg har accepteret designerens `{"def", "cell"}` (samme nøgle som attraktioner). `"def_id"` accepteres som alias. Personale: `{"type", "cell"}`. Alle start-placeringer i de 4 scenarier lykkes (testes).
  - **Data-observation til designer:** I green_meadow (karrusel-indgang (26,45)) og river_valley (karrusel-indgang (34,61)) er start-karrusellens indgang ikke forbundet til start-stien, så den kan ikke nås, før spilleren lægger én sti-celle.
  - `park_value` medregner decor og trækker ikke lån fra, fordi der ikke findes lån i M5 (`start.loan` parses, men bruges ikke).
  - **Balance-bot** (`game/tools/balance_sim.gd`, run pr. scenarie): botten lægger sti + gade og bygger hver morgen den billigste ulåste bygning med 2000 i reserve. Med forskningsfinansiering 0 taber den alle tre: green_meadow på frist (61/150 gæster, omdømme 33), river_valley på frist (3 forlystelser, 354 kr.) og mountain_peak på `money_below` på dag 57. Med finansiering 1 (500/dag) går den fallit tidligere (dag 37/30/14). Scenarierne vindes altså ikke med en naiv strategi. Coaster-målene kan først opfyldes efter T-068. Forskningsprisen på 500/dag er tung i forhold til den tidlige indtjening, så designeren bør kigge på det.
  - Ikke dækket: kontrakten nævner, at `list_all` i en eksporteret build skal testes i integration.sh. Det ligger i `tools/` (QA) og bør tages i T-072.
- 2026-10-15 – qa (T-072): Scenarier, sejr/nederlag og list_all i eksporteret pck (integration.sh) er ok. test.sh (235/236. Den eneste fejl er test_ui_m5, se T-077), integration.sh (inkl. ny pck-test af ScenarioDef.list_all), balance.sh, build_web.sh og smoke er grønne. Acceptkriterierne er verificeret, og test_qa_m5.gd dækker dem også. Godkendt.
