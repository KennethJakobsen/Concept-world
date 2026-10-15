# T-015: Gameplay – Bridge og byggeværktøjer

- **Status:** todo
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
- [ ] Spilleren kan bygge sti fra indgang til en karrusel og se gæster gå, stå i kø, køre og gå igen
- [ ] Ingen spillogik i bridge/building
- [ ] Web-build virker
