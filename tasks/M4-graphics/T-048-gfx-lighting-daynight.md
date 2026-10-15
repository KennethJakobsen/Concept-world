# T-048: Grafik – lys og dag/nat-rig

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** –

## Mål
`DayNightRig` jf. `_CONTRACT.md` §3: sol/måne, himmel, ambient, tone mapping/fog der virker i Compatibility. Lamper med `set_intensity`, natbelysning på forlystelser (`set_lights`). Løft materialer generelt (farvepalet, let rim/ambient, kontaktskygge-fake under figurer hvis billigt).

## Acceptkriterier
- [x] `day_night_rig.tscn` + `DayNightRig` med `set_time_of_day`, `night_factor`, `night_factor_changed`
- [x] Dag, skumring og nat ser tydeligt forskellige ud; nat er stadig spilbar (kan se stier/grid)
- [x] Lamper: `set_intensity(f)`; maks. ~8 aktive skyggeløse OmniLights – resten emissive-only (LOD efter afstand til kamera)
- [x] Alle forlystelser har `set_lights(f)` (emissive pærer)
- [x] Kun Compatibility-features; test i `test_props.gd`/ny test for rig-API (headless)
- [x] Demo-scene eller debug-tast til at spole tiden (til brugerens visuelle check)

## Ejer / må ikke røre
Ejer: `game/scripts/rendering/`, `game/scenes/rendering|props|effects/`, `game/shaders/`, `game/assets/` (ikke audio), `game/tests/test_props.gd`. Må ikke røre `game/simulation/`, `game/scripts/bridge|ui|audio/`, `main.tscn`.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – graphics: `DayNightRig` (`scripts/rendering/day_night_rig.gd`, `scenes/rendering/day_night_rig.tscn`): ProceduralSky, ACES, let fog, sol/måne-retning, farve/energi, ambient holdes oppe om natten. `night_factor_changed` kun ved >0.01. `LampVisual.set_intensity` + statisk LOD (`update_lod`, maks. 8 skyggeløse OmniLights nærmest kameraet; kaldes fra rig'ens `_process`). `RideVisual` (rod-script på alle 6 forlystelser) bygger emissive lyskæde, `set_lights(f)`. Demo: `scenes/rendering/day_night_demo.tscn` (T spoler tid, R/B/E/F – se scriptet). Tests i `test_props.gd`. Venter på brugerens visuelle check. Note til bridge (T-051): rig'en tilføjes som erstatning for evt. eksisterende sol/WorldEnvironment i main.tscn.
- 2026-10-15 – qa (T-053): headless OK (tests, kun Compatibility-features: gl_compatibility, ingen GPUParticles/SDFGI/SSAO/SSR, OmniLights skyggeløse, kun sol har skygge). Visuelt check kræver brugeren (se T-053-tjekliste). Bliver på review.
- 2026-10-15 – orkestrator: brugeren har godkendt visuelt/lyd. Status: done.
