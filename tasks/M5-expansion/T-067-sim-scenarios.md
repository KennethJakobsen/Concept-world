# T-067: Sim – scenarier, mål, sejr/nederlag

- **Status:** todo
- **Milepæl:** M5
- **Agent:** simulation
- **Afhænger af:** T-065, T-066

## Mål
Implementér `_CONTRACT.md` §2.

## Acceptkriterier
- [ ] `ScenarioDef.from_json` og `ScenarioDef.list_all()` (sorteret efter `order`)
- [ ] `ParkSim.new_from_scenario` sætter kort, penge, omdømme, entré, start-bygninger og unlocks op
- [ ] `Scenario`-evaluering i `_end_day`: alle 6 objective-typer, deadline og `money_below`/`reputation_below` med streak. Sejr vinder over nederlag samme dag. Ingen yderligere evaluering efter afslutning
- [ ] `scenario_status()`, `scenario_finished(won, reason)` og `park_value()`
- [ ] Tests for hver objective-type, deadline, lose-streak (nulstilles ved bedring) og save/load midt i et scenarie
- [ ] Gamle saves (`scenario = null`) opfører sig som sandbox
- [ ] `tools/test.sh` og `tools/balance.sh` er grønne. `balance.sh` får et scenarie-run pr. scenarie (vindes det med en simpel bot-strategi eller ej? Skriv det i loggen)

## Ejer / må ikke røre
Som T-066.

## Log
- 2026-10-15 – architect: oprettet
