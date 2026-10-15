# T-019: Simulation – Økonomi

- **Status:** done
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-018 (data kan stubbes i tests)

## Mål
Economy-klasse, byggeomkostninger, entré, billetpriser, driftsomkostninger pr. dag, dagsskift. Se `_CONTRACT.md`.

## Acceptkriterier
- [x] Economy + kommandoer iht. kontrakt, med tests
- [x] Data læses fra economy.json og bygnings-JSON (kind, build_cost, running_cost_per_day)
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: Economy (spend/earn/charge, today/history pr. kategori), Balance (economy.json+guests.json med defaults, injicerbar i ParkSim.new(w,h,seed,balance)), AttractionDef udvidet (kind, build_cost, running_cost_per_day, excitement, satisfies, model). Kommandoer iht. kontrakt + dagsskift med driftsomkostninger. Ekstra API: Economy.charge/close_day/today, ParkSim.register_def, ParkSim.entry_fee, ParkSim.attraction_removed + ParkWorld.remove_attraction/attraction_removed. Tests: test_economy.gd (7). → review
- 2026-10-15 – qa: godkendt (45/45 tests, smoke uden fejl, web-build ok, kontrakt tjekket). → done
