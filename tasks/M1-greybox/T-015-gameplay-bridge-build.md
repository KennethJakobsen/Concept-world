# T-015: Gameplay – Bridge og byggeværktøjer

- **Status:** done
- **Milepæl:** M1
- **Agent:** gameplay
- **Afhænger af:** T-013, T-014

## Mål
Forbind ParkSim med scenen og lad spilleren bygge.

## Indhold
- `game/scripts/bridge/park_view.gd`: ejer `ParkSim` (64×64), kalder `update(delta)`, lytter på signaler og opretter/opdaterer noder (stier, attraktioner, gæster interpoleret mellem cell og next_cell).
- `game/scripts/building/build_tool.gd`: værktøjer Sti (venstreklik/træk), Fjern sti (højreklik), Karrusel (tast 2), med highlight-preview. Tast 1 = sti.
- Simpel debug-label: antal gæster, tick, hastighed. Space = pause, +/- = hastighed.
- Tilføj til `scenes/main.tscn`.

## Acceptkriterier
- [x] Spilleren kan bygge sti fra indgang til en karrusel og se gæster gå, stå i kø, køre og gå igen
- [x] Ingen spillogik i bridge/building
- [x] Web-build virker

## Log
- 2026-10-15 – gameplay: ParkView (bridge, signaler→noder, gæste-lerp/rotation/kø-spredning, RIDING skjult) + BuildTool (1/2, træk-sti, højre=fjern, 3×3 preview via can_place_attraction, Space/+/-, debug-label). test_park_view.gd tilføjet; tests 18/18, smoke og web-build OK. Manuel visuel test i editor mangler.
- 2026-10-15 – qa: test_park_view + headless smoke (300 frames, ingen fejl) + web-build OK; ingen spillogik i bridge/building (kun kommandoer/visning) → done. Manuel visuel verifikation afventer bruger.
