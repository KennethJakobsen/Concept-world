# T-114: Data: tutorial-scenariet 'Første park'

- **Status:** review
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-110, T-113

## Mål
GDD §4 Tutorial og kontraktens §5. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `scenarios/tutorial.json` med 6 trin og `complete_when` fra kontraktens liste
- [x] Vises i scenariovalget og kan springes over

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – designer: `scenarios/tutorial.json` (32x32, 20.000 kr, ingen forskning/milepæle/mål, `order` 0 → listes efter sandbox). 6 trin: sti → karrusel (+ køfelter i teksten) → drikkebod → pris → kø-overlay → rengøring. `complete_when`: `path_connected_to_entrance`, `attraction_built:ride`, `attraction_built:shop`, `price_changed`, `overlay_opened:queue`, `staff_hired:cleaner`. `highlight`-format til T-115: `entrance`, `build:<def>`, `attraction:<kind>`, `overlay:<kind>`, `staff:<type>`. Ekstra felter `tutorial: true`, `skippable: true` (ignoreres af ScenarioDef; T-115/T-116 læser rå JSON). Ingen sporbaner i tutorialen, så T-131/T-133-sving er irrelevante. Tests: 421/422; eneste fejl `test_render_m7` hører til igangværende T-148.
- 2026-10-16 – qa: teknisk OK (test.sh, integration, smoke, web-build grønne) – afventer brugerens visuelle godkendelse.
