# T-084: Sim: intensity, kvalme, opkast + save v3

- **Status:** done
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-081

## Mål
Mekanik B for alle forlystelser og save-version 3 (kontrakt §1). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `AttractionDef.intensity/nausea`, og coaster-ratings mappes ×10
- [x] `Guest.intensity_tolerance` (sim-RNG) og `Guest.nausea`, `too_intense`/`too_tame`
- [x] Opkast: vomit-affald, glædetab, `guest_vomited`, `warning(&"guest_vomit")`, og rengøring fjerner det
- [x] `SaveMigrations.CURRENT = 3`, `_v2_to_v3` med alle M6-defaults fra §1
- [x] Tests: v1→v3, v2→v3, round-trip og determinisme

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: test_real_content_parses tillader nu M6-kinds (sideshow, flume, train, transport)
- 2026-10-16 – simulation: implementeret. `AttractionDef.intensity/nausea`, `Attraction.intensity_value()/nausea_value()` (coaster: ratings×10), `Guest.intensity_tolerance/nausea/items`, tolerance trækkes med sim-RNG ved spawn. Gammel id-baseret coaster-tolerance og `_maybe_sick` er erstattet af den generelle mekanik. Opkast: `ParkWorld.vomit` (delmængde af litter, gemmes som `world.vomit`), rengøring (`set_litter(c, 0)`) fjerner det. Signal `guest_vomited`, `warning(&"guest_vomit", {cell, guest_id})`, `get_stats()["vomit"]`. Save v3 (`_v2_to_v3`): affald har ingen liste-objekter, så "litter[].kind" er realiseret som `world.vomit = []`. Tests: test_intensity_nausea.gd. test.sh og integration.sh grønne.
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. → done
