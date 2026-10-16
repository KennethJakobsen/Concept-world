# T-094: UI: spor-faner, fejltekster og info

- **Status:** review
- **Milepæl:** M6
- **Agent:** ui
- **Afhænger af:** T-090, T-091

## Mål
Byggemenu og info for de nye sporbaner (kontrakt §7 T-094). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] Spor-fane eller -faner pr. system
- [x] Danske tekster for `wrong_system`, `too_low` og `incomplete`
- [x] Info: plask (tømmerrende) og passagerer pr. dag (svævebane)
- [x] UI-tests og glyph-test er grønne

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-16 – ui: byggefanen "Baner og spor" med alle sporbaner; paletten filtreres efter system (CoasterPalette.set_system), knappen Endestation vises for svævebanen; M6Texts.track_error med danske tekster for alle 7 nye koder; info viser plask og passagerer i dag. test_ui_tracks.gd. test.sh (292) og integration.sh grønne. → review (visuelt tjek)
