# T-074: Stiliserede bygninger med tema-elementer

- **Status:** done
- **Milepæl:** M5
- **Agent:** graphics
- **Afhænger af:** –

## Mål
Brugeren ønsker mere stiliserede bygninger i Theme Park-stil, f.eks. en isbod formet som en stor is og et spøgelseshus med et kraniehoved foran. Alle bygnings- og forlystelses-props får et tydeligt og overdrevet tema-element, der kan læses fra spillets kamera.

## Acceptkriterier
- [x] Alle 12 bygninger har et `Theme`-undertræ (karrusel og svingkarrusel under `Top/Theme`, så det drejer med).
- [x] Footprint, origin, rotation og API'et (`set_running`, `set_broken`, `set_lights`, `KartTrack` osv.) er uændret.
- [x] Eksisterende materialer og teksturer er bevaret. Tema-materialerne bruger `plaster.png` triplanart, så `test_rides_fully_textured` fortsat består.
- [x] Kun procedurelle primitiver, Compatibility-sikre (ingen shaders eller Forward+-features).
- [x] Ingen strakte kugler og ingen spejlede eller skalerede transforms. Det testes i `tests/test_stylized_buildings.gd`.
- [x] Under 3000 trekanter pr. tema-element (testet).
- [x] Screenshots i opengl3 før og efter, både i spillets kameravinkel og som nærbilleder.
- [ ] Brugeren har set og godkendt udseendet.

## Tema-elementer
| Bygning | Tema-element |
|---|---|
| Isbod | Kæmpe vaffelis med to kugler, chokoladetop, kirsebær og drip |
| Burgerbod | Kæmpe burger med bolle, bøf, ost, salat, tomat og sesamfrø |
| Drikkebod | Kæmpe sodavandsbæger med låg, kuppel, sugerør og citron |
| Toilet | Stort rundt blåt herre/dame-skilt på stang og en vanddråbe |
| Indgang | Gul maskot-bjørn med klovnehat over porten og ballonklaser på søjlerne |
| Rutsjebanestation | Rødt/gult loop på taget med vogn og ternede flag |
| Spøgelseshus | Kæmpe kranie om døren med kæbeknogler, tænder og grønt glødende øjne |
| Karrusel | Guldkrone med ædelsten og kors på toppen, der drejer med |
| Pariserhjul | Smilende sol-ansigt med stråler ved navet |
| Svingkarrusel | Stribet luftballon med kurv på toppen, der drejer med |
| Radiobiler | Kæmpe radiobil med strømstang og lyn på taget |
| Gokart | Guldpokal på podie i infielden og et stort ternet målflag |

## Log
- 2026-10-15 – graphics: oprettet og startet. Gennemgik props. Lavede before-screenshots (opengl3).
- 2026-10-15 – graphics: tema-elementerne er tilføjet via en generator (rotationsmatricer række-major i .tscn, halvkugler med `is_hemisphere`). Spøgelseshusets veranda er erstattet af kraniet, og de små toppers på boderne er erstattet af de store. Ny test: `test_stylized_buildings.gd`. `./tools/test.sh`: 203 bestået, 0 fejlet. Sat til review, så brugeren kan se det.
- 2026-10-15 – qa (T-072): Afventer brugerens visuelle bekræftelse.
- 2026-10-16 – bruger: godkendt.
