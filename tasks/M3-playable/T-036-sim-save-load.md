# T-036: Simulation – Save/load med versionering

- **Status:** todo
- **Milepæl:** M3
- **Agent:** simulation
- **Afhænger af:** T-033

## Mål
Fuld serialisering af ParkSim inkl. RNG og alle under-objekter, migrationsramme og determinismetest. SaveStore i game/scripts/persistence/ må simulation-agenten også lave (ren fil-I/O). Se `_CONTRACT.md`.

## Acceptkriterier
- [ ] to_save/from_save for alt state
- [ ] Determinisme-test: gem midtvejs → indlæs → identisk state efter 2000 ticks
- [ ] Migration-test (v0 dummy → v1)
- [ ] SaveStore med tests (user://)
## Log
- 2026-10-15 – architect: oprettet
