# T-091: Sim: svævebane – transport mellem to stationer

- **Status:** review
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-090

## Mål
Mekanik C (kontrakt §4 T-091). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] Åbent system med start- og end-station
- [x] `ParkWorld.add_link/remove_links/links_from`
- [x] Pathfinder bruger links deterministisk, og kun når de er åbne og ikke brudt ned
- [x] Gæst: kø, billet og transport, og fattige gæster undgår linket
- [x] Links genopbygges ved load, og der er tests for brudt/lukket bane

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – simulation: implementeret. `ParkWorld.add_link(a, b, cost, owner_id)` (tovejs), `remove_links(owner_id)`, `links_from(cell)` (sorteret efter owner_id), `has_links()`, signal `links_changed`. `PathFinder.find_path(from, to, budget = -1)`: med budget ≥ 0 bruges kanter, hvor `link_usable(owner)` er sand og prisen ≤ budget (Dijkstra med float-vægte, stabil rækkefølge; uden kanter er A* uændret). `ParkSim.link_usable(id)`, `transport_exit_cell(a)`, `guest_state_name(g)` (`&"riding_transport"`/`&"queuing_transport"`), `guest_info()["state"]`, `attraction_stats()["riders_today"/"splashes"]`. Gæsteruter bruger `_route(g, to)` med `g.money` som budget; personale bruger ikke kanter. Gæsten betaler, står i kø, kører `ride_ticks` og står derefter ved den anden indgang (`Guest.transport_id/transport_dest/transport_resume_state`, defaults i v3-migrering). `Attraction.riders_today` nulstilles ved dagsskifte. Links gemmes ikke, men genopbygges i `_restore_coaster`. Nåbarhed følger brugbare kanter. Tests: `test_transport.gd`.
- Afvigelse: `cmd_finish_coaster` for transport kan give de nye fejlkoder `exit_blocked` (endestationens indgang er blokeret) og `stations_too_close` (indgangene støder op til hinanden). Transport tæller som facilitet i tiltrækning (ikke forlystelse) og kan bryde ned som forlystelser.
