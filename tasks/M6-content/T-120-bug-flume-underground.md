# T-120: Bug: tømmerrenden går under terræn ved fald

- **Status:** in-progress
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-090, T-092

## Mål
Brugerrapport (screenshot): ved faldstykket (`flume_drop`) dykker truget ned under terrænet. Find årsagen (sim tillader level < 0 / forkert `min_level`/`rise`-håndtering, eller mesh/scene tegner højden forkert) og ret den. Hvis sim: faldet skal afvises med `too_low` (eller stationen ligge højt nok), så banen aldrig går under jorden. Hvis det er mesh/højde-mapping i grafik eller bridge: rapportér præcist, så det kan sendes videre.

## Acceptkriterier
- [ ] Ingen bane kan placeres under terræn (alle sporsystemer)
- [ ] Test, der reproducerer fejlen
- [ ] Eksisterende saves med ugyldige baner håndteres uden crash

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens screenshot
