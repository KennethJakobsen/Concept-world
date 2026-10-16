# T-090: Sim: generaliseret spor, tømmerrende og minitog

- **Status:** done
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-082, T-086, ADR-004

## Mål
ADR-004 i sim samt mekanik A og Bimmelbanen på spor (kontrakt §4 T-090). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `TrackPieceDef.system`, `CoasterContent.pieces(system)`, `Attraction.is_tracked()`
- [x] Fejlkoderne `wrong_system`, `too_low` og `incomplete`, `clearance_levels` fra data
- [x] Flume: friktion, `splashes`, `wet_thirst`, `wet_ticks` og `ride_splash` udledt i sim
- [x] Train: profil med konstant fart, ratings fra data
- [x] Alle M5-coaster-tests er uændret grønne, og determinismetesten dækker alle tre systemer

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – simulation: implementeret. `TrackPieceDef.system/splash/water/min_level/max_level/station_role/allow_rise/allow_turn` (rise nu -2..2), `CoasterContent.pieces(system)/system_def/systems/system_for_kind/is_tracked_kind/station_id(system, role)`, `CoasterTrack(system)` med `closed_loop/max_stations/clearance_levels/speed_mode`, `is_complete()`, fejlkoderne `wrong_system`, `too_low`, `incomplete`. Preview giver også `wrong_system`/`too_low`/`multiple_stations`. Stationen startes på `min_level`. `CoasterPhysics` konstant fart (`cruise_speed`), `CoasterProfile.splashes/splash_s/splash_pieces`. Signal `ParkSim.ride_splash(attraction_id, cell)` udledt i `_on_tick`. `wet_thirst`, `Guest.wet_ticks` (+glæde i dag-fasen, `guests.json` `wet_ticks`/`wet_happiness_per_tick` med defaults 600/0.005). Ikke-coaster-spor får ratings fra data. `Attraction.is_tracked()`, `is_ride()` omfatter flume/train. Save v3-defaults udvidet. Tests: `test_track_systems.gd`. NB: sim-ændringerne kom ved en fejl med i graphics' commit c9c87a7 (T-092); T-090-commit indeholder tests og task.
- Afvigelse: `max_coaster_excitement()` (scenarie-mål) tæller stadig kun rigtige rutsjebaner. `allow_rise/allow_turn` parses men håndhæves ikke (systemets stykker har allerede rise/turn 0).
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. → done
