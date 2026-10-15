# T-034: Design – Omdømme stiger for hurtigt

- **Status:** done
- **Milepæl:** M2
- **Agent:** designer
- **Afhænger af:** T-032

## Mål
QA: omdømme går 50→93 på 3 dage. Sænk reputation_learn_rate (forslag 0.005) så en god park bygger omdømme over 1–2 uger, og overvej max_guests_per_capacity. Kun content + GDD.

## Acceptkriterier
- [x] Startpark: omdømme ca. 60–70 efter 5 dage, break-even stadig omkring dag 3
## Log
- 2026-10-15 – architect: oprettet efter QA-fund
- 2026-10-15 – designer: reputation_learn_rate 0.02→0.0025 (0.005 gav 81 på dag 5). balance.sh startpark: omdømme 50→53.8/57.9/62.4/65.9/69.8; netto -1445/+618/+687/+787/+754 → kumuleret ≈ -140 efter dag 3, +647 dag 4 (break-even omkring dag 3). max_guests_per_capacity uændret 2.0 – startparken når ikke loftet (40–43/48); fuld-park-trængsel afventer T-033. GDD opdateret. → review
- 2026-10-15 – qa: godkendt. Import ok, test 66/66, smoke 300 frames uden ERROR, web-build ok. balance: startpark omdømme 53.8→70.0, kumuleret netto −204 dag 3/+571 dag 4; fuld park glæde 79–88, omdømme 53.7→82.1; QA-layout glæde 80–85, omdømme →71. HUD viser g.thought direkte fra sim ("Køen er for lang!" via ParkSim.QUEUE_FULL_THOUGHT). → done
