# T-101: UI: UX-fundament (skærmzoner, tooltips, indstillinger)

- **Status:** review
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-096, T-098

## Mål
Nyt HUD efter GDD §4 og kontraktens §4. Det kommer først, så alle senere UI-tasks bygger på det. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `TopBar`, `BuildDock` (6 kategorier + kort), `Inspector`, `ParkRail`, `AlertTray` og `TooltipService` med udvidelses-API'et fra kontrakten
- [x] Al nuværende funktionalitet er tilgængelig i de nye zoner, og Esc lukker inspektøren
- [x] `UserSettings` i `user://settings.cfg` ([ui]/[accessibility]) uden at slette audio-nøgler. UI-skala 75–200 %
- [x] `test_hud_glyphs` og UI-tests er grønne. Skærmbilleder til brugeren (bliver på review indtil godkendt)

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – ui: in-progress.
- 2026-10-16 – ui: review. Nye klasser i `game/scripts/ui/`: `TopBar` (ur, tal, glæde-smiley i 5 trin, stjerner, pause/1x/2x/4x med markering, varsler-klokke med ulæst-tal), `BuildDock` (node "BuildMenu"; Vælg/Fjern + 6 kategorier Stier/Forlystelser/Butikker/Pynt/Personale/Rutsjebane + kort med navn og pris, tooltip med stats, lås), `Inspector` (højre panel, fanerække, X-knap, Esc), `ParkRail` (venstre kant: Park, Personale, Forskning, Indstillinger, Menu), `AlertTray` (nederst til højre, 4 s, maks 4, klik → `GameSession.focus_cell(cell)` hvis den findes, historik via klokken), `TooltipService` (0,4 s via `gui/timers/tooltip_delay_sec` sat ved runtime), `UserSettings` og `UiSettingsPanel` (UI-skala 75/100/125/150/200 %, svævetal, farveblind; T-113 kan udvide).
  - API: `Inspector.register_tab(context, tab_id, title, factory)` – factory() -> Control, bygges lazy; har kontrollen `refresh(sim, target_id)`, kaldes den hver frame. Kontekster: `&"attraction"`, `&"guest"`, `&"staff"`. `ParkRail.register(id, icon, panel_factory, title := "")` – icon er en `UiIcons`-kind; panelet centreres og har evt. `refresh(sim)`. `AlertTray.push(text, icon := "info", cell := Vector2i(-1,-1))`. `TooltipService.attach(control, title, body := "")`.
  - Sim-varsler (`warning`) går nu til AlertTray i stedet for Toast (celle fra `data.cell` eller attraktionens origin); Toast bruges stadig til korte beskeder. `LockOverlay` gendanner TooltipService-teksten ved oplåsning. Esc: Hud._input lukker inspektør/rail-panel før BuildTool (som ellers åbner pause-menuen). UI-skala anvendes via `Window.content_scale_factor`.
  - Tests: ny `test_ui_m7_foundation.gd` (12 tests), opdateret `test_hud_m3`/`test_ui_m4`/`test_ui_m5` (sti ligger i "Stier", varsler i AlertTray). `./tools/test.sh`: 329 ok, 2 fejl der ikke er UI (`atm.json` fra T-100 mangler sim/prop-understøttelse: `test_economy::test_real_content_parses`, `test_park_view::test_build_all_m6_buildings`). `./tools/integration.sh`: OK.
  - Skærmbilleder (1280x720, Compatibility): `$TMPDIR/opencode/t101_a.png` (inspektør + varsler) og `t101_b.png` (Butikker-kort + indstillingspanel). Venter på brugerens godkendelse.
