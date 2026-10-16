# T-093: Gameplay: byggeværktøj for alle sporsystemer

- **Status:** review
- **Milepæl:** M6
- **Agent:** gameplay
- **Afhænger af:** T-090, T-091, T-092

## Mål
Spor-værktøjet generaliseres, og plask og transport vises i scenen (kontrakt §6 T-093). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `coaster:<id>` virker for flume, train og transport, og paletten er filtreret
- [x] Placering af endestation for svævebanen
- [x] `ride_splash` → splash, og transportgæster skjules og vises
- [x] `integration.sh` bygger alle tre baner headless

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – gameplay: BuildTool: `coaster_system()`, `coaster_palette()` (systemets stykker uden stationer, til UI), `end_station_piece()`, `can_place_end_station()`/`place_end_station()` (svævebanen, > 1 stykke og ingen endestation endnu); valgt stykke nulstilles ved skift til andet system. ParkView: stationsscene pr. system (flume/train/monorail_station.tscn, `level` sat for svævebanen), endestation som egen node (`end_station_node(id)`), `set_style(system)` efter `set_cars`, svævebanens kabine stopper ved endestationen, `ride_splash` → FX `splash` + lyd, gæster med state `riding_transport` skjules. Test `tests/test_track_view.gd`; `integration_flow.gd` bygger alle tre baner via BuildTool. test.sh (295) og integration.sh grønne. Venter på visuel bekræftelse.
