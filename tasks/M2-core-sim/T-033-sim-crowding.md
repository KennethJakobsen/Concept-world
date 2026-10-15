# T-033: Simulation – Fuld park går i stå (glæde styrtdykker)

- **Status:** todo
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-030

## Mål
QA (T-032): fuld park (alle 7 bygninger) rammer 96/96 fra dag 2, glæde falder 78→47 og omdømme 78→36. Find årsagen (kø-længder? gæster der ikke kan gå hjem? behov uden kapacitet? afvisninger der loopér?) med instrumentering i balance_sim, og ret den.
Overvej: maks kølængde pr. bygning (gæst vælger andet ved fuld kø), "Køen er for lang!"-tanke, at utilfredse gæster faktisk forlader parken, og at max_guests ikke overstiger hvad bygningerne kan betjene.

## Acceptkriterier
- [ ] Årsag dokumenteret i loggen med tal
- [ ] Fuld park: glæde holder sig > 65 og omdømme stiger/holder over 5 dage
- [ ] Regressionstest
## Log
- 2026-10-15 – architect: oprettet efter QA-fund
