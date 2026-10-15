# T-073: Bug – rutsjebanestationens tag er galt

- **Status:** review
- **Milepæl:** M5
- **Agent:** graphics
- **Afhænger af:** T-069

## Mål
Brugerrapport fra rutsjebane-demoen: "taget er galt på huset" (`coaster_station.tscn`).

## Acceptkriterier
- [x] Sadeltag med rygning langs sporet (z) over midten, tagfod på søjletoppene
- [x] Tjekket for samme fejl som T-057 (række-major Transform3D)
- [x] Screenshot før/efter i Compatibility-rendereren
- [x] Test (`tests/test_coaster_station_roof.gd`)
- [x] `tools/test.sh` grøn
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/scenes/props/coaster_station.tscn`, `game/tests/test_coaster_station_roof.gd`. Må ikke røre simulation, ui, bridge.

## Log
- 2026-10-15 – graphics: oprettet og løst. Årsag: samme fejl som T-057. Tag-rotationerne i `.tscn` var skrevet som kolonner, men Transform3D er række-major, så hældningen var spejlet. Tagfladerne dannede en "V"-dal (yderkanter højest), og yderkanterne svævede ca. 8 cm over søjletoppene. Fortegnene på Z-rotationen er byttet om for RoofL/RoofR. Nu ligger rygningen ved x=0 langs sporet, og tagfoden hviler på søjlerne. Placering, størrelse og perron er uændret. Screenshots før/efter (opengl3) er bekræftet. Afventer brugerens øjne.
