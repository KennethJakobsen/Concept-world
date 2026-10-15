# T-059: Teksturer på terræn, stier og modeller

- **Status:** review
- **Milepæl:** M4
- **Agent:** graphics
- **Afhænger af:** T-058

## Mål
Brugerønske: teksturer i stedet for kun flade farver. Stiliseret, lav-kontrast, små opløsninger, kun egne assets. Prioritet: græs → sti-fliser → træ → tag/mursten/puds/metal (markiser urørt).

## Acceptkriterier
- [x] Egne procedurelle teksturer (64–128 px, PNG via LFS, mipmaps, lossless – ingen VRAM-kompression af hensyn til web) genereret af `game/tools/gen_textures.gd`
- [x] Græsterræn: tekstur i to skalaer + storskala-pletter, checker dæmpet, grid-linjer bevaret men svagere og fader på afstand
- [x] Sti-fliser: brosten (kant + indlæg)
- [x] Delte materialer i `game/assets/materials/*.tres` (triplanar + uv1_scale): wood, wood_dark, metal, roof_tiles, roof_shingles_dark, brick_purple, plaster_teal, path_stone, path_inlay
- [x] Træ/metal på bænk, spand, boder, forlystelser, indgang, toilet, spøgelseshus (træer, blomster og personer urørt)
- [x] Tage (spøgelseshus, toilet, go-kart-hytte, billetbod) og vægge (spøgelseshus mursten, toilet puds) via `material_override` – ingen node-navne ændret
- [x] Kilde/licens i `game/assets/CREDITS.md`
- [x] test.sh, integration.sh, smoke, build_web.sh grønne; index.pck 631 KB → 732 KB
- [ ] Brugeren bekræfter visuelt

## Ejer / må ikke røre
Ejer: `game/assets/`, `game/shaders/ground_grid.gdshader`, `game/scenes/props/*.tscn`, `game/tools/gen_textures.gd|apply_textures.py|render_preview.gd`, Ground-materialet i `game/scenes/main.tscn`. Må ikke røre simulation, audio, ui.

## Log
- 2026-10-15 – graphics: oprettet og udført. Teksturer genereres af `tools/gen_textures.gd` (periodisk value-noise/Worley, lyse gråtoner, så materialets farve tinter). `tools/apply_textures.py` (idempotent) erstatter m_/dm_ wood/brown/grey sub-materialer med delte .tres og sætter overrides på tag/vægge/sti. Kontrolrender i Compatibility (opengl3) via `tools/render_preview.gd`: brosten, mursten, tagspån og græs ser stiliserede ud; træplanker gjort længere (uv1_scale 1/2.2/1). Grid-linjer er stadig synlige altid (der findes ingen byggetilstands-toggle i shaderen; `line_strength` kan styres fra bridge senere). test.sh 152/0, integration OK, smoke uden fejl, web-pck +100 KB.
