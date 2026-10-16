# T-100: Data: config, opskrifter, kø/gæste-parametre, ATM, milepæle, omgivelser

- **Status:** done
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-096, T-098

## Mål
Alle datafelter fra kontraktens §0 i `game/content/`. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [x] `config` på flat rides, `recipes`/`price_effects` på relevante shops
- [x] `atm.json`, nye nøgler i `guests.json`/`park.json`, decor-felter (`seats`, `night_aura`, `capacity`)
- [x] `milestones.json` (6 stk) og `research.json: start_topics`
- [x] Alle eksisterende tests og `balance.sh` er grønne (sim ignorerer ukendte felter)

## Log
- 2026-10-16 – architect: oprettet (T-098)
- 2026-10-16 – designer: in-progress
- 2026-10-16 – designer: data lagt ind: `config` på alle 13 flat rides, `recipes` (fries/burger/drinks/coffee/ice), `price_effects` (is/fritter/burger), `atm.json` (+ forskningsitem `shops` 90), guests/park-nøgler inkl. `surroundings`, decor `seats`/`night_aura`/`capacity: 20`, `milestones.json` (6), `research.start_topics`, `surroundings.theme` i scenarier. Data-noter i GDD §M7. `balance.sh`: alle 3 scenarier 5/5. `test.sh`: 314/316 – 2 fejl skyldes `atm.json` uden sim/grafik-understøttelse endnu: `test_economy::test_real_content_parses` (kind "atm" ikke i testens liste → T-104 udvider) og `test_park_view::test_build_all_m6_buildings` (mangler `scenes/props/atm.tscn` → T-107). Review.
- 2026-10-16 – qa: verificeret (test.sh 446/446, integration, balance 5/5 scenarier vundet, web-build, smoke, v1/v2/v3→v4 i test_qa_m7). review → done.
