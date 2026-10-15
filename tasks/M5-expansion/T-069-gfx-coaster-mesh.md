# T-069: Grafik – procedurel bane, tog og station

- **Status:** done
- **Milepæl:** M5
- **Agent:** graphics
- **Afhænger af:** – (kan bruge hårdkodede stykke-defs indtil T-065)

## Mål
Implementér `_CONTRACT.md` §5: `CoasterTrackMesh`, `CoasterTrain` og `coaster_station.tscn`.

## Acceptkriterier
- [x] `CoasterTrackMesh.build()` laver skinner, sveller og støtteben for alle 7 stykketyper. Kurver og hældninger er glatte, og der er ingen huller ved samlingerne
- [x] `CoasterTrackMesh.centerline()` er statisk og testet: endepunkterne for to på hinanden følgende stykker er ens (≤ 1e-3)
- [x] `set_ghost(ok)` giver en grøn/rød halvgennemsigtig variant
- [x] `CoasterTrain` med `set_cars`, `set_path_pose` og RideVisual-metoderne. Teksturer/stil passer til de øvrige modeller (T-059)
- [x] `coaster_station.tscn`
- [x] 60 stykker ≤ 20k trekanter (test). Kun Compatibility-kompatible materialer
- [x] Demo-scene `game/scenes/rendering/coaster_demo.tscn` med en hårdkodet oval og kørende tog til visuel kontrol
- [x] `tools/test.sh` er grøn. Status forbliver `review`, indtil brugeren har godkendt det visuelt

## Ejer / må ikke røre
Ejer: `game/scripts/rendering/`, `game/scenes/props|effects|rendering/`, `game/shaders/`, `game/assets/`, `game/tests/test_props.gd` og `test_coaster_mesh.gd`. Må ikke røre simulation/, bridge/, building/ og ui/.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – graphics: implementeret. `scripts/rendering/coaster/` (CoasterTrackMesh, CoasterTrain, demo), `scenes/props/coaster_train.tscn`, `coaster_station.tscn`, `scenes/rendering/coaster_demo.tscn`, `tests/test_coaster_mesh.gd`. Defs læses fra `content/coaster/pieces.json` (liste eller `{pieces: [...]}`) med fallback til `DEFAULT_DEFS`. Ekstra statiske hjælpere til bridge: `full_centerline(pieces, defs)` (glatte hældningsovergange via Hermite, samme endepunkter), `arc_lengths`, `pose_at(line, acc, s)`, `CoasterTrain.CAR_SPACING`. Stationen har origin i cellemidten og sporet langs z (rotation.y = -heading·90°). Demo-oval (16 stykker) = 3150 trekanter, og 60 stykker ligger under 20k (test). Materialer: StandardMaterial3D (Compatibility). Venter på brugerens visuelle godkendelse.
- 2026-10-15 – orkestrator: brugeren har godkendt visuelt → done
