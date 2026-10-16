# T-142: Bug: menuen hopper ned på plads ved dagskift

- **Status:** review
- **Milepæl:** M7
- **Agent:** ui
- **Afhænger af:** T-138

## Mål
Brugerrapport: UI'et (menu/dock) hopper ved dagskift – formentlig en layout-størrelse, der ændres, når dato/tekst skifter, eller at layoutet først bliver korrekt ved næste opdatering.

## Acceptkriterier
- [x] Ingen synligt hop ved dagskift (faste bredder/min-størrelser, korrekt layout fra første frame)
- [x] Regressionstest: positioner uændrede før/efter dagskift

## Log
- 2026-10-16 – orkestrator: oprettet fra brugerrapport
- 2026-10-16 – ui: Årsag: layout blev kun genberegnet når top-tekstens længde ændrede sig, så breddeændringer (dag/ur) lod top-bar vokse uden relayout og blev først rettet senere. Fix: top_bar.minimum_size_changed -> Hud._relayout (samme frame, re-entrancy-vagt). Test: test_layout_stable_across_day_change. Kræver visuel bekræftelse.
