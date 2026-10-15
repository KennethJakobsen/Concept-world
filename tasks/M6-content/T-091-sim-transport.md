# T-091: Sim: svævebane – transport mellem to stationer

- **Status:** todo
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-090

## Mål
Mekanik C (kontrakt §4 T-091). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [ ] Åbent system med start- og end-station
- [ ] `ParkWorld.add_link/remove_links/links_from`
- [ ] Pathfinder bruger links deterministisk, og kun når de er åbne og ikke brudt ned
- [ ] Gæst: kø, billet og transport, og fattige gæster undgår linket
- [ ] Links genopbygges ved load, og der er tests for brudt/lukket bane

## Log
- 2026-10-15 – architect: oprettet
