# T-132: Bug: stier kan ikke fjernes

- **Status:** done
- **Milepæl:** M6
- **Agent:** gameplay
- **Afhænger af:** –

## Mål
Brugerrapport: man kan ikke fjerne stier, når de først er sat. Sim har `cmd_remove_path`, og `build_tool.gd` fjerner kun ved højreklik-træk i sti-værktøjet (`_dragging == 2`) – det er ikke opdageligt og virker muligvis heller ikke (f.eks. hvis højreklik fanges af kameraet, eller hvis stien er indgang til en attraktion eller har dekoration).

1. Verificér om højreklik-fjernelse overhovedet virker i spillet, og ret det.
2. Tilføj et synligt "Fjern sti"/nedrivningsværktøj (knap i byggemenuen + tooltip) med ghost-markering, der viser hvilke celler der fjernes. Lille, minimal UI-ændring – det store UX-redesign kommer i M7 (T-101).
3. Giv feedback, når en celle ikke kan fjernes (f.eks. attraktionens indgang).

## Acceptkriterier
- [x] Stier kan fjernes både via synligt værktøj og højreklik i sti-værktøjet
- [x] Indgangsceller giver forklarende besked i stedet for ingenting
- [x] Test gennem build_tool

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens rapport
- 2026-10-16 – gameplay: Årsag: "Fjern"-værktøjet (X) fjernede kun bygning/dekoration – klik på sti gjorde intet; højreklik-træk i sti-værktøjet virkede, men var uopdageligt, og indgangsceller blev stille afvist. Kameraet sluger ikke højreklik (park_camera håndterer kun scroll). Rettet: `BuildTool.remove_path_at()` (floating "+refund", signal `remove_blocked` → HUD-toast ved indgang), fjern-værktøjet falder tilbage til sti og understøtter træk, rød ghost over sti i fjern-værktøj og ved højreklik i sti-værktøj, tooltips på Sti/Fjern. Test: tests/test_remove_path.gd. test.sh: 315/317 (de 2 fejl skyldes T-131's igangværende research.json/test_scenario_track_unlocks), integration.sh OK. Visuelt: kræver brugerens bekræftelse.
- 2026-10-16 – bruger: godkendt.
