# T-130: Bug: tømmerrende kan ikke færdiggøres – "banen mangler en station"

- **Status:** review
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-090, T-093

## Mål
Brugerrapport (screenshot): en lukket tømmerrende med synlig station (flume_station med træstamme) giver "Banen mangler en station", når man trykker Færdig. (Nummer T-130 for ikke at kollidere med QA's bug-tasks fra T-121.)

Undersøg hele kæden: sim-validering (station-id pr. system, `station_id(system, role)`, `kind == "station"`-tjek, `multiple_stations`/`incomplete`), byggeværktøjets start af banen (placeres stationen som rutsjebanens station i stedet for flume-stationen?), og UI's mapping af fejlkode → tekst.

## Acceptkriterier
- [x] En lukket tømmerrende og et lukket minitog kan færdiggøres via UI-kæden
- [x] Test, der går gennem build_tool/palette (som i test_track_view) og reproducerer fejlen
- [x] Fejlteksten matcher den reelle fejlkode

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens screenshot
- 2026-10-16 – simulation: Årsag: ikke sim (sim-validering af lukket rende/minitog er korrekt). BuildTool.coaster_id er ren værktøjstilstand og nulstilles af Esc, Vælg-værktøjet, nyt værktøjsvalg og ved indlæsning af save; et nyt klik på byggeknappen (eller Færdig med paletten åben) gav derefter coaster_id=-1 → finish_coaster() returnerede hårdkodet "no_station", selv om banen har station. Rettelse (building/ui): `finish_coaster(prefer_id)` genoptager nu en ufærdig bane (paletten sender `resume_id`; ellers den eneste ufærdige af værktøjets type / i parken) via `find_unfinished_coaster`; tvetydigt → ny kode `no_active_track` ("Vælg den ufærdige bane og tryk 'Fortsæt byg'.") i M6Texts. Test: `tests/test_track_finish_chain.gd` (palette → BuildTool → sim for tømmerrende og minitog, inkl. reproduktion efter værktøjsskift/Esc). Gemte ufærdige baner virker (status `building` gemmes; Færdig finder dem). test.sh + integration.sh grønne.
