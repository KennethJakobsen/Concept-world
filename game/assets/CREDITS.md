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

## T-137 UI-ikoner og miniaturer (`ui/`)
Alle **egne**, ingen tredjepartsassets. Licens: samme som projektet.
- `ui/icons/<id>.png` (64 px) og `ui/icons/128/<id>.png` (128 px): 60 ikoner efter `docs/ui-style.md` §8, tegnet som egne SVG-former i
  `game/tools/gen_ui_icons.gd` og rasteriseret af Godot. Genkør: `cd game && godot --headless --script res://tools/gen_ui_icons.gd`.
- `ui/thumbs/<content_id>.png` (160×120, transparent): renderet i Compatibility fra vores egne prop-scener af `game/tools/render_thumbs.gd`.
  Genkør (ikke headless): `cd game && godot --rendering-method gl_compatibility --script res://tools/render_thumbs.gd -- <kontaktark.png>`.
  `atm` er renderet fra `scenes/props/atm.tscn` (T-107).
- T-107: `scenes/props/atm.tscn`, køsti-rækværk, skrald, spand-fyld, gæstemængde og svævetal er procedurelle/egne (CC0, ingen eksterne assets).

- `ui/logo/*` – Concept-world-logo (T-139). Eget arbejde (håndskrevet SVG), CC0. v2 (T-143): genereret af `ui/logo/src/gen_logo.py`; ordmærket er egne, håndtegnede monoline-bogstavformer (ingen font brugt).
