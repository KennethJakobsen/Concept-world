# T-025: Simulation – Afstem med GDD-regler fra T-018

- **Status:** done
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
- [x] Ovenstående implementeret, tal fra content (ikke hardcodet)
- [x] Tests opdateret/tilføjet
- [x] Afvigelser fra GDD noteret i loggen eller GDD rettet i samråd (notér)
## Log
- 2026-10-15 – architect: oprettet (race mellem T-018 og T-020)
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: afstemt med GDD: price_value(a, g=null) efter GDD-formler inkl. glæde-modifier; afvisning "For dyrt!" glæde −2 (både ved valg og ved ankomst); startbehov 0–30; hjem ved glæde < leave_happiness, penge < billigste åbne pris (cheapest_open_price()) eller energy ≥ 100; energy indgår nu som behov (forlystelser med energy<0 kan vælges); vægtet forlystelsesvalg efter excitement (min. vægt 1); tanker "Jeg skal tisse!" og "Jeg vil hjem." for alle hjemgangsårsager. Tests: +5 i test_guest_needs.gd, +1 tjek i test_economy.gd (karrusel = 7 ved glæde 50); 43/43 grøn.
- 2026-10-15 – simulation: Afvigelser/noter: GDD-konstanterne (2, 1/5, 0.75, 1/200, −2, 30, 100) står ikke i content-filerne; de ligger som defaults i Balance og kan overskrives via valgfrie nøgler i guests.json (ride_price_base, ride_price_per_excitement, happiness_price_base, happiness_price_factor, reject_happiness_penalty, need_start_max, leave_energy) – designer kan tilføje dem. Pre-filtrering: bygninger over betalingsvilje afvises allerede ved beslutningen (med tanke/−2, én gang pr. bygning indtil næste gennemførte besøg), så gæsten ikke går forgæves. Bodens behov i formlen = højeste af gæstens behov som boden dækker. Tankerne "Jeg har ikke flere penge."/"Jeg er træt…" er erstattet af GDD's "Jeg vil hjem.".
- 2026-10-15 – qa: godkendt (45/45 tests, smoke uden fejl, web-build ok, kontrakt tjekket). → done
