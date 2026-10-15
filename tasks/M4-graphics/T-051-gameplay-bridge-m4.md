# T-051: Bridge – dag/nat, effekter og lyd i scenen

- **Status:** review
- **Milepæl:** M4
- **Agent:** gameplay
- **Afhænger af:** T-047, T-048, T-049, T-050

## Mål
Forbind det hele i `ParkView` jf. `_CONTRACT.md` §5 (signal → effekt/lyd-tabellen).

## Acceptkriterier
- [x] `DayNightRig` i `main.tscn`/ParkView, tid interpoleret glat mellem ticks, også ved 2x/3x og pause
- [x] Lamper og forlystelseslys følger `night_factor`
- [x] Alle rækker i signal-tabellen implementeret; coins/cash throttlet
- [x] Gæster/personale: `set_walking` efter bevægelse; emotes ved tanker (glad/vred/syg) og arbejde (fej/reparer)
- [x] Forlystelser `set_running`/`set_broken` følger sim-status – også efter indlæsning af et save
- [x] Ambience skifter ved `phase_changed`; musik `menu`/`park` ved sceneskift
- [x] `fx_event`-signal + headless test: placering/nedbrud/reparation udsender forventede events
- [x] `tools/test.sh`, `tools/integration.sh`, smoke grønne uden ERROR/WARNING

## Ejer / må ikke røre
Ejer: `game/scripts/bridge|building/`, `game/scenes/main.tscn`. Må ikke røre `game/simulation/`, `game/scripts/rendering|ui/` (bestil ændringer via ny task).

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – gameplay: implementeret. ParkView: DayNightRig (instans i main.tscn under ParkView, gammel Sun/WorldEnvironment fjernet; oprettes i kode hvis den mangler), glat visningstid (fremskrives med delta×speed, låst til [sim-tid, +1 tick), snap ved spring, står stille ved pause). Lamper `set_intensity`/forlystelser `set_lights` via `night_factor()` (kun ved ændring ≥0.01). Signal-tabellen: build_dust/confetti/build, demolish, breakdown_smoke+set_broken+breakdown, repair_sparks+emote repair+repair (Staff WORKING/TASK_REPAIR poll), repaired stopper røg/gnister, coins+cash throttlet 4/s, sweep_dust+sweep+emote sweep, set_running via poll af `is_running()` (virker efter load), ride_start kun ≤25 m fra kamera, ambience day/night (dusk/night → night). Gæst `set_walking` + emote ud fra tanker (`ParkView.thought_emote`). `signal fx_event`. Musik menu/park styres af GameSession ud fra current_scene. Under rebuild (load) undertrykkes effekter/lyd. Tests: `test_fx_events_place_break_repair`, `test_thought_emotes`. test.sh 144/0, integration OK, smoke uden ERROR/WARNING. Ingen ændringer i simulation/, rendering/ eller ui/. Bemærk: sim har ingen "syg"-tanke endnu – sick-emote trigges kun hvis tanken indeholder kvalm/syg/ondt. Visuelt kræver brugerens øjne.
- 2026-10-15 – qa (T-053): headless OK (fx_event-tests, integration OK, smoke main+main_menu uden ERROR/WARNING). Visuelt check kræver brugeren (se T-053-tjekliste). Bliver på review.
