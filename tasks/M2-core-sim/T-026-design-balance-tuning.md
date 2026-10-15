# T-026: Design – Balance-justering efter M2-simulation

- **Status:** todo
- **Milepæl:** M2
- **Agent:** designer
- **Afhænger af:** T-024

## Mål
T-024's balance-sim (`tools/balance.sh`) viser at startparken (karrusel+burger+drikke+toilet) giver ~+1900/dag i driftsoverskud og tjener investeringen (1800) hjem på dag 2. GDD-målet er overskud omkring dag 3, og penge må ikke eksplodere.

## Forslag (QA – vurder og juster)
- `running_cost_per_day` ca. ×4–5 (karrusel 40→180, boder 15–20→60–80, toilet 10→50) så drift æder ~25–35% af omsætningen.
- `entry_fee` 10→5, eller `spawn_interval_ticks` 40→60 (entré er ~45% af indtægten alene).
- Evt. `start_money` 2500→2000 så første park er strammere.
- Højere hunger-rate (0.03→0.04) eller `need_start_max` 30→40 så boder bruges allerede dag 1.
- Overvej om GDD-konstanter (ride_price_base m.fl.) skal skrives eksplicit i guests.json.

## Acceptkriterier
- [ ] `tools/balance.sh`: netto negativ/omkring 0 dag 1–2, positiv fra ~dag 3
- [ ] Glæde forbliver > 50, boder bruges hver dag
- [ ] GDD balance-rationale opdateret

## Log
- 2026-10-15 – qa: oprettet ud fra T-024
