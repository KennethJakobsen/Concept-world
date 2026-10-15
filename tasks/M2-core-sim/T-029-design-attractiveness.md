# T-029: Design – Tiltrækning, omdømme og gæstestrøm

- **Status:** todo
- **Milepæl:** M2
- **Agent:** designer
- **Afhænger af:** T-026

## Mål
Antal besøgende skal afhænge af parkens kvalitet. Design model + tal i `game/content/park.json` og GDD-sektion.

## Kontrakt (simulation implementerer præcis dette)
- **attraction_score** = Σ over åbne rides: excitement × weight_ride + Σ åbne shops/toilets × weight_facility. Faldende merværdi (fx sqrt eller log) så 20 karruseller ikke er uendeligt godt.
- **reputation** (0..100), start `reputation_start`. Når en gæst forlader parken: reputation += (guest.happiness − reputation) × `reputation_learn_rate`.
- **price_penalty** fra entré vs. forventet entré (`expected_entry_fee_per_score` × attraction_score).
- **spawn rate** (gæster pr. dag) = f(attraction_score, reputation, price_penalty), med minimum `spawn_min_per_day` når der er sti og mindst én åben forlystelse, ellers 0 (ingen forlystelser → ingen gæster).
- **max_guests** = `max_guests_base` + Σ kapacitet af åbne bygninger × `max_guests_per_capacity`.
- Ankomst sker stokastisk (seedet RNG) med middelrate = spawn rate.
- Alle konstanter i park.json. Formler i GDD med eksempeltabel: 1 karrusel / 3 rides+boder / 7 bygninger × omdømme 30/60/90.

## Acceptkriterier
- [ ] park.json + GDD-sektion
- [ ] Startpark (karrusel + 2 boder + toilet) giver omtrent samme gæstestrøm som nu (~50/dag), så T-026-balancen holder; fuld park giver tydeligt flere
## Log
- 2026-10-15 – architect: oprettet efter brugerønske
