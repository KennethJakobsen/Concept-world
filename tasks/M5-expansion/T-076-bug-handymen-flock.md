# T-076: Bug: rengøringsfolk løber i flok

- **Status:** done
- **Milepæl:** M5
- **Agent:** simulation
- **Afhænger af:** –

## Mål
Brugeren: "Rengøringsfolkene render rundt i samlet flok." Indfør opgavereservation, så hver opgave højst har én ansat, og spred ledige fejere.

## Acceptkriterier
- [x] Hver affaldscelle/skraldespand/inspektion reserveres af højst én ansat (udledt af `task`/`task_target_id`/`task_cell`)
- [x] Reservationen frigives ved udført opgave, fyring (drop_task) og timeout (`StaffAI.TASK_TIMEOUT_TICKS` = 1200)
- [x] Fejere vælger nærmeste ledige opgave; uden opgaver patruljerer de mod sti-cellen længst fra andre fejere (aldrig samme mål)
- [x] Mekanikere: reparation var allerede én pr. nedbrud; inspektioner er nu også reserveret
- [x] Deterministisk (fast rækkefølge, ingen ny RNG-brug)
- [x] Save: reservationer genopbygges af staff-state. Nyt felt `task_ticks` med default 0, så der er ingen formatændring og ingen migration
- [x] Tests: forskellige mål, spredning, mekanikere, fyring/timeout, round-trip og determinisme
- [ ] Brugeren bekræfter visuelt

## Log
- 2026-10-15 – simulation: oprettet efter brugerrapport, in-progress
- 2026-10-15 – simulation: implementeret i staff_ai.gd/staff.gd og 5 tests i test_staff_decor.gd. test.sh: 230/231 (fejlen i test_ui_m5 fandtes også før ændringen). integration.sh OK. → review
- 2026-10-16 – qa (T-096): Sim-delen er verificeret headless (tests grønne). Står på review, indtil brugeren har bekræftet visuelt, at fejerne spreder sig.
- 2026-10-16 – bruger: godkendt.
