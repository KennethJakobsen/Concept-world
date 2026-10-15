# T-090: Sim: generaliseret spor, tømmerrende og minitog

- **Status:** todo
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-082, T-086, ADR-004

## Mål
ADR-004 i sim samt mekanik A og Bimmelbanen på spor (kontrakt §4 T-090). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [ ] `TrackPieceDef.system`, `CoasterContent.pieces(system)`, `Attraction.is_tracked()`
- [ ] Fejlkoderne `wrong_system`, `too_low` og `incomplete`, `clearance_levels` fra data
- [ ] Flume: friktion, `splashes`, `wet_thirst`, `wet_ticks` og `ride_splash` udledt i sim
- [ ] Train: profil med konstant fart, ratings fra data
- [ ] Alle M5-coaster-tests er uændret grønne, og determinismetesten dækker alle tre systemer

## Log
- 2026-10-15 – architect: oprettet
