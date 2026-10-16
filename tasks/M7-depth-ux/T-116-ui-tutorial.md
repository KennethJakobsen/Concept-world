# T-116: UI: tutorial-trinpanel

- **Status:** review
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-114

## Mål
Kontraktens §4 T-116. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Trinpanel med tekst, fremskridt og 'Spring over'
- [x] Glyf-test er grøn

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – ui: `TutorialPanel` (tutorial_panel.gd: titel, "Trin x af y", fremskridtsbjælke, trin-tekst, "Spring over" → `GameSession.tutorial_skip()`) og `TutorialHighlight` (tutorial_highlight.gd: pulserende messingramme om dok-kort/kategori for `build:<def>` og `staff:<type>`, overlay-knap/rail-knap for `overlay:<kind>`; `entrance`/`attraction:*` overlades til gameplays verdenspile). Hud forbinder defensivt `tutorial_step_changed(index, step)` og `tutorial_finished(skipped)` og samler et igangværende trin op via `tutorial_active/tutorial_current_step/tutorial_step_index`; antal trin fra `tutorial_step_count()` (fallback: tutorial.json), skjult "Spring over" hvis `tutorial_skippable()` er false. Panelet placeres under målpanelet ved rail'en. Tests: `tests/test_ui_m7_tutorial.gd` (inkl. glyf-test). `./tools/test.sh` 442/0, `./tools/integration.sh` OK. Skærmbilleder: `docs/screenshots/t116_{path,ride,queue,cleaner}.png` (script `scripts/ui/ui_screenshots_t116.gd`) – set: panel og highlights (Karrusel-kort, overlay-øje) ser rigtige ud. Afventer brugerens øjne.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
