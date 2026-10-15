# T-081: Data: 14 bygninger, intensity/nausea, præmier, bærbare ting

- **Status:** todo
- **Milepæl:** M6
- **Agent:** designer
- **Afhænger af:** T-080

## Mål
Data for alle bygninger uden spor samt felter til mekanik B, D og E (kontrakt §0 T-081). Se `tasks/M6-content/_CONTRACT.md`.

## Acceptkriterier
- [ ] 14 nye `attractions/*.json` med navne/tal fra T-079
- [ ] `intensity`/`nausea` på alle `kind: ride`, også de eksisterende
- [ ] Sideshow-felter `win_chance`, `prize_cost`, `prize_happiness`, `prize_item`
- [ ] `items.json` og `carry_item` på Ballonbåsen/Mindebutikken
- [ ] `guests.json` tolerance-, kvalme- og opkastfelter
- [ ] `research.json`: topics `water_rides`/`sideshows`, `bouncy_castle` startunlock, katalog-testen er grøn
- [ ] `game/content/scenarios/` er IKKE rørt (T-078)
- [ ] `./tools/test.sh` og `balance.sh` er grønne

## Log
- 2026-10-15 – architect: oprettet
