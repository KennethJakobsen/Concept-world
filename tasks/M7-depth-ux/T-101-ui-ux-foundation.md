# T-101: UI: UX-fundament (skærmzoner, tooltips, indstillinger)

- **Status:** todo
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-096, T-098

## Mål
Nyt HUD efter GDD §4 og kontraktens §4. Det kommer først, så alle senere UI-tasks bygger på det. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [ ] `TopBar`, `BuildDock` (6 kategorier + kort), `Inspector`, `ParkRail`, `AlertTray` og `TooltipService` med udvidelses-API'et fra kontrakten
- [ ] Al nuværende funktionalitet er tilgængelig i de nye zoner, og Esc lukker inspektøren
- [ ] `UserSettings` i `user://settings.cfg` ([ui]/[accessibility]) uden at slette audio-nøgler. UI-skala 75–200 %
- [ ] `test_hud_glyphs` og UI-tests er grønne. Skærmbilleder til brugeren (bliver på review indtil godkendt)

## Log
- 2026-10-16 – architect: oprettet (T-098)
