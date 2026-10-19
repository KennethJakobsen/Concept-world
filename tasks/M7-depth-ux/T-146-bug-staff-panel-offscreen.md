# T-146: Bug: personale-panelet går uden for skærmen

- **Status:** done
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-138

## Mål
Brugerrapport: Personale-panelet (ParkRail) går ud over skærmkanten, så ingen af knapperne kan nås.

## Acceptkriterier
- [x] Panelet holdes inden for skærmen ved alle opløsninger ned til 1024x600 og UI-skala op til 200 % (scroll ved behov)
- [x] Gælder alle rail-paneler (Park, Personale, Forskning, Indstillinger, Menu)
- [x] Regressionstest der tjekker at alle rail-paneler og deres knapper ligger inden for viewporten

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerrapport
- 2026-10-16 – ui: Årsag: højre-/rail-paneler blev placeret ud fra `custom_minimum_size.x` (240), men Control klamper størrelsen op til indholdets minimum. Personale-rækkernes labels (lange navne/status) gjorde panelet bredere -> "Fyr"-knapperne og kanten lå uden for skærmen (samme for forskningspanelet: 4 finansieringsknapper på én række). Højden kunne heller ikke begrænses.
  Rettelse (generelt): ny `UiFit` (`wrap_scroll` + `fit`): paneler (Park, Personale, Forskning, fabrik-paneler som Indstillinger, samt selve ParkRail) har indholdet i en lodret ScrollContainer, og `Hud.layout` sætter størrelse klampet til tilgængelig bredde/højde og placerer ud fra den faktiske størrelse. Paneler må dække dokken ved lave opløsninger, men aldrig skærmkanten. Personalerækker: label klippes med "..." + tooltip. Forskning: finansiering i 2x2-grid, prioritet klipper, emnetekst ombrydes.
  Regressionstest: `UiBounds.check_control` + nyt trin i `tools/integration_flow.gd` (kræver scenetræ for rigtige tekstmål – unit-runneren kører uden træ): alle rail-paneler med 14 ansatte ved 1280x720, 1024x600 og 512x300 (= 1024x600 @ 200 %). Fejlede før rettelsen (50 fejl), nu 0. test.sh 372/0, integration OK. Skærmbillede: docs/screenshots/t146_staff.png (ui_screenshots.gd har fået et staff-trin). Venter på brugerens bekræftelse.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
