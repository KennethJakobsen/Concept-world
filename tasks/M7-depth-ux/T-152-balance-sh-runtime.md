# T-152: balance.sh tager over 15 minutter

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-118

## Mål
`tools/balance.sh` tog 15 min 38 s i T-118 (alle scenarier + T-117/T-150/T-151-sektioner). Det gør det for langsomt at køre ofte. Tilføj f.eks. `--quick` (færre seeds/dage) eller `--section=<navn>`, og lad standardkørslen holde sig under ~5 min uden at fjerne dækning af vindbarhed.

## Acceptkriterier
- [ ] Standardkørsel ≤ 5 min, eller dokumenteret flag til hurtig kørsel
- [ ] Alle scenarier tjekkes stadig for vindbarhed

## Log
- 2026-10-16 – qa: oprettet fra T-118
