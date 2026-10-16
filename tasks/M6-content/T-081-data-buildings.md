# T-081: Data: 14 bygninger, intensity/nausea, præmier, bærbare ting

- **Status:** done
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-080

## Mål
Data for alle bygninger uden spor samt felter til mekanik B, D og E (kontrakt §0 T-081). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] 14 nye `attractions/*.json` med navne/tal fra T-079
- [x] `intensity`/`nausea` på alle `kind: ride`, også de eksisterende
- [x] Sideshow-felter `win_chance`, `prize_cost`, `prize_happiness`, `prize_item`
- [x] `items.json` og `carry_item` på Ballonbåsen/Mindebutikken
- [x] `guests.json` tolerance-, kvalme- og opkastfelter
- [x] `research.json`: topics `water_rides`/`sideshows`, `bouncy_castle` startunlock, katalog-testen er grøn
- [x] `game/content/scenarios/` er IKKE rørt (T-078)
- [x] `./tools/test.sh` og `balance.sh` er grønne

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – designer: 14 attraktioner, I/N på eksisterende rides, items.json, guests.json (tolerance/kvalme/opkast, `litter_kinds`), research (water_rides/sideshows, bouncy_castle start). balance.sh grøn. test.sh: 2 forventede fejl – `test_real_content_parses` afviser `kind: sideshow` (kræver T-085), og `test_research_ids_exist_in_catalog` mangler mini_train/monorail/log_flume (løses af T-082). Tests er ikke rettet.
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. → done
