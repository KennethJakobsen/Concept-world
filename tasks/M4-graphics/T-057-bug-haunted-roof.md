# T-057: Bug – spøgelseshusets tag vender forkert

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** –

## Mål
Brugerrapport (skærmbillede): sadeltaget på spøgelseshuset vender forkert (gavle ses forkert), og tårnets spir sidder skævt.

## Acceptkriterier
- [x] Tagfladerne danner et sadeltag med rygning langs husets lange side (x) og tagfod ved vægtop
- [x] Tårnspiret flugter med det kvadratiske tårn
- [x] Øvrige props tjekket for samme fejl
- [x] Test (`tests/test_haunted_roof.gd`)
- [x] `tools/test.sh` grøn
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/scenes/props/haunted_house.tscn`, `game/tests/test_haunted_roof.gd`. Må ikke røre simulation, ui, bridge.

## Log
- 2026-10-15 – graphics: oprettet og løst. Årsag: `Transform3D` i .tscn er række-major, men tag-rotationerne var skrevet som kolonner → hældningen var spejlet, så fladerne dannede en "V"-dal i stedet for et sadeltag. Fortegn på X-rotationen byttet om for Roof0/Roof2. Spiret (CylinderMesh med 4 segmenter = pyramide med hjørner på akserne) stod som diamant på det firkantede tårn → roteret 45° om Y. Andre props: bumper_cars/carousel/toilet-tage er urotérede (OK); de øvrige små hældninger er bænkeryglæn o.l. (uændret). test.sh 150/0. Afventer brugerens øjne.
