# T-061: Bug: karrusel, gokart og pariserhjul mangler teksturer

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** T-059

## Mål
Brugerrapport: karrusel, gokart og pariserhjul står med flade farver. Brug T-059's teksturer/materialer, behold farver og stiliseret look. Gennemgå også svingkarrusel og radiobiler.

## Acceptkriterier
- [x] Ny egen asfalt-tekstur (`asphalt.png`, 128 px, lossless, LFS) i `tools/gen_textures.gd` + `materials/asphalt.tres` på gokartbanen
- [x] `tools/apply_textures.py` (idempotent) udvidet med `TINT`: farvede sub-materialer får tekstur (metal/plaster/planks/grass/asphalt) + triplanar, farven bevares
- [x] Karrusel (metal på guld/stænger, puds på dæk/heste/tag), pariserhjul (metal på stel/ring/eger/kabiner, træ på platform/billetbod), gokart (asfalt bane, græs-tekstur, kantsten/dæk, metal karts), svingkarrusel og radiobiler gennemgået
- [x] Hud og glas urørt; node-navne/API'er uændrede
- [x] `tools/render_preview.gd` tager valgfri prop-liste som 2. argument
- [x] CREDITS.md opdateret
- [x] test.sh, integration.sh, smoke grønne; kontrolrender (Compatibility)
- [x] Runde 2: tydelige teksturer (stærkere kontrast/uv-skala) på alle forlystelser inkl. radiobiler (biler, riflet gulv, hegn, tag) og spøgelseshus
- [x] Test `test_rides_fully_textured`: ingen mesh på forlystelserne uden tekstur (undtagen hud, glas/vinduer, emissive)
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/assets/`, `game/scenes/props/*.tscn`, `game/tools/gen_textures.gd|apply_textures.py|render_preview.gd`. Må ikke røre simulation, audio, ui.

## Log
- 2026-10-15 – graphics: oprettet og udført. Kontrolrender (opengl3) af alle fem forlystelser: farver bevaret, svag tekstur synlig (træplanker på platforme, metalstriber, asfaltkorn). test.sh 153/0, integration OK, smoke uden fejl.
- 2026-10-15 – graphics: runde 2 (brugeren: radiobiler m.fl. ser stadig utekstureret ud – kontrasten var for lav, ~±5 %). Nye egne teksturer med tydelig kontrast: `tread` (riflet diamantplade), `panel` (metalpanel m. samlinger og nitter), `canvas` (stof med striber/vævning), `steel` (børstet stål med bånd) + materialer `steel.tres`, `tread_plate.tres`. `apply_textures.py` dækker nu alle farvede sub-materialer i alle seks forlystelser (default panel; tage/flag/skilte canvas; gummi asfalt; platforme planker), erstatter tidligere tekstur-linjer (genkørbar), skifter `metal` -> `steel` kun på forlystelser og lægger `tread_plate` på radiobil-gulvet. Spøgelseshusets resterende flade dele (sokkel, stakit, gravsten, spir, græskar, spøgelse) fik også tekstur. `render_preview.gd` har nu `close`-nærbillede. Nærbilleder af alle seks forlystelser tjekket: samlinger, nitter, striber og gulvplade er tydelige, og farverne er bevaret. test.sh 154/0.
- 2026-10-15 – orkestrator: brugeren har godkendt. Status: done.
