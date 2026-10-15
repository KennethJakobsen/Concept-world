# T-062: Bug: lyskæde-pærer svæver fra modellen

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** T-049

## Mål
Brugerrapport: RideVisuals emissive lyskæder svæver et stykke fra modellen (tydeligst på gokart og spøgelseshus). Pærerne skal sidde på faktiske kanter (tagkant, hegn, portal) på alle seks forlystelser.

## Acceptkriterier
- [x] `RideVisual._build_bulbs` bruger ankermeshes pr. forlystelse (`BULB_ANCHORS`): radiobiler `RoofTrim`, karrusel `Top/Rim`, pariserhjul `Wheel/RimA|RimB`, gokart `Banner` + `Wall0-4`, spøgelseshus `Eaves`, svingkarrusel `Top/Canopy` (underkant)
- [x] Kantforløb: torus/cylinder = ring, boks = top-rektangel eller top-linje (tynde vægge); jævn afstand (~0,35 m, 8-28 pærer)
- [x] Pærerne lægges under ankerets forælder, så de roterer med (karrusel, pariserhjul, svingkarrusel)
- [x] Fallback for ukendte forlystelser: øverste mesh
- [x] Test `test_ride_bulbs_sit_on_model`: hver pære ligger højst 0,06 m fra en mesh-AABB i samme forlystelse
- [x] test.sh grøn; kontrolrender (Compatibility, lys tændt)
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/scripts/rendering/`, `game/scenes/props/`, `game/tests/test_props.gd`. Må ikke røre bridge (terræn-grid) eller export_presets.

## Log
- 2026-10-15 – graphics: oprettet og udført. Årsag: pærerne lå på en ellipse rundt om hele modellens AABB i 60 % højde, dvs. i luften uden for model og hegn. Nu følger de faktiske kanter. test.sh 158/0. Kontrolrender af alle seks med lys tændt: pærer sidder på tagudhæng, karruselkant, hjulringe, tagkant, kalechekant og gokartens vægge/portal.
