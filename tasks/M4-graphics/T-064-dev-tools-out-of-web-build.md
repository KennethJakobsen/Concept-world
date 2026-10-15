# T-064: Udviklingsværktøjer ud af web-build

- **Status:** done
- **Milepæl:** M4
- **Agent:** architect
- **Afhænger af:** T-061

## Mål
`game/tools/*` (gen_textures, render_preview, apply_textures.py, balance_sim, integration_flow) og `game/tests/*` må ikke komme med i exports.

## Acceptkriterier
- [x] `exclude_filter="tools/*, tests/*"` i alle presets i `game/export_presets.cfg` (Web, macOS)
- [x] Web-build bygger; `strings index.pck` indeholder ingen `res://tools/` eller `res://tests/` stier (main.tscn stadig med)
- [x] test.sh (154 ok) og integration.sh grønne (de kører fra projektet, ikke fra pck)

## Log
- 2026-10-15 architect: filter tilføjet, web-build verificeret, tests grønne. Done.
