# T-030: Simulation – Tiltrækning og omdømme

- **Status:** done
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-029

## Mål
Implementér kontrakten i T-029. API-tilføjelser: `ParkSim.reputation: float`, `ParkSim.attraction_score() -> float`, `ParkSim.expected_guests_per_day() -> float`, `ParkSim.current_max_guests() -> int`, `signal reputation_changed(value: float)`. `get_stats()` udvides med reputation, attraction_score, guests_per_day, max_guests.

## Acceptkriterier
- [x] Tests: ingen forlystelser → ingen gæster; flere forlystelser → højere rate; glade gæster øger omdømme; høj entré sænker rate; max_guests vokser med kapacitet; deterministisk
- [x] tools/balance.sh opdateret til at printe reputation og rate
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – simulation: startet
- 2026-10-15 – simulation: implementeret efter T-029-kontrakten. Balance læser park.json (from_dicts(economy, guests, park={}) – has_park=false → legacy fast spawn fra guests.json). ParkSim: reputation, reputation_changed, attraction_score(), price_penalty(), expected_guests_per_day(), current_max_guests(), get_stats() + reputation/attraction_score/guests_per_day/max_guests. Ankomst: pr. tick sandsynlighed rate/day_ticks via seedet RNG, kun når guests < current_max_guests(). Omdømme opdateres ved hver fjernelse af gæst. Test-override: `fixed_spawn` (sættes automatisk når man assigner spawn_interval_ticks) → fast interval op til max_guests; eksisterende M1-tests bruger det uændret. Tests: test_attractiveness.gd (9); 60/60 grøn. balance.sh printer score/rate/max_guests ved start og omdømme+rate pr. dag. Startpark: 50.6/dag, max 48 ved omdømme 50; omdømme stiger til ~96 på 5 dage → rate ~74/dag, max 48 rammes ofte (designer kan overveje learn_rate/rep_mult).
- 2026-10-15 – qa: 61/61 tests, smoke og web-build grønne; API og get_stats verificeret via balance + test_hud_live. → done
