# T-099: Bug: M6-props mangler teksturer/detaljer, showcase viser kun 3

- **Status:** review
- **Milepæl:** M6
- **Agent:** graphics
- **Afhænger af:** T-083

## Mål
Brugerfeedback på T-083:
1. I `m6_showcase.tscn` kan kun de 3 første bygninger ses ordentligt. Man skal kunne se hver bygning individuelt (centreret, fuldt i billedet, evt. kun én synlig ad gangen), både i spil- og nærzoom.
2. De nye props mangler teksturer og detaljer og har ikke samme kvalitet som resten (M4 T-058/T-059/T-061, M5 T-074). Løft alle 15 til samme niveau.

## Acceptkriterier
- [x] Showcase: venstre/højre viser hver af de 15 bygninger centreret og individuelt
- [x] Alle 15 props har teksturer (samme materialer/triplanar-tilgang som eksisterende) og detaljeniveau som de bedste eksisterende props
- [x] Screenshots (opengl3) af alle 15 sammenlignet med eksisterende props
- [x] `./tools/test.sh` grøn

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens review af T-083
- 2026-10-16 – graphics: Showcasen viser nu én bygning ad gangen ved origo, og kameraet indrammes efter bygningens AABB (spil- og nærzoom). `-- --shots <mappe>` gemmer screenshots af alle 15 i begge zoom. Builderen bruger nu de delte materialer (`wood`, `wood_dark`, `metal`, `steel`, `tread_plate`, `path_stone`, `roof_tiles`) og triplanare canvas/panel/metal/tread/cobble-teksturer. Ingen flade plaster-flader på strukturelle dele længere. Der er nye fælles detaljer: kantsten, hegn, indgangsportal med skilt, betjeningshus, lygtepæle, stribede markiser med kamkant, menutavler og vimpelsnore. Hver prop har fået ekstra detaljer, f.eks. merloner, flag, blæser og skohylde på hoppeborgen, prikker, underkopper og roser på kopperne, net og fjedre på trampolinerne, rækværk, koøjer, kanoner og sejl på piratskibet, nitter og ruder på raketten, afstivning og motor på faldtårnet samt præmiehylder og bamser i boderne. Boderne har fået lyskæde-ankre på markisekanten (`ride_visual.gd`). Screenshots i opengl3 er sammenlignet med `render_preview` af M4/M5-props. `./tools/test.sh`: 297 bestået, 0 fejlet. Venter på, at brugeren ser det.
