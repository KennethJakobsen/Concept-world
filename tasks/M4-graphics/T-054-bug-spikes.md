# T-054: Bug – lange "spyd" fra lamper, forlystelser og træer

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** T-048, T-049

## Mål
Brugerrapport (skærmbillede): hvide kegler skråt op fra lamper, lange nåle fra forlystelser (især swing ride, skæv paraply-top), pink stribe ved bygning, konfetti der svæver højt. Nedbrudseffekten (røg/blink/tilt) var ikke synlig.

## Acceptkriterier
- [x] Root cause fundet og rettet
- [x] Regressionstest i `test_props.gd` (ingen strakte meshes; sane transforms efter mange frames med set_running/set_broken)
- [x] Nedbrudseffekt verificeret via ParkView (røg, `set_broken`, blink) og gjort tydeligere
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Må: `game/scripts/rendering`, `game/scenes/props|effects`, `game/tests/test_props.gd`. Ikke: audio, simulation, ui.

## Log
- 2026-10-15 – graphics: oprettet.
- 2026-10-15 – graphics: **Root cause:** prop-scenerne (fra M3-generatoren) havde `SphereMesh.height = 8` (eller 6) i stedet for `2*radius` → kugler blev til 6–8 m lange spindler: lampepærer (hvide "kegler"), swing ridens knop (top ser skæv ud), haunted house, træernes kroner (pink/grøn), blomster, go-kart-hoveder, entertainer, affald. Rettet i 9 scener (height = 2*radius). Ingen transform-fejl i animationerne (testet). Nedbrud: bridgen kalder allerede røg + `set_broken` korrekt; hældning øget 1.5° → 4° (`BROKEN_TILT_DEG`) så den kan ses. Konfetti: højere tyngde/lavere fart, så den lander inden for levetiden (one-shot frigives via timer – virker). Nye tests: `test_no_stretched_meshes`, `test_ride_transforms_stay_sane`. 147 tests grønne, smoke uden fejl. Afventer visuelt tjek.
- 2026-10-15 – orkestrator: brugeren har godkendt visuelt/lyd. Status: done.
