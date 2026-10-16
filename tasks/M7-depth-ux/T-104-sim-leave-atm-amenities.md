# T-104: Sim: gå hjem, hæveautomat, spande, bænke og lys

- **Status:** todo
- **Milepæl:** M7
- **Agent:** simulation
- **Afhænger af:** T-103

## Mål
Kontraktens §1 T-104 (GDD §3 og §9). Se `tasks/M7-depth-ux/_CONTRACT.md`.

## Acceptkriterier
- [ ] `LEAVING`-tilstand med tanker. Gæsten køber ikke og står ikke i kø
- [ ] ATM-hævning (seedet), gebyr `atm_fees`, maks 2 pr. besøg
- [ ] Spandens fyldniveau og overløb, bænk med 2 pladser, lys om natten og straf på mørke stier
- [ ] Signaler fra kontrakten og `litter_at`. Udvider `_v3_to_v4`

## Log
- 2026-10-16 – architect: oprettet (T-098)
