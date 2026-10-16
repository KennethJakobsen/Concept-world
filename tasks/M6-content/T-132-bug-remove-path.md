# T-132: Bug: stier kan ikke fjernes

- **Status:** in-progress
- **Milepæl:** M6
- **Agent:** gameplay
- **Afhænger af:** –

## Mål
Brugerrapport: man kan ikke fjerne stier, når de først er sat. Sim har `cmd_remove_path`, og `build_tool.gd` fjerner kun ved højreklik-træk i sti-værktøjet (`_dragging == 2`) – det er ikke opdageligt og virker muligvis heller ikke (f.eks. hvis højreklik fanges af kameraet, eller hvis stien er indgang til en attraktion eller har dekoration).

1. Verificér om højreklik-fjernelse overhovedet virker i spillet, og ret det.
2. Tilføj et synligt "Fjern sti"/nedrivningsværktøj (knap i byggemenuen + tooltip) med ghost-markering, der viser hvilke celler der fjernes. Lille, minimal UI-ændring – det store UX-redesign kommer i M7 (T-101).
3. Giv feedback, når en celle ikke kan fjernes (f.eks. attraktionens indgang).

## Acceptkriterier
- [ ] Stier kan fjernes både via synligt værktøj og højreklik i sti-værktøjet
- [ ] Indgangsceller giver forklarende besked i stedet for ingenting
- [ ] Test gennem build_tool

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens rapport
