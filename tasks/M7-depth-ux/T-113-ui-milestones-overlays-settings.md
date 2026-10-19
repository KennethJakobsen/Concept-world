# T-113: UI: milepæle, overlay-vælger, indstillinger og tanker

- **Status:** done
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-101, T-105, T-111

## Mål
Kontraktens §4 T-113. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] Milepælspanel med fremskridt og toast + fanfare
- [x] Overlay-vælger (O) med legende
- [x] Indstillingspanel: UI-skala, farveblind, svævetal
- [x] Låste grene viser, hvilken milepæl der åbner dem. `m7_texts.gd` med alle nye tanker. Pengeblink

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – ui: implementeret. `MilestonePanel` (rail "Milepæle", pokal-ikon): fremskridtslinjer, belønningstekst og flueben. Teksten "slået fra" vises i sandbox. `Hud.on_milestone_achieved` ← `GameSession.milestone_achieved`: toast i AlertTray og fanfare (`cheer`). Backfill giver ingen toast. `OverlayPicker` (rail "Overlays", øje-ikon, tast O): Ingen + `ParkColors.OVERLAY_KINDS` → `GameSession.show_overlay/hide_overlay` og legende fra `ParkColors.legend`. Overlayet skjules, når vælgeren lukkes. Indstillingspanelet (T-101) kalder nu `ParkColors.set_colorblind` og `GameSession.refresh_settings()` ved ændringer. `ResearchPanel`: låste emner er deaktiveret i prioritetslisten, har tooltip og en liste med "Låst - kræver milepælen 'X'". `m7_texts.gd` (`M7Texts`): tanker, overlay-navne, belønnings- og låsetekster. HUD'en viser gæstetanker via `M7Texts.thought_text`. `TopBar.flash_money(sign)` ← `GameSession.money_flash`: grøn/rød i 0,4 s. Tests: `tests/test_ui_m7_panels.gd` (7 tests inkl. glyffer). test.sh 435/0 og integration.sh OK. Screenshots: `docs/screenshots/t113_{milestones,overlay,settings,research,toast}.png` (script `scripts/ui/ui_screenshots_t113.gd`, Grøn eng). Brugeren skal se dem: pengeblink og fanfare kan kun vurderes i spillet.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
- 2026-10-19 – orkestrator: brugeren har godkendt → done (M7 lukket)
