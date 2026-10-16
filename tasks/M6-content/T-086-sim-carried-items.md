# T-086: Sim: bærbare ting (ballon, souvenir, præmier)

- **Status:** review
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-085

## Mål
Mekanik E (kontrakt §3). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `ItemDef` og `Guest.items`, køb og gevinst giver en ting
- [x] Glæde pr. time og aura pr. time (manhattan-radius)
- [x] Ballon flyver væk via sim-RNG, `item_lost`/`item_gained`
- [x] `guest_info` med items, nausea og tolerance, og items gemmes
- [x] Tests og determinisme

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – simulation: ItemDef (guests/item_def.gd), AttractionDef.carry_item, timevis tick (_tick_items_hour, hour_ticks()=day_ticks/24) med glæde, aura (manhattan) og ballontab via sim-RNG; signaler item_gained/item_lost; ny ParkSim.guest_info(id) (fandtes ikke før). Items gemmes allerede (T-084/v3). Tests: test_carried_items.gd.
