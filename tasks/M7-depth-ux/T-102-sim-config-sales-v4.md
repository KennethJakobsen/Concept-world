# T-102: Sim: config, opskrifter, prisvirkninger, salg + save v4

- **Status:** review
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-100

## Mål
Kontraktens §1 T-102. Ejer bumpet til save v4. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `cmd_set_config`, `cmd_set_recipe`, `effective_config` og formler efter GDD §1
- [x] `price_effects` med sim-RNG, `supplies` i `finance_report`
- [x] `sales_tick`-signal og udvidet `attraction_stats` (omsætning, 7-dages-historik, payback)
- [x] `SaveMigrations.CURRENT = 4` med tests v1/v2/v3→v4 og round-trip-determinisme

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – simulation: startet.
- 2026-10-16 – simulation: færdig → review. `AttractionDef.config/recipes/price_effects` (+ `recipe(id)`), `Attraction.config/recipes/customers_today/revenue_today/revenue_days/payback_day/upkeep_total/supplies_total` (+ `supplies_frac`, `locked_config` gemt, så round-trip er eksakt). `cmd_set_config` (clamp, heltal for capacity/ride_ticks, default-værdi fjerner nøglen; config låses ved turstart), `cmd_set_recipe`, `effective_config`. Formler efter GDD §1 (drift, excitement, intensity/nausea × speed², reliability-tab × speed). Opskrifter: behov/glæde pr. salg, `price_tolerance` i betalingsvilje, varekøb samles i brøk og bogføres som `"supplies"` (ny kategori i `Economy.CATEGORIES`). `price_effects`: ekstra køb med sim-RNG, kvalme, tanke `too_much` (`ParkSim.M7_THOUGHTS` id → tekst). `sales_tick(sales)` én gang pr. tick (sum = `purchase_made`). `attraction_stats` udvidet (+ `config`, `recipes`, `supplies_total`). Save v4 (`_v3_to_v4`), tests v3/v2/v1→v4 og round-trip med config/opskrifter (`tests/test_m7_config_sales.gd`). Gamle versionstests peger nu på `SaveMigrations.CURRENT`. `test_economy` kender `atm`-kind. Ikke lavet: "salt gør gæsten lidt mindre glad uden drikkebod i nærheden" (balance, T-117 kan tage den).
