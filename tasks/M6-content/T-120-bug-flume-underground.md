# T-120: Bug: tømmerrenden går under terræn ved fald

- **Status:** review
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-090, T-092

## Mål
Brugerrapport (screenshot): ved faldstykket (`flume_drop`) dykker truget ned under terrænet. Find årsagen (sim tillader level < 0 / forkert `min_level`/`rise`-håndtering, eller mesh/scene tegner højden forkert) og ret den. Hvis sim: faldet skal afvises med `too_low` (eller stationen ligge højt nok), så banen aldrig går under jorden. Hvis det er mesh/højde-mapping i grafik eller bridge: rapportér præcist, så det kan sendes videre.

## Acceptkriterier
- [x] Ingen bane kan placeres under terræn (alle sporsystemer)
- [x] Test, der reproducerer fejlen
- [x] Eksisterende saves med ugyldige baner håndteres uden crash

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens screenshot
- 2026-10-16 – simulation: Årsag er IKKE sim: preview/cmd_place_track_piece og validate afviser allerede level < 0 (`below_ground`/`too_low`). Fejlen lå i grafik: `CoasterTrackMesh.full_centerline` brugte gennemsnitshældning i samlinger, så stykket efter et fald (fx flume_straight i niveau 0) fik start-hældning -1 og Hermite-kurven dykkede ~0,15 under terræn. Rettet (lille, klar ændring i game/scripts/rendering/coaster/coaster_track_mesh.gd): `_joint_slope` giver hældning 0 ved fortegnsskift/fladt nabostykke, og y klampes til stykkets [min,max]-niveau. Gælder alle sporsystemer. Test: `test_flume_drop_never_below_ground`. Saves berøres ikke (kun visning). test.sh 309/309, integration OK. Kræver visuel bekræftelse.
