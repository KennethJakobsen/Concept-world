# T-084: Sim: intensity, kvalme, opkast + save v3

- **Status:** todo
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-081

## Mål
Mekanik B for alle forlystelser og save-version 3 (kontrakt §1). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [ ] `AttractionDef.intensity/nausea`, og coaster-ratings mappes ×10
- [ ] `Guest.intensity_tolerance` (sim-RNG) og `Guest.nausea`, `too_intense`/`too_tame`
- [ ] Opkast: vomit-affald, glædetab, `guest_vomited`, `warning(&"guest_vomit")`, og rengøring fjerner det
- [ ] `SaveMigrations.CURRENT = 3`, `_v2_to_v3` med alle M6-defaults fra §1
- [ ] Tests: v1→v3, v2→v3, round-trip og determinisme

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: test_real_content_parses tillader nu M6-kinds (sideshow, flume, train, transport)
