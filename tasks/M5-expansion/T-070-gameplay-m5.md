# T-070: Gameplay – rutsjebane-værktøj, bridge, scenarie-flow

- **Status:** review
- **Milepæl:** M5
- **Agent:** gameplay
- **Afhænger af:** T-068, T-069

## Mål
Implementér `_CONTRACT.md` §6.

## Acceptkriterier
- [ ] `BuildTool` coaster-tilstand: placering af station med rotation, `set_coaster_piece`, ghost-preview (grøn/rød), placering, Backspace, "Færdig" og `coaster_errors`-signal. Esc lader banen stå ufærdig, og "Fortsæt byg" genoptager den
- [ ] Låste id'er afvises med `error`-lyd
- [ ] `ParkView`: mesh pr. rutsjebane, genbygget ved `coaster_changed`. Toget følger banen glat (interpoleret) og står stille i stationen mellem ture
- [ ] `GameSession.start_scenario`, `start_sandbox` (`start_new` er alias) og pause ved `scenario_finished`
- [ ] Lyd: `cheer` ved `research_unlocked` og ved sejr, `error` ved nederlag
- [ ] Tests: headless placering af en lukket oval via BuildTool-API'et, og scenariestart via GameSession. `tools/test.sh` og `tools/integration.sh` (udvidet: menu → scenarie → gem → indlæs) er grønne
- [ ] Status forbliver `review`, indtil brugeren har bekræftet byggeoplevelsen

## Ejer / må ikke røre
Ejer: `game/scripts/bridge|building|persistence/`, `game/scenes/main.tscn` og gameplay-tests. Må ikke røre simulation/, rendering/ og ui/.

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – gameplay: implementeret. BuildTool: `set_tool` returnerer bool og afviser låste id'er (bygning/decor/coaster) med `error`-lyd. Rutsjebane-API til UI: `place_coaster_station(cell, heading)`, `rotate_coaster()` (R), `set_coaster_piece(id)`, `place_coaster_piece()` (klik/Enter), `remove_last_coaster_piece()` (Backspace), `finish_coaster()` (udsender `coaster_errors(codes)` ved fejl, `coaster_finished(id)` ved succes), `resume_coaster(id)` ("Fortsæt byg"), `is_building_coaster()`, `coaster_id`. Esc nulstiller coaster_id, og banen bliver stående. Ghost via CoasterTrackMesh.set_ghost, stationspreview via highlights (station + indgangscelle). ParkView: CoasterVis pr. bane (mesh + tog), genbygges ved `coaster_changed`, stationen roteres efter heading, toget interpoleres mellem ticks og står i stationen ved progress 0. Buelængden skaleres mesh_total/profile.length. GameSession: `start_scenario`, `start_sandbox`, `start_new` (alias) og `pending_scenario`. `scenario_finished` pauser og spiller cheer/error, og `research_unlocked` spiller cheer. Tests: `tests/test_coaster_build.gd` (4) og integration med menu → scenarie → gem → indlæs. test.sh 218/218, integration OK. Afventer brugerens bekræftelse af byggeoplevelsen.
- 2026-10-15 – qa (T-072): Headless (integration, smoke) er grøn. Afventer brugerens visuelle bekræftelse.
