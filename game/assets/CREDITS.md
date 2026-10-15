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
| plaster.png (64) | puds (toilet) |

## Materialer (`materials/`)
Egne `StandardMaterial3D` (.tres) med triplanar UV, deles mellem props.
