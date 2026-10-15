# T-025: Simulation – Afstem med GDD-regler fra T-018

- **Status:** todo
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-018, T-020

## Mål
T-020 blev implementeret før GDD-reglerne var skrevet. Afstem med docs/gdd.md:
- Pris-vurdering: ride maks = 2 + excitement/5; bod maks = standardpris × (1 + behov/100); begge × (0.75 + glæde/200). Afvisning: "For dyrt!" og glæde −2.
- Startbehov tilfældige 0–30.
- Gæst går hjem når energi = 100 (ud over designers øvrige regler).
- Valg af forlystelse vægtes efter excitement.
- Boder øger toilet-behov via `satisfies`.
- Glæde-tab 0.02/tick pr. behov over threshold; går hjem under leave_happiness.

## Acceptkriterier
- [ ] Ovenstående implementeret, tal fra content (ikke hardcodet)
- [ ] Tests opdateret/tilføjet
- [ ] Afvigelser fra GDD noteret i loggen eller GDD rettet i samråd (notér)
## Log
- 2026-10-15 – architect: oprettet (race mellem T-018 og T-020)
