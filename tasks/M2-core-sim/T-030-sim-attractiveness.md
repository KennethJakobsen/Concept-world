# T-030: Simulation – Tiltrækning og omdømme

- **Status:** todo
- **Milepæl:** M2
- **Agent:** simulation
- **Afhænger af:** T-029

## Mål
Implementér kontrakten i T-029. API-tilføjelser: `ParkSim.reputation: float`, `ParkSim.attraction_score() -> float`, `ParkSim.expected_guests_per_day() -> float`, `ParkSim.current_max_guests() -> int`, `signal reputation_changed(value: float)`. `get_stats()` udvides med reputation, attraction_score, guests_per_day, max_guests.

## Acceptkriterier
- [ ] Tests: ingen forlystelser → ingen gæster; flere forlystelser → højere rate; glade gæster øger omdømme; høj entré sænker rate; max_guests vokser med kapacitet; deterministisk
- [ ] tools/balance.sh opdateret til at printe reputation og rate
## Log
- 2026-10-15 – architect: oprettet
