# T-119: Sim: impulskøb i butikker uden behov (ballon, souvenir)

- **Status:** in-progress
- **Milepæl:** M6
- **Agent:** simulation
- **Afhænger af:** T-095

## Mål
Ballonbåsen og Mindebutikken får 0 besøg, fordi gæster kun går i butikker for at dække et behov (fund i T-095). Tilføj impulskøb: gæster, der passerer/er tæt på en butik med `carry_item` (eller uden behov), kan købe med en sandsynlighed afhængig af glæde, penge, pris og om de allerede har tingen. Parametre i data (med defaults i kode), sim-RNG, deterministisk.

## Acceptkriterier
- [ ] Butikker uden behov får besøg via impulskøb; ingen gæst køber samme ting to gange
- [ ] Parametre læses fra data med defaults
- [ ] Tests (seedet) for frekvens og determinisme

## Log
- 2026-10-16 – orkestrator: oprettet ud fra T-095
