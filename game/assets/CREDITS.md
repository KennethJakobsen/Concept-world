# Assets – kilder og licenser

## Teksturer (`textures/`)
Alle teksturer er **egne**, procedurelt genereret af `game/tools/gen_textures.gd`
(deterministisk seed; genkør: `cd game && godot --headless --script res://tools/gen_textures.gd`).
Licens: samme som projektet. Ingen tredjepartsassets.

| Fil | Brug |
|---|---|
| grass.png (128) | græsterræn (`shaders/ground_grid.gdshader`) |
| cobble.png (128) | sti-fliser |
| planks.png (128) | træ (bænke, boder, platforme) |
| roof_tiles.png (128) | tegl/spån på tage |
| brick.png (128) | mursten (spøgelseshus) |
| metal.png (64) | metal på forlystelser, skraldespand |
| plaster.png (64) | puds (toilet), malede flader på forlystelser |
| asphalt.png (128) | asfalt (gokartbane), dæk/gummi (T-061) |
| tread.png (64) | riflet gulvplade (radiobiler) (T-061) |
| panel.png (64) | malet metalpanel med nitter (karosser, kabiner, trim) (T-061) |
| canvas.png (64) | stof/lærred (tage, markiser, flag, skilte) (T-061) |
| steel.png (64) | børstet stål (forlystelsernes stel) (T-061) |

## Materialer (`materials/`)
Egne `StandardMaterial3D` (.tres) med triplanar UV, deles mellem props.
- `asphalt.tres` (T-061): gokartbanen. Desuden får forlystelsernes farvede sub-materialer
  (karrusel, pariserhjul, gokart, radiobiler, svingkarrusel) en af de egne teksturer
  (metal/plaster/planks/grass/asphalt) tintet med den oprindelige farve – se `tools/apply_textures.py`.
- `steel.tres`, `tread_plate.tres` (T-061): kraftigere stål på forlystelser og riflet radiobil-gulv.

## T-108 omgivelser
- Mur, port, busstoppested, træer, marker, vej, biler/busser og gæster i `scripts/rendering/surroundings_renderer.gd` er procedurelle primitiver (egne, ingen eksterne assets).
