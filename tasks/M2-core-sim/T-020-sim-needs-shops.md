# T-020: Simulation – Gæstebehov, butikker, toiletter, glæde

- **Status:** todo
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-019

## Mål
Gæster med behov, penge, glæde og tanker. Beslutningslogik som beskrevet i GDD (T-018). Butikker/toiletter genbruger Attraction (kind). Gæster betaler ved køstart; afviser hvis pris > deres vurdering (fx excitement-baseret) eller for få penge. Gæster forlader parken ved lav glæde/ingen penge/træthed.

## Acceptkriterier
- [ ] Tests: sulten gæst går til burgerbod og sulten falder; for dyr pris afvises med tanke; ingen penge → forlader; lukket bygning bruges ikke; deterministisk
- [ ] get_stats()
## Log
- 2026-10-15 – architect: oprettet
