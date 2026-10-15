# T-017: Bug – WASD flytter ikke kameraet

- **Status:** review
- **Milepæl:** M1
- **Agent:** graphics
- **Afhænger af:** T-009

## Mål
Rapporteret af bruger: WASD virker ikke. Årsag: park_camera.gd bruger ui_*-actions (kun piletaster).
Definér egne input-actions i project.godot (cam_left/right/forward/back = A/D/W/S + pile, cam_rotate_left/right = Q/E) og brug dem i kameraet. Tjek at ingen andre taster (1, 2, Space, +/-) kolliderer.

## Acceptkriterier
- [x] WASD og pile flytter kameraet, Q/E roterer
- [x] Input-actions defineret i project.godot
- [x] Test der verificerer at actions findes og er bundet til WASD

## Log
- 2026-10-15 – architect: oprettet efter brugerrapport
- 2026-10-15 – graphics: cam_* input-actions (physical_keycode, WASD+pile, Q/E) i project.godot; park_camera bruger dem; test_input_map.gd. Ingen kollision med 1/2/Space/+/-. Import, tests (20/20) og smoke grønne.
