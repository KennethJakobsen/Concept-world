# T-021: Grafik – Props til M2-bygninger

- **Status:** review
- **Milepæl:** M2
- **Agent:** graphics
- **Afhænger af:** –

## Mål
Low-poly props for ferris_wheel, bumper_cars, burger_stand, drinks_stand, ice_cream_stand, toilet i samme stil som carousel (`game/scenes/props/<id>.tscn`). Animation hvor det giver mening (hjul drejer, radiobiler kører rundt). Valgfrit: lille "tanke-ikon"-scene over gæst (`thought_bubble.tscn` med `func show_text(t:String)` / `hide_bubble()`). Se `_CONTRACT.md` for origo/footprint.

## Acceptkriterier
- [x] 6 props, Compatibility-kompatible, instansierbare headless
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – graphics: 6 props (ferris_wheel m. drejende hjul, bumper_cars m. kørende biler, burger/drinks/ice_cream_stand, toilet) + thought_bubble.tscn (billboard-quad + Label3D, show_text/hide_bubble). Spinner fik `axis`-export (default Y). Primitive meshes, ingen eksterne assets. tests/test_props.gd tilføjet; import + test.sh grønne.
