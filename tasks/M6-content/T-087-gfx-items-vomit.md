# T-087: Grafik: bærbare ting, opkast og plask

- **Status:** review
- **Milepæl:** M6
- **Agent:** graphics
- **Afhænger af:** T-083, T-086

## Mål
Visning af ting på gæster og effekter (kontrakt §5 T-087). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `GuestVisual.set_items` med ballon, pose og bamse
- [x] Effekterne `balloon_float`, `vomit` (pøl som mesh) og `splash` med CPUParticles3D
- [x] Prop-tests er grønne
- [ ] Brugeren har godkendt udseendet

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – graphics: implementeret. Offentlig API til bridge (T-088/T-093):
  - `GuestVisual.set_items(items: Array[StringName])` – viser `balloon` (paa snor, svajer), `souvenir` (pose), `prize_bear`/`prize_duck` (ukendt `prize_*` = bamse). Tom liste fjerner alt. `get_items()` til debug. Noderne bygges dovent i barnet `Items` (`CarriedItemsVisual`), saa gaester uden ting koster intet.
  - Effektscener i `res://scenes/effects/`: `balloon_float.tscn`, `vomit.tscn`, `splash.tscn`. Brug som de andre FX: instantier, saet `position` = cellens verdenspos (jordhoejde), `add_child`, kald `play()`. Alle frigiver sig selv. Tilfoej dem til `ParkView.FX_SCENES` (`&"balloon_float"`, `&"vomit"`, `&"splash"`).
  - `vomit` = draaber (CPUParticles3D) + lille poel-mesh (CylinderMesh, ingen decal), der toner ud efter ~7 s (`VomitFx`). Den vedvarende tilsmudsning er affaldet.
  - Alt er primitiver/CPUParticles3D (Compatibility). Tests: `test_guest_items` + FX-listen i `test_props.gd`. `./tools/test.sh` 260/260 groen. Afventer brugerens godkendelse af udseendet.
