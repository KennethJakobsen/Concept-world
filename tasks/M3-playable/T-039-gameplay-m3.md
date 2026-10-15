# T-039: Gameplay – Personale, dekoration, affald og nedbrud i scenen

- **Status:** done
- **Milepæl:** M3
- **Agent:** gameplay
- **Afhænger af:** T-037, T-038

## Mål
Placér personale og dekoration (byggeværktøjer), vis affald pr. sti-celle, nedbrudseffekt på forlystelser, personale-noder interpoleret som gæster. Hovedscene-flow: start fra hovedmenu, ny park/indlæs → ParkView genopbygger scenen ud fra en indlæst ParkSim. Se `_CONTRACT.md`.

## Acceptkriterier
- [x] ParkView kan genopbygge fuld scene fra indlæst save
- [x] Byg/fjern dekoration, ansæt/flyt personale via Selection/BuildTool
- [x] Tests
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – gameplay: Autoload GameSession (pending_save, seed, start_new, start_from_save, current_sim, save_to, load_from, go_to_main_menu, autosave ved day_passed). ParkView: setup(sim) → rebuild() (alle noder i Content-barn; stier, indgang, bygninger, røg, decor, personale, gæster, affald), lytter på staff/decor/broken/repaired/litter_changed; personale interpoleres (set_walking), affald poolet, RESTING-gæster ved bænk, lamper set_on(false), node_counts()/staff_near/decor_at. Selection: +selected_staff, +pause_menu_requested. BuildTool: decor:<id>, staff:<type>, staff_move:<id>, træk valgt personale i select, remove tager decor først, Esc → select / pause-menu. Tests: rebuild fra save, alle 7 decor, ansæt/flyt/fyr, affald/røg (104 grøn). Import/web ok; smoke har SCRIPT ERROR i scripts/ui/hud.gd:104 (UI-agentens igangværende arbejde, ikke bridge).
- 2026-10-15 – qa: godkendt (T-041): test.sh 116/116, integration.sh grøn, smoke main_menu+main 300 frames uden ERROR/WARNING, web-build ok. → done
