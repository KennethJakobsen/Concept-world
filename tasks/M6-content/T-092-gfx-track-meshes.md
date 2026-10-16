# T-092: Grafik: trug, togskinner, monorail-bjælke og køretøjer

- **Status:** review
- **Milepæl:** M6
- **Agent:** graphics
- **Afhænger af:** T-082, ADR-004

## Mål
Mesh-snit pr. system, køretøjer og stationer med tema (kontrakt §5 T-092). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `CoasterTrackMesh` dispatcher på system, og eksisterende coaster er uændret
- [x] `CoasterTrain.set_style` med båd, lokomotiv og røg samt kabine
- [x] Stationer med tema (træstamme og økse, perron, tandhjul)
- [x] ≤ 20k trekanter for 60 stykker, Compatibility-sikkert
- [ ] Brugeren har godkendt udseendet

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – graphics: `CoasterTrackMesh.load_defs()` læser også `content/tracks/*.json` (sætter `system`), `system_of()` + `build()` dispatcher: flume = trætrug + vand (`shaders/flume_water.gdshader`, scrollende UV, Compatibility), train = skinner/sveller/grusleje, monorail = betonbjælke på søjler. Coaster-grenen er uændret. `CoasterTrain.set_style()` med træstammebåd, lokomotiv (stor skorsten + CPUParticles3D-røg) + åbne vogne og kabine. Stationer: `scenes/props/{flume,train,monorail}_station.tscn` (`TrackStation`, `level` for monorail). Trekanter for 60 stykker: flume ~13k, train ~14k, monorail ~3k (test). Test `test_track_systems_mesh.gd`; 268/268 grønne. Screenshots (opengl3): `docs/screenshots/t092*.png`. Afventer brugerens godkendelse.
