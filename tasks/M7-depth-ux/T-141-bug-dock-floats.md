# T-141: Bug: byggedock svæver efter undermenu lukkes

- **Status:** review
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-138

## Mål
Brugerrapport: Klik "Forlystelser" → kortpanel åbner. Klik "Forlystelser" igen → panelet lukker, men dock-bjælken bliver stående der, hvor panelet var, i stedet for at falde tilbage til bunden.

## Acceptkriterier
- [x] Docken står i bunden efter luk (klik igen, Esc, valg af andet værktøj)
- [x] Regressionstest der tjekker dockens position efter åbn/luk

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerrapport
- 2026-10-16 – ui: Årsag: close_cards() (klik igen/Esc) kaldte aldrig Hud.layout, og layout brugte en cachet minimumsstørrelse. Fix: BuildDock.layout_changed-signal -> Hud._relayout (også uden for tree via sidste vp), BuildDock.dock_size() beregner højden fra synlige dele, position ud fra faktisk størrelse. Test: test_dock_returns_to_bottom_after_close (klik igen + Esc). Kræver visuel bekræftelse.
