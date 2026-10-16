# T-082: Data: spor til tømmerrende, minitog og svævebane

- **Status:** done
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-081, ADR-004

## Mål
`tracks/*.json`, tre attraktioner og køretøjer (kontrakt §0 T-082). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [x] `tracks/flume.json`, `train.json` og `monorail.json` med `system`-blok og minimums-stykker
- [x] `log_flume.json`, `mini_train.json` og `monorail.json`
- [x] Køretøjerne `log_boat`, `mini_loco` og `monorail_cabin` med `cruise_speed`, hvor systemet er constant
- [x] Ingen ændring i `coaster/pieces.json`'s eksisterende stykker

## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – designer: tracks/flume|train|monorail.json, log_flume/mini_train/monorail og 3 køretøjer i coaster/trains.json (cruise_speed på mini_loco/monorail_cabin). Research-testen er nu grøn. Der er 1 forventet fejl: `test_real_content_parses` afviser kinds sideshow/flume/train/transport. Det kræver kode i T-085/T-090/T-091, så testen er ikke rettet.
- 2026-10-16 – qa (T-096): Godkendt headless. test.sh 308/0 (inkl. ny runner-selvtest og test_qa_m6), integration OK, balance.sh 5/5 i alle tre scenarier, build_web OK, smoke uden fejl. → done
