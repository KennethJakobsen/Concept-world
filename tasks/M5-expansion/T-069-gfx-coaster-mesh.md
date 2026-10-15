# T-069: Grafik – procedurel bane, tog og station

- **Status:** todo
- **Milepæl:** M5
- **Agent:** graphics
- **Afhænger af:** – (kan bruge hårdkodede stykke-defs indtil T-065)

## Mål
Implementér `_CONTRACT.md` §5: `CoasterTrackMesh`, `CoasterTrain` og `coaster_station.tscn`.

## Acceptkriterier
- [ ] `CoasterTrackMesh.build()` laver skinner, sveller og støtteben for alle 7 stykketyper. Kurver og hældninger er glatte, og der er ingen huller ved samlingerne
- [ ] `CoasterTrackMesh.centerline()` er statisk og testet: endepunkterne for to på hinanden følgende stykker er ens (≤ 1e-3)
- [ ] `set_ghost(ok)` giver en grøn/rød halvgennemsigtig variant
- [ ] `CoasterTrain` med `set_cars`, `set_path_pose` og RideVisual-metoderne. Teksturer/stil passer til de øvrige modeller (T-059)
- [ ] `coaster_station.tscn`
- [ ] 60 stykker ≤ 20k trekanter (test). Kun Compatibility-kompatible materialer
- [ ] Demo-scene `game/scenes/rendering/coaster_demo.tscn` med en hårdkodet oval og kørende tog til visuel kontrol
- [ ] `tools/test.sh` er grøn. Status forbliver `review`, indtil brugeren har godkendt det visuelt

## Ejer / må ikke røre
Ejer: `game/scripts/rendering/`, `game/scenes/props|effects|rendering/`, `game/shaders/`, `game/assets/`, `game/tests/test_props.gd` og `test_coaster_mesh.gd`. Må ikke røre simulation/, bridge/, building/ og ui/.

## Log
- 2026-10-15 – architect: oprettet
