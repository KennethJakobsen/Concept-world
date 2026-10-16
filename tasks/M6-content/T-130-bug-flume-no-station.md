# T-130: Bug: tømmerrende kan ikke færdiggøres – "banen mangler en station"

- **Status:** in-progress
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-090, T-093

## Mål
Brugerrapport (screenshot): en lukket tømmerrende med synlig station (flume_station med træstamme) giver "Banen mangler en station", når man trykker Færdig. (Nummer T-130 for ikke at kollidere med QA's bug-tasks fra T-121.)

Undersøg hele kæden: sim-validering (station-id pr. system, `station_id(system, role)`, `kind == "station"`-tjek, `multiple_stations`/`incomplete`), byggeværktøjets start af banen (placeres stationen som rutsjebanens station i stedet for flume-stationen?), og UI's mapping af fejlkode → tekst.

## Acceptkriterier
- [ ] En lukket tømmerrende og et lukket minitog kan færdiggøres via UI-kæden
- [ ] Test, der går gennem build_tool/palette (som i test_track_view) og reproducerer fejlen
- [ ] Fejlteksten matcher den reelle fejlkode

## Log
- 2026-10-16 – orkestrator: oprettet ud fra brugerens screenshot
