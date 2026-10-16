# T-102: Sim: config, opskrifter, prisvirkninger, salg + save v4

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-100

## Mål
Kontraktens §1 T-102. Ejer bumpet til save v4. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [ ] `cmd_set_config`, `cmd_set_recipe`, `effective_config` og formler efter GDD §1
- [ ] `price_effects` med sim-RNG, `supplies` i `finance_report`
- [ ] `sales_tick`-signal og udvidet `attraction_stats` (omsætning, 7-dages-historik, payback)
- [ ] `SaveMigrations.CURRENT = 4` med tests v1/v2/v3→v4 og round-trip-determinisme

## Log
- 2026-10-16 – architect: oprettet (T-098)
