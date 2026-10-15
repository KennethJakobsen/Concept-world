# T-020: Simulation – Gæstebehov, butikker, toiletter, glæde

- **Status:** review
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-019

## Mål
Gæster med behov, penge, glæde og tanker. Beslutningslogik som beskrevet i GDD (T-018). Butikker/toiletter genbruger Attraction (kind). Gæster betaler ved køstart; afviser hvis pris > deres vurdering (fx excitement-baseret) eller for få penge. Gæster forlader parken ved lav glæde/ingen penge/træthed.

## Acceptkriterier
- [x] Tests: sulten gæst går til burgerbod og sulten falder; for dyr pris afvises med tanke; ingen penge → forlader; lukket bygning bruges ikke; deterministisk
- [x] get_stats()
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: startet. GDD (T-018) havde endnu ingen beslutningsregler – implementeret efter kontrakt/task; tilpasses når GDD er klar.
- 2026-10-15 – simulation: behov stiger pr. tick, glæde falder pr. behov over tærskel. Beslutning: forlad ved penge<=0 / glæde<=leave_happiness / energy>=tærskel; ellers mest akutte behov (ikke energy) → nærmeste åbne bygning der dækker det; ellers tilfældig åben forlystelse (rides_left) ; ellers vandring/hjem. Betaling ved køstart; afvisning hvis lukket, pris > værdi (ticket_price(default)*price_tolerance + excitement*excitement_value, min 1) eller for få penge, med tanke. Endt besøg anvender satisfies, glæde += excitement (+bonus ved dækket behov). Valgfri nøgler i guests.json: need_start_max, price_tolerance, excitement_value, reject_happiness_penalty, need_relief_happiness. Tests: test_guest_needs.gd (7). → review
