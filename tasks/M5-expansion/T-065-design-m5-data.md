# T-065: Data – forskning, scenarier, rutsjebane

- **Status:** todo
- **Milepæl:** M5
- **Agent:** designer
- **Afhænger af:** –

## Mål
Lever alt indhold til M5 efter `_CONTRACT.md` §0, og beskriv systemerne i `docs/gdd.md`.

## Acceptkriterier
- [ ] `research.json` med emner, items (mindst 8, der dækker de eksisterende forlystelser, butikker og decor samt coaster-stykker) og `start_unlocked`
- [ ] `scenarios/` med mindst 3 scenarier i stigende sværhedsgrad plus `sandbox.json`. Hvert scenarie bruger mindst 2 forskellige objective-typer, og mindst ét af dem har `coaster_excitement_min`
- [ ] `coaster/pieces.json` (mindst de 7 stykker fra kontrakten), `coaster/trains.json`, `coaster/ratings.json`, `attractions/wooden_coaster.json`
- [ ] Alle id'er krydsrefererer korrekt (verificeres af testen i T-066/T-067). Kun ASCII og danske bogstaver, der findes i fonten
- [ ] GDD: afsnit om forskning, scenarier og rutsjebane, inklusive rating-formlen i ord og en tabel over scenarie-mål
- [ ] Efter T-068: balance-noter for en "typisk" oval rutsjebane (forventede ratings) i loggen

## Ejer / må ikke røre
Ejer: `game/content/**`, `docs/gdd.md`. Må ikke røre kode.

## Log
- 2026-10-15 – architect: oprettet
