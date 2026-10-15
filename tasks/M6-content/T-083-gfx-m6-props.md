# T-083: Grafik: props med tema-elementer til 14 bygninger

- **Status:** review
- **Milepæl:** M6
- **Agent:** graphics
- **Afhænger af:** T-080 (footprints fra T-079, T-081 for endelige tal)

## Mål
Props og animation til alle 14 bygninger uden spor, med tema-elementer i stil med T-074 (kontrakt §5 T-083). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] 14 scener med `RideVisual`-API og driftsanimation
- [x] `Theme`-undertræ, ≤ 3000 trekanter pr. element, plaster-triplanart, ingen strakte kugler eller skalerede/spejlede transforms (testet)
- [x] `test_rides_fully_textured` dækker de nye props
- [x] Kun Compatibility-sikre features
- [x] Screenshots i opengl3 (spilkamera og nærbilleder)
- [ ] Brugeren har godkendt udseendet

## Tema-elementer
| Bygning | Tema-element | Driftsanimation |
|---|---|---|
| Hoppeborgen | Kæmpe gummiand på midtertårnet | borgen hopper |
| Tekopperne | Kæmpe tekande i midten, låget løfter sig | pladen og kopperne drejer |
| Springfjedrene | Spiralfjedre som indgangsbue | figurer hopper på trampoliner |
| Himmelringene | Lilla planet med guldring og måne | gyroskop-ringe drejer om to akser, planeten drejer |
| Gyngeskibet | Dødningehoved-flag og blæksprutte om masten | skibet gynger ±26° |
| Månefærgen | Høj tegneserieraket med finner og flammekegler | raketvogne kører rundt, flammer flimrer |
| Faldtårnet | Termometertårn med "kogepunkt"-skilt og damp | gondolen kører op og falder |
| Fritterbixen | Kæmpe pommes frites-bæger | – |
| Kaffekoppen | Boden er en kæmpe kop med damp | dampen bølger |
| Ballonbåsen | Klase af 7 kæmpe balloner | klasen svajer |
| Mindebutikken | Kæmpe snekugle med mini-park på taget | – |
| Kokoskasteriet | Tre kæmpe kokosnødder på pinde | – |
| Skydeteltet | Stribet telt med kæmpe blikand og skydeskive | blikænder kører frem og tilbage |
| Andefiskeriet | Kæmpe gul and med fiskestang på taget | ænderne svømmer rundt |
| Kraftklokken | Høj skala med kæmpe klokke og hammer | pucken skydes op |

Bemærk: kontrakten lister 15 bygninger (inkl. Ballonbåsen). Alle 15 er lavet.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – graphics: startet. Props genereres af `scripts/rendering/props/m6_prop_builder.gd` (Godot pakker transforms, så række-major-fejl undgås).
- 2026-10-15 – graphics: 15 props genereret (`scripts/rendering/props/m6_prop_builder.gd`). Ny `Oscillator` (arver `Spinner`, så RideVisual styrer blød start/stop) til gyngning, hop og fald. Footprint ligger som metadata (`footprint`) og matcher T-081's data. Lyskæde-ankre er tilføjet i `ride_visual.gd`. Tests: M6 i `RIDES`/`PROPS` (textured, API, transforms) samt `test_m6_transforms_and_footprint` og `test_m6_rides_animate`. Screenshots i opengl3 (spilkamera + nær) er gennemgået, og rakettens vogne og souvenir-taget er rettet. Showcase: `res://scenes/rendering/m6_showcase.tscn`. `./tools/test.sh`: 236 bestået, 2 fejlet (`test_economy`/`test_research`, begge fra T-081's ucommittede data, ikke T-083). Sat til review, så brugeren kan se det.
