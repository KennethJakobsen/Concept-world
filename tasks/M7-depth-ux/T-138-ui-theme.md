# T-138: UI: fælles tema og billedbaseret byggemenu

- **Status:** done
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-136, T-137

## Mål
Implementér stilguiden som et fælles Godot `Theme` for alle UI-zoner og hovedmenu. Byggemenuen bliver kort med miniature + navn + pris og kategorier som ikoner.

## Acceptkriterier
- [x] Ét fælles Theme-resource bruges af alle UI-scener
- [x] Byggedock med ikon-kategorier og billedkort (hover/valgt/låst)
- [x] TopBar, Inspector, ParkRail, AlertTray, hovedmenu i samme stil
- [~] Tests grønne, skærmbilleder til brugeren (bliver på review)

## Log
- 2026-10-16 – orkestrator: oprettet
- 2026-10-16 – ui: implementeret "Tivoli-skilt".
  - `UiTheme` (`scripts/ui/ui_theme.gd`): palet, StyleBoxes og variationer (PanelWood/PanelPaper/SignWood/RailWood/DockRoot, WoodLabel/TitleLabel/CardName/CardPrice, Medallion/Card/Tab/AlertNote/BigButton, TooltipPanel/TooltipLabel, ProgressBar, LineEdit, CheckBox). Gemt som ét resource `scenes/ui/theme/concept_theme.tres` (regenerér: `godot --headless --script res://scripts/ui/ui_theme_export.gd`). Bruges af HUD-roden og hovedmenuen og er sat som `gui/theme/custom` i project.godot, så tooltips/popups får samme stil. Det gamle `game/ui/theme.tres` er slettet.
  - BuildDock: træbjælke nederst i midten med værktøjs-medaljoner (Vælg/Fjern) og 6 kategori-medaljoner (kun ikoner, ring i kategorifarve). Over den et papirpanel med billedkort 120x150 (bånd, miniature, navn, mønt + pris) med hover-løft, valgt (messingkant + flueben), låst (desatureret, lås, "Forskning") og pris i rødt, når man ikke har råd. Sideskift med pile-ikoner. Kolonnerne følger vinduesbredden, og der er 2 rækker ved højde ≥ 900. Kortpanelet er lukket ved start, åbner ved klik på en kategori og lukker igen ved nyt klik eller Esc. Mangler en miniature (atm), bruges kategori-ikonet.
  - TopBar: 3 træskilte (penge-ikon + tal, ur/smiley/stjerner som ikoner, hastigheds-medaljoner + klokke med rødt badge). ParkRail: træstrimmel med 48 px medaljoner (rail_*-ikoner). Inspector: papir med titel-skilt (portræt + titel + luk-medaljon) og faneblade. AlertTray: papirsedler med type-farvet kant og ikon, hover pauser timeren. Hovedmenu: himmel/græs-gradient + varm vignet, logo-skilt med blinkende pærer og knapper med ikoner. Pause og indstillinger arver temaet.
  - Tests: ny `test_ui_theme.gd`. `test_hud`/`test_ui_m7_foundation` er tilpasset kort-strukturen. `./tools/test.sh`: 333 ok, 2 kendte atm-fejl. `./tools/integration.sh`: OK.
  - Skærmbilleder (1280x720, Compatibility, `scripts/ui/ui_screenshots.gd`): `docs/screenshots/t138_menu.png`, `t138_build.png` og `t138_inspector.png`. Venter på brugerens øjne.
  - Ikke med (forslag til opfølgning): Tween ved åbning/lukning af paneler, tasterne 1-6 (input ejes af bridge), "kr"-format i stedet for "$" (teksten kommer fra Hud.top_text/content).
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
