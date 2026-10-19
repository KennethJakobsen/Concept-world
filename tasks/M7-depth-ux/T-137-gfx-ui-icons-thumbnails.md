# T-137: Grafik: ikoner og prop-miniaturer til UI

- **Status:** done
- **Milepæl:** M7
- **Agent:** graphics
- **Afhænger af:** T-136

## Mål
Ikonsæt og renderede miniaturer af hver bygning/prop efter `docs/ui-style.md`.

## Acceptkriterier
- [x] Miniature (PNG) for hver bygning, sti og pynt, genereret af et værktøj fra prop-scenerne (kan genkøres)
- [x] Kategori-, værktøjs- og rail-ikoner efter stilguiden
- [x] Ligger under `game/assets/ui/`, credits opdateret

## Log
- 2026-10-16 – orkestrator: oprettet
- 2026-10-16 – graphics: 60 ikoner (§8, 64+128 px) i `game/assets/ui/icons/` fra `game/tools/gen_ui_icons.gd` (egne SVG-former → PNG, headless). 41 miniaturer (160×120, transparent, 30°/45° ortogonalt, varmt lys, flise + oval skygge) i `game/assets/ui/thumbs/` fra `game/tools/render_thumbs.gd` (Compatibility, ikke headless). Det dækker attraktioner, pynt, personale, `path` og `entrance`. `atm` har ingen prop-scene, så den bruger fallback. Kontaktark: `docs/screenshots/t137_sheet.png`. CREDITS opdateret. Tests: 329 ok, 2 kendte atm-fejl. Afventer brugerens visuelle godkendelse.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
