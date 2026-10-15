# T-035: Design – personale, nedbrud, affald, dekoration, 3 nye forlystelser

- **Status:** done
- **Milepæl:** M3
- **Agent:** designer
- **Afhænger af:** –

## Mål
Data og GDD-sektioner for alt nyt i M3. Tilføj reliability/repair_ticks til eksisterende rides. Lønninger skal gøre personale til et reelt valg. Se `_CONTRACT.md`.

## Acceptkriterier
- [x] JSON for 3 personaletyper, 5 dekorationer (bin, bench, tree, flowers, lamp), 3 nye forlystelser
- [x] GDD: personale, nedbrud, affald, dekoration med tal-rationale
- [x] Balance-forventning: startpark + 1 mekaniker + 1 rengøring holder break-even omkring dag 3–4
## Log
- 2026-10-15 – architect: oprettet
- 2026-10-15 – designer: staff/ (3), decor/ (5), 3 nye rides, reliability/repair_ticks på eksisterende rides, staff_rules.json, GDD-sektion. Forventet break-even dag 4 for startpark + mekaniker + rengøring (beregnet). → review
- 2026-10-15 – architect: tree.json erstattet af tree_round/tree_pine/tree_blossom.json for at matche T-038-props
- 2026-10-15 – qa: godkendt (T-041): test.sh 116/116, integration.sh grøn, smoke main_menu+main 300 frames uden ERROR/WARNING, web-build ok. → done
