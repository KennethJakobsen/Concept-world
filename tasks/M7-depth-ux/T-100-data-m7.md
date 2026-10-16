# T-100: Data: config, opskrifter, kø/gæste-parametre, ATM, milepæle, omgivelser

- **Status:** todo
- **Milepæl:** M7
- **Agent:** designer
- **Afhænger af:** T-096, T-098

## Mål
Alle datafelter fra kontraktens §0 i `game/content/`. Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [ ] `config` på flat rides, `recipes`/`price_effects` på relevante shops
- [ ] `atm.json`, nye nøgler i `guests.json`/`park.json`, decor-felter (`seats`, `night_aura`, `capacity`)
- [ ] `milestones.json` (6 stk) og `research.json: start_topics`
- [ ] Alle eksisterende tests og `balance.sh` er grønne (sim ignorerer ukendte felter)

## Log
- 2026-10-16 – architect: oprettet (T-098)
