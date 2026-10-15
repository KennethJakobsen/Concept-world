# T-077: Bug: test_ui_m5 bruger ferris_wheel som låst, men det er låst op i Grøn eng

- **Status:** todo
- **Milepæl:** M5
- **Agent:** ui
- **Afhænger af:** T-071, T-075

## Mål
`tools/test.sh` er rød: `test_ui_m5.gd::test_hud_locks_and_coaster_tab` forventer, at `ferris_wheel` er låst i `green_meadow`. Efter T-075 er den låst op fra start (`start.unlocked`). Testen skal bruge et id, der er låst (f.eks. `go_karts` eller `haunted_house`), eller bygge sin egen ScenarioDef, så den ikke afhænger af balance-data.

## Acceptkriterier
- [ ] `tools/test.sh` er grøn (236/236)
- [ ] Testen afhænger ikke af, hvilke ting scenarie-dataene låser op

## Log
- 2026-10-15 – qa: oprettet under T-072
