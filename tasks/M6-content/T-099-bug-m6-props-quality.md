# T-099: Bug: M6-props mangler teksturer/detaljer, showcase viser kun 3

- **Status:** in-progress
- **Milepæl:** M6
- **Agent:** graphics
- **Afhænger af:** T-083

## Mål
Brugerfeedback på T-083:
1. I `m6_showcase.tscn` kan kun de 3 første bygninger ses ordentligt. Man skal kunne se hver bygning individuelt (centreret, fuldt i billedet, evt. kun én synlig ad gangen), både i spil- og nærzoom.
2. De nye props mangler teksturer og detaljer og har ikke samme kvalitet som resten (M4 T-058/T-059/T-061, M5 T-074). Løft alle 15 til samme niveau.

## Acceptkriterier
- [ ] Showcase: venstre/højre viser hver af de 15 bygninger centreret og individuelt
- [ ] Alle 15 props har teksturer (samme materialer/triplanar-tilgang som eksisterende) og detaljeniveau som de bedste eksisterende props
- [ ] Screenshots (opengl3) af alle 15 sammenlignet med eksisterende props
- [ ] `./tools/test.sh` grøn

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens review af T-083
