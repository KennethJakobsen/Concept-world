# T-070: Gameplay – rutsjebane-værktøj, bridge, scenarie-flow

- **Status:** todo
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
