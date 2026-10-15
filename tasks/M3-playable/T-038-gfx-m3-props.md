# T-038: Grafik – Personale, dekoration, affald, nye forlystelser, nedbrudseffekt

- **Status:** review
- **Milepæl:** M3
- **Agent:** graphics
- **Afhænger af:** –

## Mål
Props: mechanic, cleaner, entertainer (genkendelige farver/hatte), bin, bench, tree (2-3 varianter), flowers, lamp (lys om natten forberedt), litter (lille bunke, 3 niveauer), swing_ride, haunted_house, go_karts. Nedbrudseffekt (røg-partikler, CPUParticles3D for web) som scene der kan sættes på en forlystelse. Se `_CONTRACT.md`.

## Acceptkriterier
- [x] Alle props instansierbare (udvid test_props.gd)
- [x] Compatibility-kompatibelt
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – graphics: staff (mechanic/cleaner/entertainer, StaffVisual: set_color/set_walking/hop), bin+bench forskudt mod -Z-kant, tree_round/pine/blossom, flowers, lamp (OmniLight3D slukket, set_on), litter (set_level 0-3), swing_ride (3×3, roterer), haunted_house (3×2), go_karts (4×3, karts kører), effects/breakdown_smoke.tscn (CPUParticles3D). test_props.gd udvidet; import + test.sh grønne (70/0).
