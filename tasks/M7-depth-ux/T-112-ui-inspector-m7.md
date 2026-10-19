# T-112: UI: inspektør-faner (indstillinger, økonomi, kø)

- **Status:** done
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-101, T-102, T-103

## Mål
Kontraktens §4 T-112. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Indstillinger med skydere for config, opskrifter og pris-stepper med advarsel
- [x] Økonomi med tal, sparkline over 7 dage og 'Tjent hjem på dag N'
- [x] Kø med længde/kapacitet og ventetid
- [x] UI-tests og glyf-test er grønne

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – ui: implementeret. Ny `scripts/ui/attraction_tabs.gd` (`AttractionTabs.register(inspector)` via `Inspector.register_tab`) med tre faner for `attraction`-konteksten:
  - Indstillinger: skydere for `capacity`/`ride_ticks`/`speed` (fra `def.config`, viser `cfg_current`, kalder `cmd_set_config`; under træk sendes kun ved slip), afledte tal fra `effective_config`, opskrift-afkrydsning (`cmd_set_recipe`) og pris-stepper (`cmd_set_price`) med rød advarsel ved pris < 0,6 x standard. Sporbaner: ingen skydere.
  - Økonomi: i dag/i går/i alt/drift/varekøb/netto, sparkline (7 søjler) over `revenue_days` og "Tjent hjem på dag N"/"Ikke tjent hjem endnu".
  - Kø: fyldbjælke, `queue_length/queue_capacity`, køsti-felter, ventetid (`wait_ticks_estimate`/20) og gennemsnitlig resterende tålmodighed for gæsterne i køen.
  - T-140's midlertidige kølinje er fjernet fra Oversigt (`Hud.attraction_text`); `test_queue_view` tjekker nu Kø-fanens tekst, `test_ui_m7_foundation` tåler de nye faner.
  - Tests: `tests/test_ui_m7_inspector.gd` (5 tests inkl. glyf-tjek af alle faner) er grønne. Inspektøren er fortsat UiFit-styret (280 px bred, scroll).
  - Skærmbilleder: `docs/screenshots/t112_{settings_ride,settings_shop,economy,queue}.png` (script `scripts/ui/ui_screenshots_t112.gd`); set og ser fine ud.
  - Kendte røde ting, der ikke er mine: coaster/render-tests (parallelt graphics-arbejde: `ColorPalette.ghost`, `ParkColors`), `test_m7_amenities` (sim T-104), og integration.sh melder leak-advarsler ved exit, også med T-112 slået fra. Integration-flowet selv: OK (0 fejl).
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
