# T-136: Design: samlet visuel stil for UI (art direction)

- **Status:** review
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-101

## Mål
Brugerfeedback på T-101: byggemenuen er tekst på blå knapper på grå baggrund – ikke stemningsfuld. Der skal være ikoner/billeder, og menuer, paneler, HUD og hovedmenu skal fremstå som én helhed. Undersøg hvordan andre park-spil gør (Planet Coaster, Parkitect, RollerCoaster Tycoon 2/3, Two Point Hospital/Campus, Jurassic World Evolution) og lav en stilguide.

## Acceptkriterier
- [x] `docs/ui-style.md`: research-noter (hvad gør de andre spil, hvad tager vi), farvepalet, materialer (fx træ/papir/emalje-skilte), typografi (kun standardfont-tegn eller egen CC0-font), hjørner/kanter/skygger, ikonstil, kortlayout med billede (miniature af prop'en) + navn + pris, hover/valgt/låst-tilstande
- [x] Specifikation af byggemenu, kategori-ikoner, TopBar, Inspector, ParkRail, AlertTray, hovedmenu
- [x] Ikonliste (alle kategorier, værktøjer, rail-ikoner) med beskrivelse
- [x] Kun egne/CC0-assets, virker i Compatibility/web

## Log
- 2026-10-16 – orkestrator: oprettet efter brugerfeedback på byggemenuen
- 2026-10-16 – designer: review. `docs/ui-style.md` skrevet: retningen "Tivoli-skilt" (træ/papir/messing), research (RCT2/3, Planet Coaster, Parkitect, Two Point, JWE), palet med hex, StyleBox-tabel, typografi (standardfont, valgfri Kenney Future CC0), ikonstil, miniature-spec (160×120, offline-render), komponent-specs (BuildDock, TopBar, ParkRail, Inspector, AlertTray, hovedmenu, tooltip) og en ikonliste.
