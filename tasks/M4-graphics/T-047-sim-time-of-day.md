# T-047: Sim – tid på dagen, selv-reparation, nye signaler

- **Status:** done
- **Milepæl:** M4
- **Agent:** simulation
- **Afhænger af:** – (bruger defaults indtil T-046 lander data)

## Mål
Implementér `_CONTRACT.md` §1, §2 og de tre nye signaler i §5 (`purchase_made`, `litter_swept`, `ride_cycle_started`) samt `warning`.

## Acceptkriterier
- [x] `time_of_day()`, `is_night()`, `phase()`, `clock_text()`, `phase_changed` – med tests (grænser, wrap ved dagskifte, signal kun ved overgang)
- [x] Indlæser `daynight.json` med defaults hvis den mangler
- [x] Selv-reparation når ingen mekaniker er ansat; omkostning bogføres som `repairs`; `self_repair_ticks = 0` slår fra; tests
- [x] `warning(&"broken_no_mechanic", …)` én gang pr. nedbrud
- [x] `purchase_made`, `litter_swept`, `ride_cycle_started` udsendes og er testet
- [x] Save/load-determinisme-test stadig grøn; evt. nye felter har defaults
- [x] `tools/test.sh` og `tools/balance.sh` grønne; balance-tal for startpark uden personale noteret i loggen

## Ejer / må ikke røre
Ejer: `game/simulation/`, sim-tests i `game/tests/`. Må ikke røre `game/scripts/`, `game/scenes/`, `game/content/` (data = designer).

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: implementeret. `ParkSim.time_of_day/is_night/phase/clock_text`, `phase_changed` (afledt af day_tick, intet nyt state), `warning`, `purchase_made` (ved betaling i `_try_enter`), `litter_swept` (StaffAI ved fej af ikke-tom celle), `ride_cycle_started` (kun kind=ride). Balance læser `daynight.json` (ny 5. parameter til `from_dicts`) + `self_repair_ticks/self_repair_cost` fra staff_rules (defaults 2400/200). Selv-reparation kun uden ansat mekaniker; `Attraction.self_repair_elapsed` gemmes (default 0, ingen version-bump). Tests: `game/tests/test_time_of_day.gd` (11 tests). test.sh: alle sim-tests grønne (eneste fejl `test_ui_m4` tilhører UI-agentens igangværende T-052).
- Balance (startpark uden personale, 7 dage, seeds 12345/1/2/3/4): penge d7 snit 3619, omdømme 59.6, gæster 345, nedbrud 1.6, ødelagt-dage snit 0.77 (maks 1.5) – parken "dør" ikke længere; med personale 4309/75.4/373/0.06.
- 2026-10-15 – qa (T-053): verificeret – test.sh 145/0; ny test_qa_m4.gd: fuld spildag med rigtige data giver dawn→day→dusk→night→dawn, save om natten → load giver samme clock_text()/phase. → done
