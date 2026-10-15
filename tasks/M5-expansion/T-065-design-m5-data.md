# T-065: Data – forskning, scenarier, rutsjebane

- **Status:** done
- **Milepæl:** M5
- **Agent:** designer
- **Afhænger af:** –

## Mål
Lever alt indhold til M5 efter `_CONTRACT.md` §0, og beskriv systemerne i `docs/gdd.md`.

## Acceptkriterier
- [x] `research.json` med emner, items (mindst 8, der dækker de eksisterende forlystelser, butikker og decor samt coaster-stykker) og `start_unlocked`
- [x] `scenarios/` med mindst 3 scenarier i stigende sværhedsgrad plus `sandbox.json`. Hvert scenarie bruger mindst 2 forskellige objective-typer, og mindst ét af dem har `coaster_excitement_min`
- [x] `coaster/pieces.json` (mindst de 7 stykker fra kontrakten), `coaster/trains.json`, `coaster/ratings.json`, `attractions/wooden_coaster.json`
- [x] Alle id'er krydsrefererer korrekt (verificeres af testen i T-066/T-067). Kun ASCII og danske bogstaver, der findes i fonten
- [x] GDD: afsnit om forskning, scenarier og rutsjebane, inklusive rating-formlen i ord og en tabel over scenarie-mål
- [x] Efter T-068: balance-noter for en "typisk" oval rutsjebane (forventede ratings) i loggen

## Ejer / må ikke røre
Ejer: `game/content/**`, `docs/gdd.md`. Må ikke røre kode.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – designer: alt data og GDD-afsnit er leveret. `wooden_coaster.json` har `kind: "coaster"`, og derfor fejler `test_economy.test_real_content_parses` (den accepterer kun ride/shop/toilet), indtil simulation udvider testen. Gæsternes tolerance ligger i `ratings.json.guest_tolerance` og ikke i `guests.json`. Balance-noter følger efter T-068.
- 2026-10-15 – designer: balance-noter for en typisk oval (16 stykker, 17,6 m, vmax 7,85) efter T-075-tuning: E 4,66 / I 4,67 / N 2,50. Se T-075.
- 2026-10-15 – qa (T-072): Data og krydsreferencer er ok. Oval E 4.66/I 4.67/N 2.5. test.sh (235/236. Den eneste fejl er test_ui_m5, se T-077), integration.sh (inkl. ny pck-test af ScenarioDef.list_all), balance.sh, build_web.sh og smoke er grønne. Acceptkriterierne er verificeret, og test_qa_m5.gd dækker dem også. Godkendt.
